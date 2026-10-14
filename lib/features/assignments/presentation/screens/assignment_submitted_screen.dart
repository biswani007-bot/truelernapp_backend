import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/assignment_submission_entity.dart';
import '../controllers/assignment_submission_controller.dart';
import '../widgets/assignments_skeleton.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';

/// SCR-19: Assignment Submitted Screen (Figma Node 76:2611 "Assignment Submitted (Revised)")
///
/// Fully dynamic:
/// 1. Backed by backend assignment and submission models via [assignmentSubmissionControllerProvider].
/// 2. If assignment details are not in state or loading, displays a shimmer skeleton matching the Figma bento geometry.
/// 3. If API fetch fails, displays an error state with a Retry button.
/// 4. Shows actual submission timestamp, status, assignment title, topic, description, and connected class navigation.
class AssignmentSubmittedScreen extends ConsumerStatefulWidget {
  final String? assignmentId;
  final AssignmentEntity? assignment;

  const AssignmentSubmittedScreen({
    super.key,
    this.assignmentId,
    this.assignment,
  });

  @override
  ConsumerState<AssignmentSubmittedScreen> createState() =>
      _AssignmentSubmittedScreenState();
}

class _AssignmentSubmittedScreenState
    extends ConsumerState<AssignmentSubmittedScreen> {
  String get _effectiveAssignmentId =>
      widget.assignmentId ?? widget.assignment?.id ?? 'default_asg';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        _initController();
      }
    });
  }

  void _initController() {
    final childrenState = ref.read(childrenControllerProvider);
    String? activeChildId;
    if (childrenState is ChildrenLoaded) {
      activeChildId = childrenState.activeChildId;
    }
    activeChildId ??= widget.assignment?.childStudentId;

    ref
        .read(assignmentSubmissionControllerProvider.notifier)
        .init(
          assignmentId: _effectiveAssignmentId,
          childStudentId: activeChildId,
          initialAssignment: widget.assignment,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChildrenState>(childrenControllerProvider, (prev, next) {
      if (next is ChildrenLoaded) {
        final prevChildId = prev is ChildrenLoaded ? prev.activeChildId : null;
        if (prevChildId != next.activeChildId && next.activeChildId != null) {
          ref
              .read(assignmentSubmissionControllerProvider.notifier)
              .init(
                assignmentId: _effectiveAssignmentId,
                childStudentId: next.activeChildId,
                initialAssignment: null,
              );
        }
      }
    });

    final subState = ref.watch(
      singleAssignmentSubmissionProvider(_effectiveAssignmentId),
    );

    final currentAssignment = subState.assignment ?? widget.assignment;

    final isLoading =
        (subState.status == SubmissionFlowStatus.loadingDetail ||
            subState.status == SubmissionFlowStatus.initial) &&
        currentAssignment == null;

    final isError =
        subState.status == SubmissionFlowStatus.error &&
        currentAssignment == null;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching TrueLern Figma canvas (Node 76:2611)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.8, -1.0),
                end: Alignment(0.8, 1.0),
                stops: [0.0, 0.5, 1.0],
                colors: [
                  Color(0xFFF3E8FF), // Light purple
                  Color(0xFFE0F2FE), // Sky blue tint
                  Color(0xFFFFFFFF), // Pure white
                ],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: AppRefreshIndicator(
              onRefresh: () async {
                _initController();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: isLoading
                        ? _buildLoadingSkeleton()
                        : (isError
                              ? _buildErrorState(subState.errorMessage)
                              : _buildSubmittedContent(
                                  currentAssignment,
                                  subState,
                                )),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full loading skeleton matching the submitted screen's Bento layout
  Widget _buildLoadingSkeleton() {
    return Column(
      key: const Key('submitted_loading_skeleton'),
      children: [
        const SizedBox(height: 16),
        // Hero icon shimmer
        const Center(
          child: AssignmentShimmerBox(
            width: 180,
            height: 180,
            borderRadius: 32,
            opacity: 0.7,
          ),
        ),
        const SizedBox(height: 24),
        // Title shimmer
        const Center(
          child: AssignmentShimmerBox(
            width: 260,
            height: 32,
            borderRadius: 8,
            opacity: 0.7,
          ),
        ),
        const SizedBox(height: 12),
        // Subtitle shimmer
        const Center(
          child: AssignmentShimmerBox(
            width: 320,
            height: 20,
            borderRadius: 6,
            opacity: 0.5,
          ),
        ),
        const SizedBox(height: 36),

        // Bento Card 1 Shimmer (Submission Details)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AssignmentShimmerBox(
                width: 160,
                height: 20,
                borderRadius: 6,
                opacity: 0.7,
              ),
              SizedBox(height: 16),
              AssignmentShimmerBox(
                width: double.infinity,
                height: 16,
                borderRadius: 4,
                opacity: 0.5,
              ),
              SizedBox(height: 16),
              AssignmentShimmerBox(
                width: double.infinity,
                height: 16,
                borderRadius: 4,
                opacity: 0.5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bento Card 2 Shimmer (Related Class Context)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AssignmentShimmerBox(
                    width: 48,
                    height: 48,
                    borderRadius: 12,
                    opacity: 0.7,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AssignmentShimmerBox(
                          width: 100,
                          height: 14,
                          borderRadius: 4,
                          opacity: 0.7,
                        ),
                        SizedBox(height: 6),
                        AssignmentShimmerBox(
                          width: 180,
                          height: 18,
                          borderRadius: 4,
                          opacity: 0.7,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              AssignmentShimmerBox(
                width: double.infinity,
                height: 16,
                borderRadius: 4,
                opacity: 0.5,
              ),
              SizedBox(height: 14),
              AssignmentShimmerBox(
                width: 130,
                height: 16,
                borderRadius: 4,
                opacity: 0.7,
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // CTA Shimmer
        const Center(
          child: AssignmentShimmerBox(
            width: 220,
            height: 52,
            borderRadius: 9999,
            opacity: 0.7,
          ),
        ),
      ],
    );
  }

  /// Error state if loading assignment details failed
  Widget _buildErrorState(String? errorMessage) {
    return Container(
      key: const Key('submitted_error_state'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFBA1A1A),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load submission',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF434655),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('submitted_retry_button'),
            onPressed: _initController,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0037B1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Real submission content
  Widget _buildSubmittedContent(
    AssignmentEntity? assignment,
    AssignmentSubmissionState subState,
  ) {
    final topic = assignment?.topic ?? 'Academics';
    final classTitle = assignment?.title ?? 'Class Assignment';
    final description =
        assignment?.description ??
        assignment?.instructions ??
        'This assignment is connected to the recent live class. Review the materials if needed.';

    final submission = subState.submission ?? assignment?.submission;

    final submittedTime = _formatSubmissionTimestamp(submission?.submittedAt);
    final statusLabel = _resolveStatusLabel(submission);

    final scoreVal = assignment?.score ?? submission?.marksAwarded;
    final totalMarksVal = assignment?.totalMarks ?? 100;
    final gradeVal = assignment?.grade ?? submission?.grade;
    final String? gradeDisplay = scoreVal != null
        ? '$scoreVal/$totalMarksVal${gradeVal != null && gradeVal.isNotEmpty ? ' ($gradeVal)' : ''}'
        : (gradeVal != null && gradeVal.isNotEmpty ? gradeVal : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Success Hero Section (Figma Node 76:2613)
        _buildHeroSection(topic),
        const SizedBox(height: 36),

        // 2. Details & Context Grid (Bento Style) (Figma Node 76:2631)
        _buildSummaryCard(
          submittedTime,
          statusLabel,
          gradeDisplay: gradeDisplay,
        ),
        const SizedBox(height: 16),
        _buildRelatedClassCard(
          context,
          topic: topic,
          classTitle: classTitle,
          description: description,
          classId: assignment?.classId,
        ),
        const SizedBox(height: 36),

        // 3. Primary CTA: BACK TO LEARNING (Figma Node 76:2668)
        _buildBackToLearningButton(context),
      ],
    );
  }

  /// 1. Success Hero Section (Node 76:2613)
  Widget _buildHeroSection(String topic) {
    return Column(
      children: [
        // Large Clay 3D Representation with Success Badge (Node 76:2614)
        SizedBox(
          width: 208,
          height: 208,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Blue blur shadow glow under clay card
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                bottom: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E4ED8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),

              // Rotated white 3D clay tile (Node 76:2617)
              Transform.rotate(
                angle: 3 * 3.141592653589793 / 180, // 3 deg
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/submission_puzzle_large.svg',
                      width: 64,
                      height: 67,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Green Success Badge with white checkmark (Node 76:2621)
              Positioned(
                right: 4,
                bottom: 2,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/submission_badge_check.svg',
                      width: 23,
                      height: 18,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Heading 1: "Assignment Submitted" (Node 76:2627)
        Text(
          'Assignment Submitted',
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0037B1),
            letterSpacing: -0.7,
            height: 36 / 28,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle (Node 76:2629)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Great job! Your $topic assignment is\nsecurely in the hands of our reviewers.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF434655),
              height: 24 / 16,
            ),
          ),
        ),
      ],
    );
  }

  /// 2A. Summary Card (Node 76:2632)
  Widget _buildSummaryCard(
    String submittedTime,
    String statusLabel, {
    String? gradeDisplay,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Color(0xFFA855F7), // Purple accent bar (76:2650)
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading 3: "Submission Details" (Node 76:2633)
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/submission_doc_icon.svg',
                  width: 16,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF1A1B23),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Submission Details',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1B23),
                      height: 24 / 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 1: Submitted vs Today, 4:30 PM (Node 76:2638)
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E1ED), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Submitted',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF434655),
                        height: 20 / 14,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      submittedTime,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1B23),
                        letterSpacing: 0.1,
                        height: 20 / 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Row 2: Status vs Under Review pill (Node 76:2643)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Status',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF434655),
                        height: 20 / 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E7F3),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/submission_hourglass.svg',
                          width: 11,
                          height: 14,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF0037B1),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0037B1),
                            height: 16 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Row 3 (Optional): Grade vs 100/100
            if (gradeDisplay != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E1ED), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Grade',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF434655),
                          height: 20 / 14,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        gradeDisplay,
                        textAlign: TextAlign.end,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0037B1),
                          letterSpacing: 0.1,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 2B. Related Class Context Card (Node 76:2651)
  Widget _buildRelatedClassCard(
    BuildContext context, {
    required String topic,
    required String classTitle,
    required String description,
    String? classId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Class header: Icon + Topic uppercase + Title (Node 76:2653)
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/submission_puzzle_small.svg',
                    width: 19,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFA855F7),
                      BlendMode.srcIn,
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
                      topic.toUpperCase(),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFA855F7),
                        letterSpacing: 0.6,
                        height: 16 / 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      classTitle,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1B23),
                        height: 20 / 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description (Node 76:2663)
          Text(
            description,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF434655),
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 14),

          // "View Class Details ->" link (Node 76:2664)
          InkWell(
            key: const Key('view_class_details_link'),
            onTap: () => context.pushNamed(AppRouteNames.currentProgram),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Class Details',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0037B1),
                      letterSpacing: 0.1,
                      height: 20 / 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    'assets/icons/submission_arrow_right.svg',
                    width: 12,
                    height: 12,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF0037B1),
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Primary CTA: BACK TO LEARNING (Node 76:2668)
  Widget _buildBackToLearningButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        key: const Key('back_to_learning_button'),
        onPressed: () => context.goNamed(AppRouteNames.parentDashboard),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0037B1),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BACK TO LEARNING',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.1,
                height: 20 / 14,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/icons/submission_cap.svg',
              width: 22,
              height: 18,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats submission timestamp according to requirements:
  /// - Today → “Today, 3:29 PM”
  /// - Yesterday → “Yesterday, 3:29 PM”
  /// - Older → “28 Sep 2026, 3:29 PM”
  /// Ensures local timezone conversion.
  String _formatSubmissionTimestamp(DateTime? submittedAt) {
    if (submittedAt == null) {
      return 'Just now';
    }

    final localDt = submittedAt.toLocal();
    final now = DateTime.now();

    final isToday =
        localDt.year == now.year &&
        localDt.month == now.month &&
        localDt.day == now.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        localDt.year == yesterday.year &&
        localDt.month == yesterday.month &&
        localDt.day == yesterday.day;

    final hour = localDt.hour > 12
        ? localDt.hour - 12
        : (localDt.hour == 0 ? 12 : localDt.hour);
    final ampm = localDt.hour >= 12 ? 'PM' : 'AM';
    final minute = localDt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    if (isToday) {
      return 'Today, $timeStr';
    }

    if (isYesterday) {
      return 'Yesterday, $timeStr';
    }

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
    final monthName = months[localDt.month - 1];
    return '${localDt.day} $monthName ${localDt.year}, $timeStr';
  }

  /// Resolves the actual dynamic status label from backend submission record.
  String _resolveStatusLabel(AssignmentSubmissionEntity? submission) {
    if (submission == null) {
      return 'Submitted';
    }

    if (submission.isGraded) {
      return 'Graded';
    }

    final raw = submission.rawStatus?.trim();
    if (raw != null && raw.isNotEmpty) {
      final lower = raw.toLowerCase();
      if (lower == 'under_review' ||
          lower == 'in_review' ||
          lower == 'pending_review' ||
          lower == 'submitted') {
        return 'Under Review';
      }
      if (lower == 'graded' || lower == 'evaluated') {
        return 'Graded';
      }
      if (lower == 'submitted_late' || lower == 'late') {
        return 'Submitted Late';
      }
      if (lower == 'draft') {
        return 'Draft';
      }
      // If backend returned another string (e.g., 'Approved', 'Rejected'), convert snake_case to Title Case
      return raw
          .split(RegExp(r'[_ -]'))
          .map((word) {
            if (word.isEmpty) return '';
            return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
          })
          .join(' ');
    }

    return switch (submission.status) {
      SubmissionStatus.graded => 'Graded',
      SubmissionStatus.late => 'Submitted Late',
      SubmissionStatus.draft => 'Draft',
      _ => 'Under Review',
    };
  }
}
