import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../classes/presentation/widgets/classes_student_selector.dart';
import '../../../progress/domain/entities/progress_entity.dart';
import '../../../progress/presentation/controllers/progress_controller.dart';
import '../../../progress/presentation/controllers/progress_state.dart';
import '../controllers/children_controller.dart';
import '../controllers/children_state.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Parent Learning Progress Screen.
///
/// Displays real academic progress data from GET /api/parent/children/:studentId/progress.
/// Features:
/// - Real overall mastery circular gauge with exact backend percentage
/// - Dynamic metric cards (Assignments, Attendance, Assessments) with real values
/// - Child switching with automatic reload
/// - Pull-to-refresh via [AppRefreshIndicator]
/// - Loading shimmer skeleton, error handling with retry, and empty state
class ParentLearningProgressScreen extends ConsumerStatefulWidget {
  const ParentLearningProgressScreen({super.key});

  @override
  ConsumerState<ParentLearningProgressScreen> createState() =>
      _ParentLearningProgressScreenState();
}

class _ParentLearningProgressScreenState
    extends ConsumerState<ParentLearningProgressScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _logo = 'assets/images/learning_progress_logo.png';
  static const _iconBrain = 'assets/images/learning_progress_icon_brain.png';
  static const _iconCommunication =
      'assets/images/learning_progress_icon_communication.png';
  static const _iconPractical =
      'assets/images/learning_progress_icon_practical.png';

  static const _svgDrawer = 'assets/icons/learning_progress_drawer.svg';
  static const _svgBell = 'assets/icons/learning_progress_bell.svg';
  static const _svgNavHome = 'assets/icons/learning_progress_home.svg';
  static const _svgNavClasses = 'assets/icons/learning_progress_classes.svg';
  static const _svgNavAssignment =
      'assets/icons/learning_progress_assignment.svg';
  static const _svgNavProfile = 'assets/icons/learning_progress_profile.svg';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialProgress();
    });
  }

  void _loadInitialProgress() {
    final childrenState = ref.read(childrenControllerProvider);
    if (childrenState is ChildrenLoaded) {
      final activeChild = childrenState.activeChild;
      ref
          .read(progressControllerProvider.notifier)
          .loadProgress(
            childStudentId: activeChild?.studentId,
            studentName: activeChild?.firstName,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for child switching from childrenControllerProvider
    ref.listen<ChildrenState>(childrenControllerProvider, (prev, next) {
      if (next is ChildrenLoaded) {
        final activeChild = next.activeChild;
        ref
            .read(progressControllerProvider.notifier)
            .loadProgress(
              childStudentId: activeChild?.studentId,
              studentName: activeChild?.firstName,
            );
      }
    });

    final progressState = ref.watch(progressControllerProvider);
    final childrenState = ref.watch(childrenControllerProvider);
    final activeChild = childrenState is ChildrenLoaded
        ? childrenState.activeChild
        : null;
    final childName = activeChild?.firstName ?? 'Student';

    return Scaffold(
      key: _scaffoldKey,
      drawer: const ParentHamburgerDrawer(),
      backgroundColor: Colors.white,
      body: Container(
        key: const Key('parent_learning_progress_screen'),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -0.7),
            end: Alignment(0.7, 0.7),
            colors: [
              Color(0xFFF3E8FF), // rgb(243, 232, 255) 0%
              Color(0xFFE0F2FE), // rgb(224, 242, 254) 50%
              Color(0xFFFFFFFF), // rgb(255, 255, 255) 100%
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Top App Bar ────────────────────────────────────────
              _buildTopAppBar(context),

              // ── Child Selector Pill (Parent mode) ──────────────────
              if (childrenState is ChildrenLoaded &&
                  childrenState.children.isNotEmpty &&
                  activeChild != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Center(
                    child: ClassesStudentSelector(
                      activeChild: activeChild,
                      children: childrenState.children,
                      onChildSelected: (childId) {
                        ref
                            .read(childrenControllerProvider.notifier)
                            .setActiveChild(childId);
                      },
                    ),
                  ),
                ),

              // ── Scrollable Content ─────────────────────────────────
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(progressControllerProvider.notifier)
                        .refresh();
                  },
                  child: SingleChildScrollView(
                    key: const Key('learning_progress_scroll_view'),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildBody(context, progressState, childName),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Single Bottom Navigation Bar ───────────────────────
              _buildBottomNavBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top App Bar ──────────────────────────────────────────────────────────
  Widget _buildTopAppBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
            boxShadow: const [
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
              Row(
                children: [
                  IconButton(
                    key: const Key('progress_back_button'),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF1A1B23),
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutePaths.parentDashboard);
                      }
                    },
                  ),
                  InkWell(
                    key: const Key('learning_progress_drawer_button'),
                    borderRadius: BorderRadius.circular(9999),
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: SvgPicture.asset(
                          _svgDrawer,
                          width: 18,
                          height: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // TrueLern Logo
              Image.asset(
                _logo,
                width: 132,
                height: 45.26,
                fit: BoxFit.contain,
              ),

              // Bell Notification Button
              InkWell(
                key: const Key('learning_progress_bell_button'),
                borderRadius: BorderRadius.circular(9999),
                onTap: () => context.go(AppRoutePaths.notifications),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SvgPicture.asset(_svgBell, width: 16, height: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Body Switcher (Loading, Error, Empty, Loaded) ─────────────────────────
  Widget _buildBody(
    BuildContext context,
    ProgressState state,
    String childName,
  ) {
    if (state is ProgressLoading && state.previousProgress == null) {
      return _buildSkeleton();
    }

    if (state is ProgressError) {
      return _buildErrorState(state.message);
    }

    if (state is ProgressEmpty) {
      return _buildEmptyState(state.message, childName);
    }

    final ProgressEntity progress;
    if (state is ProgressLoaded) {
      progress = state.progress;
    } else if (state is ProgressLoading && state.previousProgress != null) {
      progress = state.previousProgress!;
    } else {
      // Initial state fallback
      return _buildSkeleton();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),

        // ── Header Section ─────────────────────────────────────────
        _buildHeaderSection(childName, progress),

        const SizedBox(height: 24),

        // ── Overall Progress Dial Card ─────────────────────────────
        _buildDialCard(progress.overallCompletion),

        const SizedBox(height: 24),

        // ── Section Title ──────────────────────────────────────────
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Performance Breakdown',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Dynamic Metric Cards ───────────────────────────────────
        _buildDynamicMetricCards(progress),

        const SizedBox(height: 16),

        // ── View Detailed Report Button ────────────────────────────
        _buildDetailedReportButton(),

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Header Section ───────────────────────────────────────────────────────
  Widget _buildHeaderSection(String childName, ProgressEntity progress) {
    final trackName = progress.activeTrack ?? 'Academic Performance & Mastery';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // "Progress" Heading (renamed from "My Progress")
        Text(
          'Progress',
          key: const Key('progress_screen_title'),
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B23),
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 8),

        // Track Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF22D3EE).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(
            trackName,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0284C7),
              height: 20 / 14,
            ),
          ),
        ),
      ],
    );
  }

  // ── Overall Progress Dial Card ───────────────────────────────────────────
  Widget _buildDialCard(double overallCompletion) {
    final displayPercentage = '${overallCompletion.round()}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 36, bottom: 24),
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
      child: Center(
        child: SizedBox(
          width: 248,
          height: 248,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dynamic Circular dial gauge
              CustomPaint(
                size: const Size(248, 248),
                painter: _MasteryDialPainter(percentage: overallCompletion),
              ),

              // Center Text Container
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayPercentage,
                    key: const Key('progress_overall_percentage'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0037B1),
                      height: 38 / 32,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overall Mastery',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF434655),
                      height: 18 / 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dynamic Metric Cards ─────────────────────────────────────────────────
  Widget _buildDynamicMetricCards(ProgressEntity progress) {
    return Column(
      children: [
        // 1. Assignments Card
        _buildSkillCard(
          key: const Key('metric_card_assignments'),
          title: 'Assignments',
          level:
              '${progress.assignmentCompletion.completed} of ${progress.assignmentCompletion.total} submitted',
          percentage: '${progress.assignmentCompletion.percentage.round()}%',
          progressValue: (progress.assignmentCompletion.percentage / 100.0)
              .clamp(0.0, 1.0),
          accentColor: const Color(0xFF22D3EE),
          iconAsset: _iconPractical,
          iconBgColor: const Color(0xFF22D3EE).withValues(alpha: 0.1),
        ),
        const SizedBox(height: 12),

        // 2. Attendance Card
        _buildSkillCard(
          key: const Key('metric_card_attendance'),
          title: 'Attendance',
          level:
              '${progress.attendanceSummary.attended} of ${progress.attendanceSummary.totalClasses} classes attended',
          percentage: '${progress.attendanceSummary.percentage.round()}%',
          progressValue: (progress.attendanceSummary.percentage / 100.0).clamp(
            0.0,
            1.0,
          ),
          accentColor: const Color(0xFF10B981),
          iconAsset: _iconCommunication,
          iconBgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
        ),
        const SizedBox(height: 12),

        // 3. Assessments Card
        _buildSkillCard(
          key: const Key('metric_card_assessments'),
          title: 'Assessments',
          level:
              '${progress.assessmentCompletion.completed} of ${progress.assessmentCompletion.total} evaluated',
          percentage: '${progress.assessmentCompletion.percentage.round()}%',
          progressValue: (progress.assessmentCompletion.percentage / 100.0)
              .clamp(0.0, 1.0),
          accentColor: const Color(0xFFFB7185),
          iconAsset: _iconBrain,
          iconBgColor: const Color(0xFFFB7185).withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildSkillCard({
    required Key key,
    required String title,
    required String level,
    required String percentage,
    required double progressValue,
    required Color accentColor,
    required String iconAsset,
    required Color iconBgColor,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Image.asset(
                          iconAsset,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.insights_rounded,
                            size: 20,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1B23),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            level,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF434655),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                percentage,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── View Detailed Report Button ──────────────────────────────────────────
  Widget _buildDetailedReportButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        key: const Key('view_detailed_report_button'),
        onPressed: () {
          // Open parent classes schedule on top of progress screen
          context.push(AppRoutePaths.progressClasses);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E1ED), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        child: Text(
          'View Classes & Schedule',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0037B1),
          ),
        ),
      ),
    );
  }

  // ── Skeleton Loading ─────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 120,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 180,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 248,
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
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF0037B1),
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < 3; i++) ...[
          Container(
            width: double.infinity,
            height: 72,
            margin: const EdgeInsets.only(bottom: 12),
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
          ),
        ],
      ],
    );
  }

  // ── Error State ──────────────────────────────────────────────────────────
  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load progress',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            key: const Key('progress_retry_button'),
            onPressed: () {
              ref.read(progressControllerProvider.notifier).retry();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0037B1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message, String childName) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              color: Color(0xFF0037B1),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Progress unavailable',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Academic performance tracking for $childName will appear here once live class sessions and assignments begin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav Bar ───────────────────────────────────────────────────────
  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x0D000000), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildNavBarItem(
                  iconSvg: _svgNavHome,
                  iconWidth: 20,
                  iconHeight: 20,
                  label: 'Home',
                  isActive: false,
                  activeColor: const Color(0xFF0037B1),
                  inactiveColor: const Color(0xFF475569),
                  onTap: () => context.go(AppRoutePaths.parentDashboard),
                ),
              ),
              Expanded(
                child: _buildNavBarItem(
                  iconSvg: _svgNavClasses,
                  iconWidth: 20,
                  iconHeight: 20,
                  label: 'My Classes',
                  isActive: false,
                  activeColor: const Color(0xFF0037B1),
                  inactiveColor: const Color(0xFF475569),
                  onTap: () => context.go(AppRoutePaths.parentClasses),
                ),
              ),
              Expanded(
                child: _buildNavBarItem(
                  iconSvg: _svgNavAssignment,
                  iconWidth: 16,
                  iconHeight: 20,
                  label: 'Assignment',
                  isActive: false,
                  activeColor: const Color(0xFF0037B1),
                  inactiveColor: const Color(0xFF475569),
                  onTap: () => context.go(AppRoutePaths.parentAssignments),
                ),
              ),
              Expanded(
                child: _buildNavBarItem(
                  iconSvg: _svgNavProfile,
                  iconWidth: 16,
                  iconHeight: 20,
                  label: 'Profile',
                  isActive: false,
                  activeColor: const Color(0xFF0037B1),
                  inactiveColor: const Color(0xFF475569),
                  onTap: () => context.go(AppRoutePaths.parentProfile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required String iconSvg,
    required double iconWidth,
    required double iconHeight,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    final color = isActive ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconSvg,
              width: iconWidth,
              height: iconHeight,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: color,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dynamic custom painter for the 248x248 Overall Mastery Dial gauge.
///
/// Draws:
/// - Background track: #F1F5F9 ring
/// - Active progress arc in #0037B1 mapped exactly from backend percentage
class _MasteryDialPainter extends CustomPainter {
  const _MasteryDialPainter({required this.percentage});

  final double percentage; // 0.0 to 100.0

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 26.1778) / 2;

    // 1. Background full circular ring
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26.1778;
    canvas.drawCircle(center, radius, bgPaint);

    if (percentage <= 0) return;

    // 2. Active arc in TrueLern Blue (#0037B1)
    final bluePaint = Paint()
      ..color = const Color(0xFF0037B1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19.2889
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweep = (percentage.clamp(0.0, 100.0) / 100.0) * 2 * math.pi;
    const startAngle = -math.pi / 2; // start from top (12 o'clock)

    canvas.drawArc(rect, startAngle, sweep, false, bluePaint);
  }

  @override
  bool shouldRepaint(covariant _MasteryDialPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
