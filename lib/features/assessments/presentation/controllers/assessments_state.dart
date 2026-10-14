import '../../domain/entities/assessment_entity.dart';
import '../../domain/entities/assessment_question_entity.dart';

/// Sealed state hierarchy for Assessments screen.
sealed class AssessmentsState {
  const AssessmentsState();
}

/// Initial state before any request is triggered.
final class AssessmentsInitial extends AssessmentsState {
  const AssessmentsInitial();
}

/// Loading state while fetching assessments from the API.
final class AssessmentsLoading extends AssessmentsState {
  const AssessmentsLoading();
}

/// Loaded state with assessment data and operational tracking.
final class AssessmentsLoaded extends AssessmentsState {
  const AssessmentsLoaded({
    required this.assessments,
    this.activeChildId,
    this.isStudent = false,
    this.launchingAssessmentId,
    this.launchedRedirectUrl,
    this.launchSuccessMessage,
    this.launchError,
    this.loadingQuestionsAssessmentId,
    this.questionsMap = const {},
  });

  final List<AssessmentEntity> assessments;
  final String? activeChildId;
  final bool isStudent;

  /// ID of the assessment currently being launched via POST.
  final String? launchingAssessmentId;

  /// Redirect URL returned after a successful launch.
  final String? launchedRedirectUrl;

  /// Success message for feedback banner.
  final String? launchSuccessMessage;

  /// Transient launch error message.
  final String? launchError;

  /// Assessment ID currently fetching questions for.
  final String? loadingQuestionsAssessmentId;

  /// Cached questions mapped by assessmentId.
  final Map<String, List<AssessmentQuestionEntity>> questionsMap;

  bool get isEmpty => assessments.isEmpty;

  AssessmentsLoaded copyWith({
    List<AssessmentEntity>? assessments,
    String? activeChildId,
    bool? isStudent,
    String? launchingAssessmentId,
    bool clearLaunchingAssessmentId = false,
    String? launchedRedirectUrl,
    bool clearLaunchedRedirectUrl = false,
    String? launchSuccessMessage,
    bool clearLaunchSuccessMessage = false,
    String? launchError,
    bool clearLaunchError = false,
    String? loadingQuestionsAssessmentId,
    bool clearLoadingQuestionsAssessmentId = false,
    Map<String, List<AssessmentQuestionEntity>>? questionsMap,
  }) {
    return AssessmentsLoaded(
      assessments: assessments ?? this.assessments,
      activeChildId: activeChildId ?? this.activeChildId,
      isStudent: isStudent ?? this.isStudent,
      launchingAssessmentId: clearLaunchingAssessmentId
          ? null
          : (launchingAssessmentId ?? this.launchingAssessmentId),
      launchedRedirectUrl: clearLaunchedRedirectUrl
          ? null
          : (launchedRedirectUrl ?? this.launchedRedirectUrl),
      launchSuccessMessage: clearLaunchSuccessMessage
          ? null
          : (launchSuccessMessage ?? this.launchSuccessMessage),
      launchError: clearLaunchError ? null : (launchError ?? this.launchError),
      loadingQuestionsAssessmentId: clearLoadingQuestionsAssessmentId
          ? null
          : (loadingQuestionsAssessmentId ?? this.loadingQuestionsAssessmentId),
      questionsMap: questionsMap ?? this.questionsMap,
    );
  }
}

/// Error state when the API call fails.
final class AssessmentsError extends AssessmentsState {
  const AssessmentsError({required this.message, this.activeChildId});

  final String message;
  final String? activeChildId;
}
