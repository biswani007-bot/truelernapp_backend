import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../assignments/domain/entities/assignment_entity.dart';
import '../../../assignments/presentation/controllers/assignments_controller.dart';
import '../../../assignments/presentation/controllers/assignments_state.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_state.dart';
import '../../domain/entities/class_entity.dart';
import '../controllers/classes_controller.dart';
import '../controllers/classes_state.dart';
import '../screens/parent_classes_screen.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';

/// Current Program Screen (Figma Frame `76:2787`).
///
/// Fully wired to backend via existing providers:
/// - [classesControllerProvider]    → live-classes API (upcoming class, schedule)
/// - [dashboardControllerProvider]  → dashboard API (track name, progress, enrolled batches)
/// - [assignmentsControllerProvider]→ assignments API (pending count, recent task)
/// - [childrenControllerProvider]   → active child context
///
/// No static/mock data is used. All displayed data comes from the backend.
class CurrentProgramScreen extends ConsumerStatefulWidget {
  const CurrentProgramScreen({super.key});

  @override
  ConsumerState<CurrentProgramScreen> createState() =>
      _CurrentProgramScreenState();
}

class _CurrentProgramScreenState extends ConsumerState<CurrentProgramScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  /// Triggers a fresh fetch of all required data for this screen.
  Future<void> _loadData({bool isRefresh = false}) async {
    final childrenState = ref.read(childrenControllerProvider);
    if (childrenState is! ChildrenLoaded) {
      await ref
          .read(childrenControllerProvider.notifier)
          .loadChildren(isRefresh: isRefresh);
      return;
    }
    await _fetchForChild(childrenState.activeChildId, isRefresh: isRefresh);
  }

  Future<void> _fetchForChild(String? childId, {bool isRefresh = false}) async {
    if (childId == null || childId.isEmpty) return;

    await Future.wait([
      ref
          .read(classesControllerProvider.notifier)
          .loadClasses(childStudentId: childId, isRefresh: isRefresh),
      ref
          .read(dashboardControllerProvider.notifier)
          .loadDashboard(childStudentId: childId, isRefresh: isRefresh),
      ref
          .read(assignmentsControllerProvider.notifier)
          .loadAssignments(childStudentId: childId, isRefresh: isRefresh),
    ]);
  }

  /// Formats a [DateTime] badge relative to today: "Today", "Tomorrow", or the
  /// abbreviated weekday (e.g. "Mon, 28 Sep").
  String _formatClassBadge(DateTime? scheduledStart, [DateTime? nowOverride]) {
    if (scheduledStart == null) return '';
    final local = scheduledStart.toLocal();
    final now = nowOverride ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final classDay = DateTime(local.year, local.month, local.day);
    final diff = classDay.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${local.day} ${months[local.month - 1]}';
  }

  /// Formats a time range string from [start] to [end] local times.
  String _formatTimeRange(DateTime? start, DateTime? end) {
    if (start == null) return '';
    final localStart = start.toLocal();
    final localEnd = end?.toLocal();

    String fmt(DateTime dt) {
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final hour12 = h % 12 == 0 ? 12 : h % 12;
      return '$hour12:$m $period';
    }

    final startStr = fmt(localStart);
    if (localEnd == null) return startStr;
    return '$startStr – ${fmt(localEnd)}';
  }

  // ──────────────────────────────── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch children to detect active child
    final childrenState = ref.watch(childrenControllerProvider);

    // When children finish loading or switch, trigger fetch for the active child
    ref.listen<ChildrenState>(childrenControllerProvider, (prev, next) {
      if (next is ChildrenLoaded) {
        final prevChildId = prev is ChildrenLoaded ? prev.activeChildId : null;
        if (next.activeChildId != prevChildId) {
          _fetchForChild(next.activeChildId);
        }
      }
    });

    final classesState = ref.watch(classesControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final assignmentsState = ref.watch(assignmentsControllerProvider);

    // Derive active child ID (null-safe)
    final String? activeChildId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;

    final isDashboardForActiveChild =
        dashboardState is DashboardLoaded &&
        (activeChildId == null ||
            dashboardState.childStudentId == activeChildId);

    final isClassesForActiveChild =
        classesState is ClassesLoaded &&
        (classesState.childStudentId == null ||
            classesState.childStudentId == activeChildId);

    final isAssignmentsForActiveChild =
        assignmentsState is AssignmentsLoaded &&
        (assignmentsState.childStudentId == null ||
            assignmentsState.childStudentId == activeChildId);

    // Determine overall loading states per section to prevent stale child data leakage
    final isChildrenLoading =
        childrenState is ChildrenInitial || childrenState is ChildrenLoading;
    final isDashboardLoading =
        dashboardState is DashboardInitial ||
        dashboardState is DashboardLoading ||
        (dashboardState is DashboardLoaded && !isDashboardForActiveChild);
    final isClassesLoading =
        classesState is ClassesInitial ||
        classesState is ClassesLoading ||
        (classesState is ClassesLoaded && !isClassesForActiveChild);
    final isAssignmentsLoading =
        assignmentsState is AssignmentsInitial ||
        assignmentsState is AssignmentsLoading ||
        (assignmentsState is AssignmentsLoaded && !isAssignmentsForActiveChild);

    // Dashboard data strictly for active child
    final dashLoaded = isDashboardForActiveChild
        ? dashboardState.dashboard
        : null;
    final enrolledBatch = dashLoaded?.enrolledBatches.firstOrNull;
    final trackName =
        enrolledBatch?.courseName ??
        enrolledBatch?.batchName ??
        dashLoaded?.activeTopic;
    final progressPercentage =
        enrolledBatch?.progressPercentage ?? dashLoaded?.overallProgress;

    // Next class from live-classes API strictly for active child
    final now = ref.watch(currentDeviceDateProvider);
    ClassEntity? nextClass;
    if (isClassesForActiveChild && classesState.classes.isNotEmpty) {
      // Exclude terminal / past / cancelled sessions
      final validClasses = classesState.classes.where((c) {
        if (c.isCancelled) return false;
        if (c.isMissedAt(now)) return false;
        if (c.isCompletedAt(now) && !c.isUpcomingAt(now)) return false;
        return true;
      }).toList();

      if (validClasses.isNotEmpty) {
        // Priority 1: Currently LIVE session
        final liveCandidates = validClasses.where((c) => c.isLive).toList();
        if (liveCandidates.isNotEmpty) {
          liveCandidates.sort(
            (a, b) => (a.scheduledStartTime ?? DateTime(0)).compareTo(
              b.scheduledStartTime ?? DateTime(0),
            ),
          );
          nextClass = liveCandidates.first;
        } else {
          // Priority 2: Upcoming or ongoing session whose scheduled end time is after now
          final upcomingCandidates = validClasses.where((c) {
            if (c.isUpcomingAt(now)) return true;
            final end =
                c.scheduledEndTime?.toLocal() ??
                (c.scheduledStartTime?.toLocal().add(
                  Duration(minutes: c.duration ?? 60),
                ));
            return end != null && end.isAfter(now);
          }).toList();

          if (upcomingCandidates.isNotEmpty) {
            upcomingCandidates.sort(
              (a, b) => (a.scheduledStartTime ?? DateTime(0)).compareTo(
                b.scheduledStartTime ?? DateTime(0),
              ),
            );
            nextClass = upcomingCandidates.first;
          }
        }
      }
    }

    // Recent pending assignment strictly for active child
    AssignmentEntity? recentAssignment;
    int computedPending = 0;

    if (isAssignmentsForActiveChild &&
        assignmentsState.allAssignments.isNotEmpty) {
      // Deduplicate assignments by ID
      final seenIds = <String>{};
      final uniqueAssignments = <AssignmentEntity>[];
      for (final a in assignmentsState.allAssignments) {
        if (seenIds.add(a.id)) {
          uniqueAssignments.add(a);
        }
      }

      final childFiltered = uniqueAssignments
          .where(
            (a) =>
                activeChildId == null ||
                a.childStudentId == null ||
                a.childStudentId == activeChildId,
          )
          .toList();

      // Strictly count pending assignments (overdue, completed, and submitted are excluded)
      final pending = childFiltered
          .where((a) => a.status == AssignmentStatus.pending)
          .toList();

      computedPending = pending.length;
      if (pending.isNotEmpty) {
        recentAssignment = pending.first;
      } else if (childFiltered.isNotEmpty) {
        recentAssignment = childFiltered.first;
      }
    } else if (isDashboardForActiveChild &&
        dashLoaded?.pendingAssignmentsCount != null) {
      computedPending = dashLoaded!.pendingAssignmentsCount!;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Stack(
          children: [
            // Scrollable content
            AppRefreshIndicator(
              onRefresh: () => _loadData(isRefresh: true),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 88, bottom: 32),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Hero Header
                      if (isChildrenLoading || isDashboardLoading)
                        _buildHeroSkeleton()
                      else if (dashboardState is DashboardError &&
                          !isDashboardForActiveChild)
                        _buildErrorBanner(
                          message: dashboardState.message,
                          onRetry: () => _fetchForChild(activeChildId),
                        )
                      else if (dashboardState is DashboardNoChild)
                        _buildNoChildBanner()
                      else
                        _buildHeroHeader(trackName: trackName),

                      const SizedBox(height: 24),

                      // 2. Progress Card
                      if (isChildrenLoading || isDashboardLoading)
                        _buildProgressSkeleton()
                      else if (dashLoaded != null)
                        _buildProgressCard(
                          trackName: trackName,
                          batch: enrolledBatch,
                          progressPercentage: progressPercentage,
                        )
                      else
                        const SizedBox.shrink(),

                      const SizedBox(height: 24),

                      // 3. Next Live Class Card
                      if (isClassesLoading || isChildrenLoading)
                        _buildCardSkeleton(height: 180)
                      else if (classesState is ClassesError &&
                          !isClassesForActiveChild)
                        _buildErrorBanner(
                          message: classesState.message,
                          onRetry: () => ref
                              .read(classesControllerProvider.notifier)
                              .retry(),
                        )
                      else if (nextClass != null)
                        _buildNextLiveClassCard(
                          context,
                          title: nextClass.title,
                          time: _formatTimeRange(
                            nextClass.scheduledStartTime,
                            nextClass.scheduledEndTime,
                          ),
                          badge: _formatClassBadge(
                            nextClass.scheduledStartTime,
                            now,
                          ),
                        )
                      else
                        _buildNoClassCard(context),

                      const SizedBox(height: 12),

                      // 4. Recent Assignments Card
                      if (isAssignmentsLoading || isChildrenLoading)
                        _buildCardSkeleton(height: 200)
                      else if (assignmentsState is AssignmentsError &&
                          !isAssignmentsForActiveChild)
                        _buildErrorBanner(
                          message: assignmentsState.message,
                          onRetry: () => _fetchForChild(activeChildId),
                        )
                      else
                        _buildRecentAssignmentsCard(
                          context,
                          pendingCount: computedPending,
                          recentAssignment: recentAssignment,
                          hasAssignments:
                              isAssignmentsForActiveChild &&
                              recentAssignment != null,
                        ),

                      const SizedBox(height: 24),

                      // 5. Skills in Focus (static layout section — no API data exists for this)
                      _buildSkillsAcquiredSection(),
                    ],
                  ),
                ),
              ),
            ),

            // Floating TopAppBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopAppBar(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── TopAppBar ──────────────────────────────────

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            key: const Key('current_program_back_button'),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/parent/classes');
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          Image.asset(
            'assets/images/truelern_logo.png',
            height: 38,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Text(
              'TrueLern',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 23.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0037B1),
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Hero Header ────────────────────────────────

  Widget _buildHeroHeader({String? trackName}) {
    return Column(
      children: [
        SizedBox(
          width: 131,
          height: 126,
          child: Image.asset(
            'assets/images/figma_communication_hero.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Image.asset(
              'assets/images/rocket_illustration.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ACTIVE TRACK badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF22D3EE).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22D3EE),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ACTIVE TRACK',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.8,
                  color: const Color(0xFF1A1B23),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Track name from API
        Text(
          trackName?.isNotEmpty == true ? trackName! : 'Your Learning Track',
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B23),
            height: 24 / 16,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'Expand your knowledge and build skills\nfor every challenge ahead.',
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF434655),
            height: 24 / 16,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Progress Card ──────────────────────────────

  Widget _buildProgressCard({
    String? trackName,
    dynamic batch,
    double? progressPercentage,
  }) {
    final double progressRatio;
    final String percentageText;
    if (progressPercentage != null) {
      final clamped = progressPercentage.clamp(0.0, 100.0);
      progressRatio = clamped / 100.0;
      percentageText = '${clamped.toInt()}%';
    } else {
      progressRatio = 0.0;
      percentageText = '--';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left cyan accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF22D3EE),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Track Progress title & percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Track Progress',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF1A1B23),
                        height: 24 / 16,
                      ),
                    ),
                    Text(
                      percentageText,
                      key: const Key('current_program_progress_percentage'),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0037B1),
                        height: 24 / 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Enrolled batch / course name
                Text(
                  trackName?.isNotEmpty == true
                      ? trackName!
                      : 'Your enrolled program',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF434655),
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 16),

                // Progress bar — dynamic visual fill corresponding to percentage
                Container(
                  key: const Key('current_program_progress_bar_container'),
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E7F3),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: progressRatio > 0.0
                      ? FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progressRatio,
                          child: Container(
                            key: const Key('current_program_progress_bar_fill'),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22D3EE),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Instructor info if available
                if (batch?.instructor != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Color(0xFF434655),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          batch!.instructor!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF434655),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Batch code if available
                if (batch?.batchCode != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.tag_rounded,
                        size: 14,
                        color: Color(0xFF434655),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        batch!.batchCode!,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF434655),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── Next Live Class Card ───────────────────────────────

  Widget _buildNextLiveClassCard(
    BuildContext context, {
    required String title,
    required String time,
    required String badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('current_program_next_live_class_card'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(AppRoutePaths.topicDetail),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.videocam_rounded,
                        color: Color(0xFF0037B1),
                        size: 22,
                      ),
                    ),
                  ),
                  if (badge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F2FE),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF434655),
                          height: 24 / 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1B23),
                  height: 24 / 16,
                ),
              ),
              if (time.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Color(0xFF434655),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        time,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF434655),
                          height: 24 / 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────── No Class / Empty State Card ────────────────────────

  Widget _buildNoClassCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.videocam_off_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Upcoming Classes',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1B23),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'re all caught up! Check back soon for your next live class.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Recent Assignments Card ─────────────────────────────

  Widget _buildRecentAssignmentsCard(
    BuildContext context, {
    required int pendingCount,
    required AssignmentEntity? recentAssignment,
    required bool hasAssignments,
  }) {
    final pendingText = pendingCount > 0
        ? '$pendingCount Pending'
        : 'Up to date';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: pendingCount > 0
                      ? const Color(0xFFBA1A1A).withValues(alpha: 0.10)
                      : const Color(0xFF10B981).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    pendingCount > 0
                        ? Icons.assignment_outlined
                        : Icons.assignment_turned_in_outlined,
                    color: pendingCount > 0
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFF10B981),
                    size: 22,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: pendingCount > 0
                      ? const Color(0xFFFFDAD6).withValues(alpha: 0.30)
                      : const Color(0xFFD1FAE5).withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  pendingText,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: pendingCount > 0
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFF059669),
                    height: 24 / 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            'Recent Assignments',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 12),

          if (!hasAssignments)
            _buildNoAssignmentsTile()
          else if (recentAssignment != null)
            _buildAssignmentTile(recentAssignment)
          else
            _buildNoAssignmentsTile(),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              key: const Key('view_all_tasks_button'),
              onPressed: () => context.go('/parent/assignments'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E1ED), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 14,
                ),
              ),
              child: Text(
                'View All Tasks',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1B23),
                  height: 24 / 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentTile(AssignmentEntity assignment) {
    final isPending = assignment.status == AssignmentStatus.pending;
    final isOverdue = assignment.status == AssignmentStatus.overdue;
    final dueLabel = isOverdue
        ? (assignment.overdueDate ?? assignment.dueDate ?? 'Overdue')
        : (assignment.dueDate ?? '');

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: isOverdue
                ? const Color(0xFFBA1A1A)
                : const Color(0xFF0037B1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1A1B23),
                    height: 24 / 16,
                  ),
                ),
                if (dueLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dueLabel,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isOverdue || isPending
                          ? const Color(0xFFBA1A1A)
                          : const Color(0xFF94A3B8),
                      height: 15 / 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFF434655),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAssignmentsTile() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 20,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No pending assignments',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF434655),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Error / No-Child Banners ───────────────────────

  Widget _buildErrorBanner({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBA1A1A).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFBA1A1A),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            message.isNotEmpty ? message : 'Failed to load data.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              color: const Color(0xFFBA1A1A),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0037B1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_off_outlined,
            color: Color(0xFF434655),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'No child linked to your account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              color: const Color(0xFF434655),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Skeletons ──────────────────────────────────

  Widget _buildHeroSkeleton() {
    return Column(
      children: [
        _skeletonBox(width: 131, height: 126, radius: 16),
        const SizedBox(height: 16),
        _skeletonBox(width: 140, height: 32, radius: 9999),
        const SizedBox(height: 12),
        _skeletonBox(width: 220, height: 20, radius: 8),
        const SizedBox(height: 8),
        _skeletonBox(width: 180, height: 16, radius: 8),
      ],
    );
  }

  Widget _buildProgressSkeleton() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonBox(width: 120, height: 18, radius: 8),
            const SizedBox(height: 8),
            _skeletonBox(width: 200, height: 14, radius: 8),
            const SizedBox(height: 16),
            _skeletonBox(width: double.infinity, height: 8, radius: 9999),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSkeleton({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _skeletonBox(width: 42, height: 42, radius: 12),
                _skeletonBox(width: 80, height: 28, radius: 9999),
              ],
            ),
            const SizedBox(height: 12),
            _skeletonBox(width: 200, height: 18, radius: 8),
            const SizedBox(height: 8),
            _skeletonBox(width: 130, height: 14, radius: 8),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox({
    double? width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E7F3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ──────────────────────── Skills in Focus ───────────────────────────────

  /// Section - Skills Acquired (Figma Node 76:2879 - 76:2898).
  /// Static layout with contextual icons — no specific backend API for skills.
  Widget _buildSkillsAcquiredSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Skills in Focus',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
              height: 24 / 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSkillCard(
                title: 'Critical Thinking',
                iconData: Icons.psychology_outlined,
                tintColor: const Color(0xFF14B8A6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSkillCard(
                title: 'Expression',
                iconData: Icons.record_voice_over_outlined,
                tintColor: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSkillCard(
                title: 'Dialogue',
                iconData: Icons.chat_bubble_outline_rounded,
                tintColor: const Color(0xFF9333EA),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillCard({
    required String title,
    required IconData iconData,
    required Color tintColor,
  }) {
    return Container(
      height: 108,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tintColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(iconData, color: tintColor, size: 20)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1A1B23),
              height: 20 / 16,
            ),
          ),
        ],
      ),
    );
  }
}
