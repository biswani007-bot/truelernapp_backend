import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../../classes/presentation/widgets/classes_student_selector.dart';
import '../../../dashboard/domain/entities/child_entity.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../../dashboard/presentation/widgets/parent_hamburger_drawer.dart';
import '../../domain/entities/assessment_entity.dart';
import '../../domain/entities/assessment_question_entity.dart';
import '../controllers/assessments_controller.dart';
import '../controllers/assessments_state.dart';
import '../widgets/assessment_card.dart';
import '../widgets/assessment_questions_sheet.dart';

/// TrueLern Parent & Student Assessments Screen.
///
/// Implemented directly from the TrueLern API collection:
/// - GET /api/parent/children/:studentId/assessments (Parent role)
/// - GET /api/assessments (Student role)
/// - POST /api/parent/children/:studentId/assessments/:assessmentId/launch
/// - GET /api/assessments/:assessmentId/questions
///
/// Matches the authentic TrueLern mobile aesthetic:
/// - Canvas gradient (#F3E8FF -> #E0F2FE -> #FFFFFF)
/// - Active Child Selector pill
/// - Comprehensive Loading, Empty, Error, and Loaded states
/// - Micro-animations & pull-to-refresh
class ParentAssessmentsScreen extends ConsumerStatefulWidget {
  const ParentAssessmentsScreen({super.key});

  @override
  ConsumerState<ParentAssessmentsScreen> createState() =>
      _ParentAssessmentsScreenState();
}

