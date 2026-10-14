import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../data/repositories/assessments_repository_impl.dart';
import '../../domain/entities/assessment_attempt_details_entity.dart';
import '../../domain/repositories/assessments_repository.dart';
import 'assessments_state.dart';

/// Riverpod controller managing assessment operations.
class AssessmentsController extends Notifier<AssessmentsState> {
  @override
  AssessmentsState build() => const AssessmentsInitial();

  AssessmentsRepository get _repository =>
      ref.read(assessmentsRepositoryProvider);

  /// Loads assessments according to current role (Parent vs Student).
  Future<void> loadAssessments({
    String? childStudentId,
    bool isRefresh = false,
  }) async {
    final current = state;
    if (!isRefresh || current is! AssessmentsLoaded) {
      state = const AssessmentsLoading();
    }

    final authState = ref.read(authControllerProvider);
    final userRole = authState is Authenticated ? authState.user?.role : null;
    final isStudent = (userRole ?? '').toLowerCase() == 'student';

    try {
      if (isStudent) {
        final assessments = await _repository.getStudentAssessments();
        state = AssessmentsLoaded(assessments: assessments, isStudent: true);
      } else {
        if (childStudentId == null || childStudentId.trim().isEmpty) {
          state = const AssessmentsLoaded(
            assessments: [],
            isStudent: false,
            activeChildId: null,
          );
          return;
        }

        final assessments = await _repository.getChildAssessments(
          studentId: childStudentId,
        );

        state = AssessmentsLoaded(
          assessments: assessments,
          activeChildId: childStudentId,
          isStudent: false,
        );
      }
    } catch (error) {
      state = AssessmentsError(
        message: _formatError(error),
        activeChildId: childStudentId,
      );
    }
  }

  /// Retries the most recent fetch.
  Future<void> retry({String? childStudentId}) =>
      loadAssessments(childStudentId: childStudentId);

  /// Prepares a full native assessment attempt for a child (Parent role).
  Future<AssessmentAttemptDetailsEntity?> prepareAttempt({
    required String studentId,
    required String assessmentId,
    String? studentName,
  }) async {
    final current = state;
    if (current is! AssessmentsLoaded) return null;

    state = current.copyWith(
      launchingAssessmentId: assessmentId,
      clearLaunchError: true,
      clearLaunchSuccessMessage: true,
    );

    try {
      final attemptDetails = await _repository.prepareAssessmentAttempt(
        studentId: studentId,
        assessmentId: assessmentId,
        studentName: studentName,
      );

      state = (state as AssessmentsLoaded).copyWith(
        clearLaunchingAssessmentId: true,
      );
      return attemptDetails;
    } catch (error) {
      state = (state as AssessmentsLoaded).copyWith(
        clearLaunchingAssessmentId: true,
        launchError: _formatError(error),
      );
      return null;
    }
  }

  /// Launches an assessment session for a child (Parent role).
  ///
  /// Calls POST /api/parent/children/:studentId/assessments/:assessmentId/launch
  Future<String?> launchAssessment({
    required String studentId,
    required String assessmentId,
    String? notes,
  }) async {
    final current = state;
    if (current is! AssessmentsLoaded) return null;

    state = current.copyWith(
      launchingAssessmentId: assessmentId,
      clearLaunchError: true,
      clearLaunchSuccessMessage: true,
    );

    try {
      final redirectUrl = await _repository.launchAssessment(
        studentId: studentId,
        assessmentId: assessmentId,
        notes: notes,
      );

      state = (state as AssessmentsLoaded).copyWith(
        clearLaunchingAssessmentId: true,
        launchedRedirectUrl: redirectUrl,
        launchSuccessMessage: 'Assessment session created successfully!',
      );
      return redirectUrl;
    } catch (error) {
      state = (state as AssessmentsLoaded).copyWith(
        clearLaunchingAssessmentId: true,
        launchError: _formatError(error),
      );
      return null;
    }
  }

  /// Loads questions for an assessment from GET /api/assessments/:assessmentId/questions.
  Future<void> loadQuestions({required String assessmentId}) async {
    final current = state;
    if (current is! AssessmentsLoaded) return;

    if (current.questionsMap.containsKey(assessmentId)) {
      return; // Already cached
    }

    state = current.copyWith(loadingQuestionsAssessmentId: assessmentId);

    try {
      final questions = await _repository.getAssessmentQuestions(
        assessmentId: assessmentId,
      );

      final updatedMap = Map.of((state as AssessmentsLoaded).questionsMap);
      updatedMap[assessmentId] = questions;

      state = (state as AssessmentsLoaded).copyWith(
        clearLoadingQuestionsAssessmentId: true,
        questionsMap: updatedMap,
      );
    } catch (_) {
      state = (state as AssessmentsLoaded).copyWith(
        clearLoadingQuestionsAssessmentId: true,
      );
    }
  }

  /// Clears transient launch messages from the UI banner.
  void clearLaunchFeedback() {
    final current = state;
    if (current is AssessmentsLoaded) {
      state = current.copyWith(
        clearLaunchSuccessMessage: true,
        clearLaunchError: true,
      );
    }
  }

  String _formatError(Object error) {
    final raw = error.toString();
    final clean = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Failure\([^)]*message:\s*'), '')
        .replaceFirst(RegExp(r'\)$'), '');
    return clean.isNotEmpty
        ? clean
        : 'Unable to load assessments. Please try again.';
  }
}

/// Global provider for [AssessmentsController].
final assessmentsControllerProvider =
    NotifierProvider<AssessmentsController, AssessmentsState>(
      AssessmentsController.new,
    );
