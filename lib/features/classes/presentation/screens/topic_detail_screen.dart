import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_refresh_indicator.dart';
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
import '../controllers/program_details_provider.dart';
import 'parent_classes_screen.dart';

/// Topic / Track Detail Screen — Connected to authoritative backend APIs.
///
/// Figma Page: Parent(full app)_TreLern
/// Node: 76:2930 — "Topic Detail (New)"
///
/// Supported sections:
/// 1. Hero: Displays real course/track title, level/code badge, and description from GET /parent/children/:id/program.
/// 2. Live Class: Displays the active child's scheduled live session, instructor, and local time from GET /parent/children/:id/live-classes.
///    Tapping connects to the verified ClassDetailsScreen (/parent/classes/:classId) preserving 15-minute early entry rules.
/// 3. Assignment: Displays the child's pending assignment and due date from GET /parent/children/:id/assignments.
///    Tapping connects to AssignmentDetailsScreen (/parent/assignments/:assignmentId).
/// 4. Track Progress: Displays real completion percentage and visual fill from GET /parent/children/:id/program.
///
/// Note: The mock "Practice" card (Voice, Poise/Pulse, Clarity) has been removed because no practice,
/// self-paced module, or audio evaluation API exists in the backend API contract.
class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, this.topicTitle, this.topicId});

  final String? topicTitle;
  final String? topicId;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final childrenState = ref.read(childrenControllerProvider);
    final activeChildId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;

    if (activeChildId != null && activeChildId.isNotEmpty) {
      ref
          .read(classesControllerProvider.notifier)
          .loadClasses(childStudentId: activeChildId);
      ref
          .read(assignmentsControllerProvider.notifier)
          .loadAssignments(childStudentId: activeChildId);
      ref
          .read(dashboardControllerProvider.notifier)
          .loadDashboard(childStudentId: activeChildId);
    }
  }

  Future<void> _handleRefresh() async {
    final childrenState = ref.read(childrenControllerProvider);
    final activeChildId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;

    if (activeChildId != null && activeChildId.isNotEmpty) {
      ref.invalidate(programDetailsProvider(activeChildId));
      await Future.wait([
        ref
            .read(classesControllerProvider.notifier)
            .loadClasses(childStudentId: activeChildId, isRefresh: true),
        ref
            .read(assignmentsControllerProvider.notifier)
            .loadAssignments(childStudentId: activeChildId, isRefresh: true),
        ref
            .read(dashboardControllerProvider.notifier)
            .loadDashboard(childStudentId: activeChildId, isRefresh: true),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenState = ref.watch(childrenControllerProvider);

    // Listen for child changes to trigger refresh
    ref.listen<ChildrenState>(childrenControllerProvider, (prev, next) {
      if (next is ChildrenLoaded && next.activeChildId != null) {
        final prevChildId = prev is ChildrenLoaded ? prev.activeChildId : null;
        if (next.activeChildId != prevChildId) {
          ref.invalidate(programDetailsProvider(next.activeChildId!));
          ref
              .read(classesControllerProvider.notifier)
              .loadClasses(childStudentId: next.activeChildId, isRefresh: true);
          ref
              .read(assignmentsControllerProvider.notifier)
              .loadAssignments(
                childStudentId: next.activeChildId,
                isRefresh: true,
              );
          ref
              .read(dashboardControllerProvider.notifier)
              .loadDashboard(
                childStudentId: next.activeChildId,
                isRefresh: true,
              );
        }
      }
    });

    final String? activeChildId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;

    final classesState = ref.watch(classesControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final assignmentsState = ref.watch(assignmentsControllerProvider);
    final programAsync = activeChildId != null && activeChildId.isNotEmpty
        ? ref.watch(programDetailsProvider(activeChildId))
        : null;

    // Is active child matches current loaded state?
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

    final dashLoaded = isDashboardForActiveChild
        ? dashboardState.dashboard
        : null;
    final enrolledBatch = dashLoaded?.enrolledBatches.firstOrNull;
    final programDetails = programAsync?.asData?.value;

    // 1. Hero text derivation
    final categoryBadge =
        programDetails?.courseCode ??
        programDetails?.level?.toUpperCase() ??
        enrolledBatch?.batchCode ??
        'COMMUNICATION';

    final trackTitle =
        widget.topicTitle ??
        programDetails?.courseName ??
        enrolledBatch?.courseName ??
        dashLoaded?.activeTopic ??
        'Speaking With Confidence';

    final trackDescription =
        programDetails?.description ??
        (dashLoaded != null
            ? 'Engage in project-based learning to master core concepts, build confidence, and demonstrate measurable growth.'
            : 'Learn techniques to project your voice, overcome stage fright, and deliver your message with clarity and impact.');

    // 2. Scheduled live class derivation
    final now = ref.watch(currentDeviceDateProvider);
    ClassEntity? nextClass;
    if (isClassesForActiveChild && classesState.classes.isNotEmpty) {
      final validClasses = classesState.classes.where((c) {
        if (c.isCancelled) return false;
        if (c.isMissedAt(now)) return false;
        if (c.isCompletedAt(now) && !c.isUpcomingAt(now)) return false;
        return true;
      }).toList();

      if (validClasses.isNotEmpty) {
        // Priority 1: Live
        final liveClasses = validClasses.where((c) => c.isLive).toList();
        if (liveClasses.isNotEmpty) {
          liveClasses.sort(
            (a, b) => (a.scheduledStartTime?.toLocal() ?? DateTime(0))
                .compareTo(b.scheduledStartTime?.toLocal() ?? DateTime(0)),
          );
          nextClass = liveClasses.first;
        } else {
          // Priority 2: Upcoming
          validClasses.sort(
            (a, b) => (a.scheduledStartTime?.toLocal() ?? DateTime(0))
                .compareTo(b.scheduledStartTime?.toLocal() ?? DateTime(0)),
          );
          for (final c in validClasses) {
            final endLocal =
                c.scheduledEndTime?.toLocal() ??
                (c.scheduledStartTime?.toLocal().add(
                  Duration(minutes: c.duration ?? 60),
                ));
            if (endLocal != null && endLocal.isAfter(now)) {
              nextClass = c;
              break;
            }
          }
        }
      }
    }

    // 3. Relevant assignment derivation
    AssignmentEntity? relevantAssignment;
    if (isAssignmentsForActiveChild &&
        assignmentsState.allAssignments.isNotEmpty) {
      final childAssignments = assignmentsState.allAssignments
          .where(
            (a) => activeChildId == null || a.childStudentId == activeChildId,
          )
          .toList();

      final pending = childAssignments
          .where((a) => a.status == AssignmentStatus.pending)
          .toList();

      if (pending.isNotEmpty) {
        pending.sort((a, b) {
          final da = a.dueDate ?? '';
          final db = b.dueDate ?? '';
          return da.compareTo(db);
        });
        relevantAssignment = pending.first;
      } else if (childAssignments.isNotEmpty) {
        relevantAssignment = childAssignments.first;
      }
    }

    // 4. Progress derivation
    final double? progressValue =
        programDetails?.progress ??
        enrolledBatch?.progressPercentage ??
        dashLoaded?.overallProgress;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1.0, -0.2926),
            end: Alignment(1.0, 0.2926),
            stops: [0.0, 0.5, 1.0],
            colors: [Color(0xFFF3E8FF), Color(0xFFE0F2FE), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Stack(
            children: [
              // Scrollable content canvas
              AppRefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 76,
                    bottom: 96,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Hero Section
                        if (isChildrenLoading && activeChildId == null)
                          _buildHeroSkeleton()
                        else
                          _buildHeroSection(
                            badge: categoryBadge,
                            title: trackTitle,
                            subtitle: trackDescription,
                          ),

                        const SizedBox(height: 24),

                        // 2. Live Class Card
                        if (isClassesLoading || isChildrenLoading)
                          _buildCardSkeleton(height: 160)
                        else if (classesState is ClassesError &&
                            !isClassesForActiveChild)
                          _buildErrorBanner(
                            message: classesState.message,
                            onRetry: () => ref
                                .read(classesControllerProvider.notifier)
                                .loadClasses(
                                  childStudentId: activeChildId,
                                  isRefresh: true,
                                ),
                          )
                        else if (nextClass != null)
                          _buildLiveClassCard(context, nextClass, now)
                        else
                          _buildNoClassCard(),

                        const SizedBox(height: 24),

                        // 3. Assignment Card (Notice: Mock Practice card removed per Phase 2/3)
                        if (isAssignmentsLoading || isChildrenLoading)
                          _buildCardSkeleton(height: 180)
                        else if (assignmentsState is AssignmentsError &&
                            !isAssignmentsForActiveChild)
                          _buildErrorBanner(
                            message: assignmentsState.message,
                            onRetry: () => ref
                                .read(assignmentsControllerProvider.notifier)
                                .loadAssignments(
                                  childStudentId: activeChildId,
                                  isRefresh: true,
                                ),
                          )
                        else if (relevantAssignment != null)
                          _buildAssignmentCard(context, relevantAssignment)
                        else
                          _buildNoAssignmentCard(),

                        const SizedBox(height: 24),

                        // 4. Topic / Track Progress Card
                        if (isDashboardLoading ||
                            (programAsync?.isLoading ?? false))
                          _buildCardSkeleton(height: 160)
                        else
                          _buildProgressCard(progressPercentage: progressValue),

                        const SizedBox(height: 16),
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
      ),
    );
  }

  // ─────────────────────────── TopAppBar ──────────────────────────────────

  Widget _buildTopAppBar(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xCCFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            key: const Key('topic_detail_back_button'),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/parent/classes/program');
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.centerLeft,
              child: SvgPicture.asset(
                'assets/icons/topic_back_icon.svg',
                width: 16,
                height: 16,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),

          // TrueLern Wordmark Logo
          SizedBox(
            width: 132,
            height: 45.26,
            child: Image.asset(
              'assets/images/figma_topic_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/truelern_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Text(
                  'TrueLern',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0037B1),
                  ),
                ),
              ),
            ),
          ),

          // 3-dot Kebab Menu
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.centerRight,
            child: SvgPicture.asset(
              'assets/icons/topic_three_dots_icon.svg',
              width: 4,
              height: 16,
              errorBuilder: (_, _, _) => const Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: Color(0xFF434655),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Hero Section ───────────────────────────────

  Widget _buildHeroSection({
    required String badge,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 3D Illustration
        SizedBox(
          width: 150,
          height: 144,
          child: Image.asset(
            'assets/images/figma_topic_hero.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.school_rounded,
              size: 80,
              color: Color(0xFF0037B1),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Category / Code pill badge
        Container(
          key: const Key('topic_detail_hero_badge'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x1A22D3EE),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(
            badge,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF22D3EE),
              height: 16 / 12,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Title
        Text(
          title,
          key: const Key('topic_detail_hero_title'),
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B23),
            height: 36 / 28,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle / Description
        Text(
          subtitle,
          key: const Key('topic_detail_hero_subtitle'),
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF434655),
            height: 22 / 15,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Live Class Card ────────────────────────────

  Widget _buildLiveClassCard(
    BuildContext context,
    ClassEntity session,
    DateTime now,
  ) {
    final timeRange = _formatTimeRange(
      session.scheduledStartTime,
      session.scheduledEndTime,
      session.duration,
    );
    final badgeText = _formatClassBadge(session.scheduledStartTime, now);
    final teacher = session.teacherName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('topic_detail_live_class_card'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_isNavigating) return;
          _isNavigating = true;
          // Navigates to ClassDetailsScreen preserving the 15-minute early entry rules
          context.push('/parent/classes/${session.id}', extra: session).then((
            _,
          ) {
            if (mounted) _isNavigating = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              left: BorderSide(color: Color(0xFF0037B1), width: 4),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  width: 82,
                  height: 79,
                  child: SvgPicture.asset(
                    'assets/icons/topic_live_class_bg.svg',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      'Live Class',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1B23),
                                        height: 24 / 16,
                                      ),
                                    ),
                                    if (session.isLive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFBA1A1A),
                                          borderRadius: BorderRadius.circular(
                                            9999,
                                          ),
                                        ),
                                        child: Text(
                                          'LIVE NOW',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  badgeText.isNotEmpty
                                      ? '$badgeText, $timeRange'
                                      : timeRange,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0037B1),
                                    height: 16 / 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SvgPicture.asset(
                            'assets/icons/topic_video_icon.svg',
                            width: 36,
                            height: 41,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.videocam_rounded,
                              size: 32,
                              color: Color(0xFF0037B1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        session.title,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1B23),
                        ),
                      ),
                      if (teacher != null && teacher.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Instructor: $teacher',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF434655),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoClassCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFFC4C5D7), width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: Color(0xFF74777F),
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Live Classes Scheduled',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1B23),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No upcoming sessions are scheduled for this child.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Assignment Card ────────────────────────────

  Widget _buildAssignmentCard(
    BuildContext context,
    AssignmentEntity assignment,
  ) {
    final cleanDesc = _cleanHtml(assignment.description);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF9333EA), width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assignment',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1B23),
                            height: 24 / 16,
                          ),
                        ),
                        if (assignment.dueDate != null &&
                            assignment.dueDate!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            assignment.dueDate!,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF9333EA),
                              height: 16 / 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/topic_assignment_icon.svg',
                    width: 34,
                    height: 43,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.assignment_outlined,
                      size: 32,
                      color: Color(0xFF9333EA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                assignment.title,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1B23),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cleanDesc.isNotEmpty
                    ? cleanDesc
                    : 'Marks: ${assignment.totalMarks ?? 40}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF434655),
                  height: 20 / 14,
                ),
              ),
              const SizedBox(height: 16),
              // Action button to open assignment details
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC4C5D7)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('topic_detail_assignment_submit_button'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (_isNavigating) return;
                      _isNavigating = true;
                      context.push('/parent/assignments/${assignment.id}').then(
                        (_) {
                          if (mounted) _isNavigating = false;
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/topic_submit_doc_icon.svg',
                            width: 12,
                            height: 14,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: Color(0xFF1A1B23),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View Assignment',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1B23),
                              letterSpacing: 0.1,
                              height: 20 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoAssignmentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFFC4C5D7), width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF14B8A6),
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Pending Assignments',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1B23),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You are all caught up on assignments for this track.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Progress Card ──────────────────────────────

  Widget _buildProgressCard({double? progressPercentage}) {
    final double progressRatio;
    final String percentageString;
    final String statusLabel;

    if (progressPercentage != null) {
      final clamped = progressPercentage.clamp(0.0, 100.0);
      progressRatio = clamped / 100.0;
      percentageString = '${clamped.toInt()}';
      statusLabel = clamped >= 100.0 ? 'Completed' : 'In Progress';
    } else {
      progressRatio = 0.0;
      percentageString = '--';
      statusLabel = 'Pending Start';
    }

    return Container(
      key: const Key('topic_detail_progress_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Topic Progress',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1B23),
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progressRatio >= 1.0 ? 'Completed!' : 'Keep it up!',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF434655),
                      height: 16 / 12,
                    ),
                  ),
                ],
              ),
              SvgPicture.asset(
                'assets/icons/topic_progress_trend_icon.svg',
                width: 36,
                height: 35,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.trending_up_rounded,
                  size: 32,
                  color: Color(0xFF22D3EE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: percentageString,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1B23),
                        letterSpacing: -0.96,
                        height: 56 / 48,
                      ),
                    ),
                    TextSpan(
                      text: '%',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 25.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF434655),
                        height: 32 / 24,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF434655),
                    height: 16 / 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: progressRatio > 0.0
                ? FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D3EE),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Skeletons & Errors ─────────────────────────

  Widget _buildHeroSkeleton() {
    return Column(
      children: [
        _skeletonBox(width: 150, height: 144, radius: 16),
        const SizedBox(height: 16),
        _skeletonBox(width: 120, height: 28, radius: 9999),
        const SizedBox(height: 12),
        _skeletonBox(width: 240, height: 32, radius: 8),
        const SizedBox(height: 8),
        _skeletonBox(width: 280, height: 20, radius: 8),
      ],
    );
  }

  Widget _buildCardSkeleton({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _skeletonBox(width: 120, height: 20, radius: 8),
                _skeletonBox(width: 36, height: 36, radius: 8),
              ],
            ),
            const SizedBox(height: 16),
            _skeletonBox(width: 200, height: 18, radius: 8),
            const SizedBox(height: 8),
            _skeletonBox(width: 140, height: 14, radius: 8),
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

  Widget _buildErrorBanner({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
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
            message.isNotEmpty ? message : 'Failed to load content.',
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

  // ─────────────────────────── Formatters ─────────────────────────────────

  String _formatTimeRange(DateTime? start, DateTime? end, int? duration) {
    if (start == null) return 'Schedule TBA';
    final sLocal = start.toLocal();
    final sHour = sLocal.hour == 0
        ? 12
        : (sLocal.hour > 12 ? sLocal.hour - 12 : sLocal.hour);
    final sAmPm = sLocal.hour >= 12 ? 'PM' : 'AM';
    final sMin = sLocal.minute.toString().padLeft(2, '0');
    final sStr = '$sHour:$sMin $sAmPm';

    final resolvedEnd =
        end?.toLocal() ??
        (duration != null ? sLocal.add(Duration(minutes: duration)) : null);
    if (resolvedEnd == null) return sStr;

    final eHour = resolvedEnd.hour == 0
        ? 12
        : (resolvedEnd.hour > 12 ? resolvedEnd.hour - 12 : resolvedEnd.hour);
    final eAmPm = resolvedEnd.hour >= 12 ? 'PM' : 'AM';
    final eMin = resolvedEnd.minute.toString().padLeft(2, '0');
    final eStr = '$eHour:$eMin $eAmPm';

    return '$sStr – $eStr';
  }

  String _formatClassBadge(DateTime? start, DateTime now) {
    if (start == null) return 'Upcoming';
    final sLocal = start.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final classDay = DateTime(sLocal.year, sLocal.month, sLocal.day);
    final diffDays = classDay.difference(today).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    const months = [
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
    return '${sLocal.day} ${months[sLocal.month - 1]}';
  }

  String _cleanHtml(String? html) {
    if (html == null || html.isEmpty) return '';
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