class _ParentAssessmentsScreenState
    extends ConsumerState<ParentAssessmentsScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadInitialData(isRefresh: true);
    }
  }

  void _loadInitialData({bool isRefresh = false}) {
    final authState = ref.read(authControllerProvider);
    final userRole = authState is Authenticated ? authState.user?.role : null;
    final isStudent = (userRole ?? '').toLowerCase() == 'student';

    if (isStudent) {
      ref
          .read(assessmentsControllerProvider.notifier)
          .loadAssessments(isRefresh: isRefresh);
    } else {
      final childrenState = ref.read(childrenControllerProvider);
      final activeChildId = childrenState is ChildrenLoaded
          ? childrenState.activeChildId
          : null;
      ref
          .read(assessmentsControllerProvider.notifier)
          .loadAssessments(childStudentId: activeChildId, isRefresh: isRefresh);
    }
  }

  Future<void> _onRefresh() async {
    final authState = ref.read(authControllerProvider);
    final userRole = authState is Authenticated ? authState.user?.role : null;
    final isStudent = (userRole ?? '').toLowerCase() == 'student';

    if (isStudent) {
      await ref
          .read(assessmentsControllerProvider.notifier)
          .loadAssessments(isRefresh: true);
    } else {
      final childrenState = ref.read(childrenControllerProvider);
      final activeChildId = childrenState is ChildrenLoaded
          ? childrenState.activeChildId
          : null;

      await Future.wait([
        ref
            .read(assessmentsControllerProvider.notifier)
            .loadAssessments(childStudentId: activeChildId, isRefresh: true),
        ref
            .read(childrenControllerProvider.notifier)
            .loadChildren(isRefresh: true),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final userRole = authState is Authenticated ? authState.user?.role : null;
    final isStudent = (userRole ?? '').toLowerCase() == 'student';

    final childrenState = ref.watch(childrenControllerProvider);
    final assessmentsState = ref.watch(assessmentsControllerProvider);

    final List<ChildEntity> children = childrenState is ChildrenLoaded
        ? childrenState.children
        : const [];
    final ChildEntity? activeChild = childrenState is ChildrenLoaded
        ? childrenState.activeChild
        : null;
    final String? activeChildId = activeChild?.studentId;

    // Synchronize active child changes in Parent mode
    if (!isStudent) {
      ref.listen<ChildrenState>(childrenControllerProvider, (previous, next) {
        if (next is ChildrenLoaded) {
          final prevId = previous is ChildrenLoaded
              ? previous.activeChildId
              : null;
          if (prevId != next.activeChildId && next.activeChildId != null) {
            ref
                .read(assessmentsControllerProvider.notifier)
                .loadAssessments(childStudentId: next.activeChildId);
          }
        }
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const ParentHamburgerDrawer(activeItem: 'Assessments'),
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -0.7),
            end: Alignment(0.7, 0.7),
            colors: AppColors.canvasGradient,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top App Bar
              _buildTopAppBar(context),

              // Feedback banner for launched session
              if (assessmentsState is AssessmentsLoaded &&
                  (assessmentsState.launchSuccessMessage != null ||
                      assessmentsState.launchError != null))
                _buildFeedbackBanner(assessmentsState),

              // Main Scrollable Area with Pull-to-Refresh
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    key: const Key('assessments_scroll_view'),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: 40,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Child Selector in Parent mode
                            if (!isStudent && activeChild != null) ...[
                              ClassesStudentSelector(
                                activeChild: activeChild,
                                children: children,
                                onChildSelected: (newStudentId) {
                                  ref
                                      .read(childrenControllerProvider.notifier)
                                      .setActiveChild(newStudentId);
                                },
                              ),
                              const SizedBox(height: 20),
                            ],

                            // State Rendering
                            switch (assessmentsState) {
                              AssessmentsInitial() ||
                              AssessmentsLoading() => _buildLoadingState(),
                              AssessmentsError(
                                :final message,
                                :final activeChildId,
                              ) =>
                                _buildErrorState(message, activeChildId),
                              AssessmentsLoaded(
                                :final assessments,
                                :final isStudent,
                                :final launchingAssessmentId,
                                :final loadingQuestionsAssessmentId,
                                :final questionsMap,
                              ) =>
                                assessments.isEmpty
                                    ? _buildEmptyState()
                                    : _buildLoadedList(
                                        context,
                                        assessments,
                                        isStudent,
                                        launchingAssessmentId,
                                        loadingQuestionsAssessmentId,
                                        questionsMap,
                                        activeChildId,
                                      ),
                            },
                          ],
                        ),
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

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Navigation Back / Drawer Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('assessments_nav_button'),
              borderRadius: BorderRadius.circular(9999),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Navigator.canPop(context)
                      ? Icons.arrow_back_rounded
                      : Icons.menu_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Text(
              'Assessments',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // Drawer icon on right if can pop
          if (Navigator.canPop(context))
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(9999),
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner(AssessmentsLoaded state) {
    final isError = state.launchError != null;
    final message = isError ? state.launchError! : state.launchSuccessMessage!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            size: 20,
            color: isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isError
                    ? const Color(0xFF991B1B)
                    : const Color(0xFF065F46),
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: isError ? const Color(0xFF991B1B) : const Color(0xFF065F46),
            onPressed: () => ref
                .read(assessmentsControllerProvider.notifier)
                .clearLaunchFeedback(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedList(
    BuildContext context,
    List<AssessmentEntity> assessments,
    bool isStudent,
    String? launchingAssessmentId,
    String? loadingQuestionsAssessmentId,
    Map<String, List<AssessmentQuestionEntity>> questionsMap,
    String? activeChildId,
  ) {
    final pendingAssessments = assessments.where((a) => a.canLaunch).toList();
    final evaluatedAssessments = assessments
        .where((a) => a.isEvaluated || a.isSubmittedPendingEvaluation)
        .toList();

    final bool hasSections =
        pendingAssessments.isNotEmpty && evaluatedAssessments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasSections) ...[
          // Section 1: Pending Assessments
          _buildSectionHeader(
            title: 'Pending Assessments',
            count: pendingAssessments.length,
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFF4F46E5),
          ),
          ...pendingAssessments.map(
            (assessment) => AssessmentCard(
              key: Key('assessment_card_${assessment.assessmentId}'),
              assessment: assessment,
              isLaunching: launchingAssessmentId == assessment.assessmentId,
              isStudent: isStudent,
              onLaunch: () => _handleLaunch(assessment, activeChildId),
              onViewQuestions: () => _handleViewQuestions(assessment),
            ),
          ),
          const SizedBox(height: 16),
          // Section 2: Evaluated Results
          _buildSectionHeader(
            title: 'Evaluated Results',
            count: evaluatedAssessments.length,
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFF059669),
          ),
          ...evaluatedAssessments.map(
            (assessment) => AssessmentCard(
              key: Key('assessment_card_${assessment.assessmentId}'),
              assessment: assessment,
              isLaunching: launchingAssessmentId == assessment.assessmentId,
              isStudent: isStudent,
              onLaunch: () => _handleLaunch(assessment, activeChildId),
              onViewQuestions: () => _handleViewQuestions(assessment),
            ),
          ),
        ] else ...[
          // Single list header matching context
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 2),
            child: Row(
              children: [
                if (evaluatedAssessments.isNotEmpty)
                  const Icon(
                    Icons.military_tech_rounded,
                    size: 18,
                    color: Color(0xFF059669),
                  )
                else
                  const Icon(
                    Icons.assignment_outlined,
                    size: 18,
                    color: Color(0xFF0037B1),
                  ),
                const SizedBox(width: 6),
                Text(
                  evaluatedAssessments.isNotEmpty
                      ? 'Evaluated Results (${assessments.length})'
                      : '${assessments.length} ${assessments.length == 1 ? "Assessment" : "Assessments"} Available',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ...assessments.map(
            (assessment) => AssessmentCard(
              key: Key('assessment_card_${assessment.assessmentId}'),
              assessment: assessment,
              isLaunching: launchingAssessmentId == assessment.assessmentId,
              isStudent: isStudent,
              onLaunch: () => _handleLaunch(assessment, activeChildId),
              onViewQuestions: () => _handleViewQuestions(assessment),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(
            '$title ($count)',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleLaunch(AssessmentEntity assessment, String? activeChildId) async {
    if (activeChildId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student first.')),
      );
      return;
    }

    final childrenState = ref.read(childrenControllerProvider);
    final activeChild = childrenState is ChildrenLoaded
        ? childrenState.activeChild
        : null;
    final studentName = activeChild?.displayName ?? activeChild?.firstName;

    final attemptDetails = await ref
        .read(assessmentsControllerProvider.notifier)
        .prepareAttempt(
          studentId: activeChildId,
          assessmentId: assessment.assessmentId,
          studentName: studentName,
        );

    if (attemptDetails != null && mounted) {
      await context.push(AppRoutePaths.assessmentRunner, extra: attemptDetails);

      // Re-fetch assessments immediately after returning from runner session
      if (mounted) {
        ref
            .read(assessmentsControllerProvider.notifier)
            .loadAssessments(childStudentId: activeChildId, isRefresh: true);
      }
    }
  }

  void _handleViewQuestions(AssessmentEntity assessment) async {
    final controller = ref.read(assessmentsControllerProvider.notifier);
    await controller.loadQuestions(assessmentId: assessment.assessmentId);

    if (!mounted) return;

    final currentState = ref.read(assessmentsControllerProvider);
    final List<AssessmentQuestionEntity> questions =
        currentState is AssessmentsLoaded
        ? currentState.questionsMap[assessment.assessmentId] ??
              const <AssessmentQuestionEntity>[]
        : const <AssessmentQuestionEntity>[];

    AssessmentQuestionsSheet.show(
      context,
      assessmentTitle: assessment.title,
      questions: questions,
      isLoading: false,
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDEDF9)),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, String? activeChildId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could Not Load Assessments',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('assessments_retry_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => ref
                  .read(assessmentsControllerProvider.notifier)
                  .retry(childStudentId: activeChildId),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Try Again',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Icon(
                Icons.quiz_outlined,
                color: Color(0xFF0037B1),
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Assessments Scheduled',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no active or pending assessments for this student. Any upcoming quizzes or tests will show up here automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
