import '../entities/assessment_attempt_details_entity.dart';
import '../entities/assessment_entity.dart';
import '../entities/assessment_question_entity.dart';
import '../entities/assessment_session_entity.dart';
import '../entities/assessment_submission_result_entity.dart';

/// Contract for assessment operations based on TrueLern API collection.
abstract interface class AssessmentsRepository {
  /// Fetches assessments for a linked child student (Parent role).
  ///
  /// Endpoint: GET /api/parent/children/:studentId/assessments
  Future<List<AssessmentEntity>> getChildAssessments({
    required String studentId,
  });

  /// Fetches assessments for the authenticated student (Student role).
  ///
  /// Endpoint: GET /api/assessments
  Future<List<AssessmentEntity>> getStudentAssessments();

  /// Retrieves a child's assessment launch session and stores proxy token (Parent role).
  ///
  /// Endpoint: GET /api/parent/children/:studentId/assessments/:assessmentId/session
  Future<AssessmentSessionEntity> getAssessmentSession({
    required String studentId,
    required String assessmentId,
  });

  /// Prepares a full native test attempt: obtains session, queries assessment
  /// details and questions, starts or resumes active attempt, and returns attempt details.
  Future<AssessmentAttemptDetailsEntity> prepareAssessmentAttempt({
    required String studentId,
    required String assessmentId,
    String? studentName,
  });

  /// Launches a child's assessment proxy session (Parent role).
  ///
  /// Endpoint: POST /api/parent/children/:studentId/assessments/:assessmentId/launch
  /// Returns the redirectUrl (e.g. "/student/assessments/:assessmentId") on success.
  Future<String?> launchAssessment({
    required String studentId,
    required String assessmentId,
    String? notes,
  });

  /// Fetches questions for an assessment.
  ///
  /// Endpoint: GET /api/assessments/:assessmentId/questions
  /// Supported for: ADMIN, TEACHER, PARENT, STUDENT
  Future<List<AssessmentQuestionEntity>> getAssessmentQuestions({
    required String assessmentId,
  });

  /// Starts an assessment attempt (Student role).
  ///
  /// Endpoint: POST /api/assessments/:assessmentId/start
  Future<bool> startAssessment({required String assessmentId, String? notes});

  /// Submits an assessment attempt (Student role).
  ///
  /// Endpoint: POST /api/assessments/:assessmentId/submit
  Future<bool> submitAssessment({
    required String assessmentId,
    String? submissionNotes,
    String? fileUrl,
    List<Map<String, dynamic>>? answers,
    bool autoSubmitted = false,
  });

  /// Submits completed assessment answers via the documented native payload.
  ///
  /// Endpoint: POST /api/assessments/:assessmentId/submit
  Future<AssessmentSubmissionResultEntity> submitAssessmentAnswers({
    required String assessmentId,
    required String attemptId,
    required Map<String, dynamic> answers,
    bool autoSubmitted = false,
  });
}
