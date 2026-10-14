import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/assessments/data/models/assessment_dto.dart';
import 'package:truelearn/features/assessments/data/models/assessment_question_dto.dart';
import 'package:truelearn/features/assessments/data/repositories/assessments_repository_impl.dart';
import 'package:truelearn/features/assessments/domain/entities/assessment_attempt_details_entity.dart';
import 'package:truelearn/features/assessments/domain/entities/assessment_entity.dart';
import 'package:truelearn/features/assessments/domain/entities/assessment_question_entity.dart';
import 'package:truelearn/features/assessments/domain/entities/assessment_session_entity.dart';
import 'package:truelearn/features/assessments/domain/entities/assessment_submission_result_entity.dart';
import 'package:truelearn/features/assessments/domain/repositories/assessments_repository.dart';
import 'package:truelearn/features/assessments/presentation/screens/assessment_runner_screen.dart';
import 'package:truelearn/features/assessments/presentation/screens/parent_assessments_screen.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class MockApiClient extends Fake implements ApiClient {
  dynamic responseData;
  Map<String, List<String>>? responseHeaders;
  bool shouldThrow = false;
  String? lastPath;
  dynamic lastData;
  Options? lastOptions;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
    lastOptions = options;
    if (shouldThrow) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network connection failed',
        type: DioExceptionType.connectionError,
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      headers: Headers.fromMap(responseHeaders ?? {}),
      data: responseData as T?,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
    lastData = data;
    lastOptions = options;
    if (shouldThrow) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Server error',
        type: DioExceptionType.badResponse,
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      headers: Headers.fromMap(responseHeaders ?? {}),
      data: responseData as T?,
    );
  }
}

class MockAssessmentsRepository implements AssessmentsRepository {
  List<AssessmentEntity> assessmentsToReturn = [];
  List<AssessmentQuestionEntity> questionsToReturn = [];
  bool shouldThrow = false;
  String? lastStudentId;
  String? lastAssessmentId;
  String? redirectUrlToReturn = '/student/assessments/test_123';
  AssessmentSessionEntity? sessionToReturn;
  AssessmentAttemptDetailsEntity? attemptDetailsToReturn;
  AssessmentSubmissionResultEntity? submissionResultToReturn;

  @override
  Future<List<AssessmentEntity>> getChildAssessments({
    required String studentId,
  }) async {
    lastStudentId = studentId;
    if (shouldThrow) throw Exception('API Error fetching child assessments');
    return assessmentsToReturn;
  }

  @override
  Future<List<AssessmentEntity>> getStudentAssessments() async {
    if (shouldThrow) throw Exception('API Error fetching student assessments');
    return assessmentsToReturn;
  }

  @override
  Future<AssessmentSessionEntity> getAssessmentSession({
    required String studentId,
    required String assessmentId,
  }) async {
    lastStudentId = studentId;
    lastAssessmentId = assessmentId;
    if (shouldThrow) throw Exception('API Error fetching assessment session');
    return sessionToReturn ??
        AssessmentSessionEntity(
          proxyToken: 'dummy_proxy_token',
          studentId: studentId,
          assessmentId: assessmentId,
        );
  }

  @override
  Future<AssessmentAttemptDetailsEntity> prepareAssessmentAttempt({
    required String studentId,
    required String assessmentId,
    String? studentName,
  }) async {
    lastStudentId = studentId;
    lastAssessmentId = assessmentId;
    if (shouldThrow) throw Exception('API Error preparing assessment attempt');
    return attemptDetailsToReturn ??
        AssessmentAttemptDetailsEntity(
          assessmentId: assessmentId,
          assessmentTitle: 'Robotics Midterm Test',
          attemptId: 'attempt_mock_123',
          studentId: studentId,
          studentName: studentName ?? 'Student User',
          startedAt: DateTime.now(),
          durationMinutes: 30,
          maximumMarks: 100,
          passingMarks: 40,
          questions: questionsToReturn,
        );
  }

  @override
  Future<String?> launchAssessment({
    required String studentId,
    required String assessmentId,
    String? notes,
  }) async {
    lastStudentId = studentId;
    lastAssessmentId = assessmentId;
    if (shouldThrow) throw Exception('API Error launching assessment');
    return redirectUrlToReturn;
  }

  @override
  Future<List<AssessmentQuestionEntity>> getAssessmentQuestions({
    required String assessmentId,
  }) async {
    lastAssessmentId = assessmentId;
    if (shouldThrow) throw Exception('API Error fetching questions');
    return questionsToReturn;
  }

  @override
  Future<bool> startAssessment({
    required String assessmentId,
    String? notes,
  }) async {
    if (shouldThrow) throw Exception('API Error starting assessment');
    return true;
  }

  @override
  Future<bool> submitAssessment({
    required String assessmentId,
    String? submissionNotes,
    String? fileUrl,
    List<Map<String, dynamic>>? answers,
    bool autoSubmitted = false,
  }) async {
    if (shouldThrow) throw Exception('API Error submitting assessment');
    return true;
  }

  @override
  Future<AssessmentSubmissionResultEntity> submitAssessmentAnswers({
    required String assessmentId,
    required String attemptId,
    required Map<String, dynamic> answers,
    bool autoSubmitted = false,
  }) async {
    if (shouldThrow) throw Exception('API Error submitting assessment answers');
    return submissionResultToReturn ??
        AssessmentSubmissionResultEntity(
          isSuccess: true,
          attemptId: attemptId,
          status: 'pass',
          score: 85,
          totalMarksObtained: 85,
          maximumMarks: 100,
          percentage: 85.0,
          grade: 'A',
          isPassed: true,
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Assessment DTO Defensive Parsing Tests', () {
    test('parses live backend response format accurately', () {
      final json = {
        'id': 'pending_6ac9f83db2191b5d3a4d3d8e',
        'assessmentId': '6ac9f83db2191b5d3a4d3d8e',
        'title': 'Future ',
        'description': 'Surprise test',
        'type': 'quiz',
        'maximumMarks': 100,
        'passingMarks': 40,
        'duration': 60,
        'status': 'pending',
        'isPassed': false,
      };

      final dto = AssessmentDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.id, 'pending_6ac9f83db2191b5d3a4d3d8e');
      expect(entity.assessmentId, '6ac9f83db2191b5d3a4d3d8e');
      expect(entity.title, 'Future');
      expect(entity.description, 'Surprise test');
      expect(entity.type, 'quiz');
      expect(entity.displayType, 'Quiz');
      expect(entity.maximumMarks, 100);
      expect(entity.passingMarks, 40);
      expect(entity.durationMinutes, 60);
      expect(entity.status, 'pending');
      expect(entity.isPassed, false);
      expect(entity.isPending, true);
    });

    test('parses fallback fields gracefully', () {
      final json = {
        '_id': 'asm_alt_123',
        'title': 'Midterm Robotics',
        'notes': 'End of term test',
        'totalMarks': 50,
        'passingMarks': 25,
        'durationMinutes': 45,
        'status': 'ACTIVE',
        'marksObtained': 45,
        'isPassed': 'true',
      };

      final dto = AssessmentDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.assessmentId, 'asm_alt_123');
      expect(entity.maximumMarks, 50);
      expect(entity.passingMarks, 25);
      expect(entity.durationMinutes, 45);
      expect(entity.status, 'active');
      expect(entity.score, 45);
      expect(entity.isPassed, true);
      expect(entity.isActive, true);
    });

    test('parses question bank payload with MCQ options defensively', () {
      final json = {
        '_id': 'q_link_1',
        'assessment': 'asm_1',
        'questionBank': {
          '_id': 'qb_1',
          'questionCode': 'QB-001',
          'questionText': 'What is Robotics?',
          'category': 'Robotics',
          'difficultyLevel': 'medium',
          'marks': 5,
          'type': 'MCQ',
          'options': ['Branch of tech', 'Fiction only'],
          'correctAnswer': 'Branch of tech',
        },
        'marksOverride': 10,
        'displayOrder': 1,
      };

      final dto = AssessmentQuestionDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.id, 'q_link_1');
      expect(entity.assessmentId, 'asm_1');
      expect(entity.questionText, 'What is Robotics?');
      expect(entity.questionCode, 'QB-001');
      expect(entity.category, 'Robotics');
      expect(entity.difficultyLevel, 'medium');
      expect(entity.marks, 10); // marksOverride takes precedence
      expect(entity.options.length, 2);
      expect(entity.options.first, 'Branch of tech');
      expect(entity.displayOrder, 1);
    });

    test('parses evaluated passed assessment payload accurately (test234 / testing 123)', () {
      final json = {
        'id': '6acccb0d633ddd744f43b38c',
        'assessmentId': '6accca8d02ac1efa57e4fa54',
        'title': 'test234',
        'description': 'test234',
        'type': 'quiz',
        'maximumMarks': 10,
        'passingMarks': 4,
        'duration': 60,
        'status': 'pass',
        'submittedAt': '2026-10-12T11:57:00.218Z',
        'startedAt': '2026-10-12T11:56:49.239Z',
        'scoreObtained': 5,
        'percentage': 50,
        'isPassed': true,
        'feedback': 'F',
        'evaluatedAt': '2026-10-12T11:57:01.188Z',
      };

      final dto = AssessmentDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.id, '6acccb0d633ddd744f43b38c');
      expect(entity.assessmentId, '6accca8d02ac1efa57e4fa54');
      expect(entity.title, 'test234');
      expect(entity.status, 'pass');
      expect(entity.isPassed, true);
      expect(entity.score, 5);
      expect(entity.percentage, 50.0);
      expect(entity.evaluatedAt, isNotNull);
      expect(entity.isEvaluated, isTrue);
      expect(entity.isPassedSuccessfully, isTrue);
      expect(entity.needsRetake, isFalse);
      expect(entity.canLaunch, isFalse);
    });

    test(
      'parses evaluated needs retake payload accurately (testing you / Future)',
      () {
        final json = {
          'id': '6accaf04633ddd744f43b1c5',
          'assessmentId': '6acc8aa7af81078972ce0b99',
          'title': 'testing you',
          'description': 'testing you',
          'type': 'module-test',
          'maximumMarks': 100,
          'passingMarks': 40,
          'duration': 60,
          'status': 'fail',
          'submittedAt': '2026-10-12T09:57:24.734Z',
          'startedAt': '2026-10-12T09:53:15.292Z',
          'scoreObtained': 15,
          'percentage': 15,
          'isPassed': false,
          'feedback': 'F',
          'evaluatedAt': '2026-10-12T09:57:24.949Z',
        };

        final dto = AssessmentDto.fromJson(json);
        final entity = dto.toEntity();

        expect(entity.title, 'testing you');
        expect(entity.displayType, 'Module Test');
        expect(entity.status, 'fail');
        expect(entity.isPassed, false);
        expect(entity.score, 15);
        expect(entity.percentage, 15.0);
        expect(entity.isEvaluated, isTrue);
        expect(entity.isPassedSuccessfully, isFalse);
        expect(entity.needsRetake, isTrue);
        expect(entity.canLaunch, isFalse);
      },
    );

    test(
      'parses submitted pending evaluation assessment payload accurately',
      () {
        final json = {
          'id': 'sub_123',
          'assessmentId': 'asm_sub_1',
          'title': 'Science Test',
          'status': 'submitted',
          'submittedAt': '2026-10-12T08:00:00.000Z',
          'maximumMarks': 50,
        };

        final dto = AssessmentDto.fromJson(json);
        final entity = dto.toEntity();

        expect(entity.isEvaluated, isFalse);
        expect(entity.isSubmittedPendingEvaluation, isTrue);
        expect(entity.canLaunch, isFalse);
      },
    );
  });

  group('AssessmentsRepositoryImpl Tests', () {
    late MockApiClient mockApiClient;
    late AssessmentsRepository repository;

    setUp(() {
      mockApiClient = MockApiClient();
      repository = AssessmentsRepositoryImpl(apiClient: mockApiClient);
    });

    test(
      'getChildAssessments calls GET /parent/children/:studentId/assessments',
      () async {
        mockApiClient.responseData = {
          'success': true,
          'message': 'Child assessments retrieved successfully',
          'data': [
            {
              'id': 'pending_1',
              'assessmentId': 'asm_1',
              'title': 'AI Quiz',
              'status': 'pending',
            },
          ],
        };

        final list = await repository.getChildAssessments(studentId: 'stu_123');

        expect(mockApiClient.lastPath, '/parent/children/stu_123/assessments');
        expect(list.length, 1);
        expect(list.first.title, 'AI Quiz');
      },
    );

    test('launchAssessment calls POST /parent/children/:studentId/assessments/:assessmentId/launch', () async {
      mockApiClient.responseData = {
        'success': true,
        'message': 'Assessment proxy session created',
        'data': {'redirectUrl': '/student/assessments/asm_99'},
      };

      final redirectUrl = await repository.launchAssessment(
        studentId: 'stu_1',
        assessmentId: 'asm_99',
        notes: 'Parent authorization',
      );

      expect(
        mockApiClient.lastPath,
        '/parent/children/stu_1/assessments/asm_99/launch',
      );
      expect(mockApiClient.lastData, {'notes': 'Parent authorization'});
      expect(redirectUrl, '/student/assessments/asm_99');
    });

    test(
      'getAssessmentQuestions calls GET /assessments/:assessmentId/questions',
      () async {
        mockApiClient.responseData = {
          'success': true,
          'data': [
            {
              '_id': 'q_1',
              'assessment': 'asm_1',
              'questionBank': {'questionText': 'Explain AI', 'marks': 5},
            },
          ],
        };

        final questions = await repository.getAssessmentQuestions(
          assessmentId: 'asm_1',
        );

        expect(mockApiClient.lastPath, '/assessments/asm_1/questions');
        expect(questions.length, 1);
        expect(questions.first.questionText, 'Explain AI');
      },
    );

    test('getAssessmentSession calls GET /parent/children/:studentId/assessments/:assessmentId/session and extracts proxyToken', () async {
      mockApiClient.responseHeaders = {
        'set-cookie': [
          'assessment_proxy_token=cookie_jwt_abc; Path=/; HttpOnly',
        ],
      };
      mockApiClient.responseData = {
        'success': true,
        'data': {
          'child': {'id': 'stu_123', 'fullName': 'Rony Roul'},
          'assessment': {'id': 'asm_101', 'title': 'Robotics', 'duration': 45},
          'proxyToken': 'body_jwt_abc',
        },
      };

      final session = await repository.getAssessmentSession(
        studentId: 'stu_123',
        assessmentId: 'asm_101',
      );

      expect(
        mockApiClient.lastPath,
        '/parent/children/stu_123/assessments/asm_101/session',
      );
      expect(session.studentId, 'stu_123');
      expect(session.assessmentId, 'asm_101');
      expect(session.proxyToken, 'cookie_jwt_abc');
      expect(session.durationMinutes, 45);
    });

    test('submitAssessmentAnswers calls POST /assessments/:assessmentId/submit with transformed answers', () async {
      mockApiClient.responseData = {
        'success': true,
        'data': {
          '_id': 'att_999',
          'status': 'pass',
          'score': 90,
          'maximumMarks': 100,
          'percentage': 90.0,
          'grade': 'A+',
          'isPassed': true,
        },
      };

      final result = await repository.submitAssessmentAnswers(
        assessmentId: 'asm_101',
        attemptId: 'att_999',
        answers: {'q_1': 'Option A', 'q_2': 'True'},
      );

      expect(mockApiClient.lastPath, '/assessments/asm_101/submit');
      final data = mockApiClient.lastData as Map<String, dynamic>;
      expect(data['attemptId'], 'att_999');
      final answersList = data['answers'] as List;
      expect(answersList.length, 2);
      expect(result.isSuccess, true);
      expect(result.status, 'pass');
      expect(result.score, 90);
      expect(result.grade, 'A+');
      expect(result.isPassedSuccessfully, true);
    });
  });

  group('Assessments UI & Screen Integration Tests', () {
    late MockAssessmentsRepository mockRepo;

    final testAssessment = AssessmentEntity(
      id: 'pending_1',
      assessmentId: 'asm_101',
      title: 'Robotics Midterm Test',
      description: 'Comprehensive evaluation of robotics modules.',
      type: 'quiz',
      maximumMarks: 100,
      passingMarks: 40,
      durationMinutes: 60,
      status: 'pending',
      isPassed: false,
    );

    final testQuestion = AssessmentQuestionEntity(
      id: 'q_101',
      assessmentId: 'asm_101',
      questionText: 'What is a servo motor?',
      category: 'Hardware',
      difficultyLevel: 'medium',
      marks: 5,
      type: 'MCQ',
      options: const ['Rotary actuator', 'Display device'],
    );

    final testChild = ChildEntity(
      studentId: 'stu_001',
      firstName: 'Rony',
      lastName: 'Roul',
    );

    setUp(() {
      mockRepo = MockAssessmentsRepository();
      mockRepo.assessmentsToReturn = [testAssessment];
      mockRepo.questionsToReturn = [testQuestion];
    });

    Widget createTestWidget() {
      final router = GoRouter(
        initialLocation: AppRoutePaths.assessments,
        routes: [
          GoRoute(
            path: AppRoutePaths.assessments,
            builder: (context, state) => const ParentAssessmentsScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.assessmentRunner,
            builder: (context, state) {
              if (state.extra is AssessmentAttemptDetailsEntity) {
                return AssessmentRunnerScreen(
                  attemptDetails: state.extra as AssessmentAttemptDetailsEntity,
                );
              }
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AssessmentRunnerScreen(
                attemptDetails:
                    extra['attemptDetails'] as AssessmentAttemptDetailsEntity?,
                assessmentId: extra['assessmentId'] as String? ?? '',
                assessmentTitle: extra['assessmentTitle'] as String?,
                studentId: extra['studentId'] as String?,
                studentName: extra['studentName'] as String?,
                redirectUrl: extra['redirectUrl'] as String?,
              );
            },
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          assessmentsRepositoryProvider.overrideWithValue(mockRepo),
          childrenControllerProvider.overrideWith(
            () => _MockChildrenController(testChild),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      'renders loaded assessment cards with title, duration, marks, and full-width launch button (no Questions button)',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Assessments'), findsOneWidget);
        expect(find.text('Robotics Midterm Test'), findsOneWidget);
        expect(
          find.text('Comprehensive evaluation of robotics modules.'),
          findsOneWidget,
        );
        expect(find.text('QUIZ'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('60 mins'), findsOneWidget);
        expect(find.text('Max: 100 pts'), findsOneWidget);
        expect(find.text('Pass: 40 pts'), findsOneWidget);

        // Verify Launch button is present and Questions button is completely removed
        expect(find.byKey(const Key('btn_launch_asm_101')), findsOneWidget);
        expect(
          find.byKey(const Key('btn_view_questions_asm_101')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'tapping Launch Assessment prepares attempt and opens native AssessmentRunnerScreen without webview or external browser',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('btn_launch_asm_101')), findsOneWidget);
        await tester.tap(find.byKey(const Key('btn_launch_asm_101')));
        await tester.pumpAndSettle();

        // Verifies native test runner screen is displayed inside Flutter app
        expect(find.byType(AssessmentRunnerScreen), findsOneWidget);
        expect(find.text('Robotics Midterm Test'), findsWidgets);
        expect(find.text('Candidate: Rony Roul'), findsOneWidget);
        expect(find.text('What is a servo motor?'), findsOneWidget);
        expect(find.text('Rotary actuator'), findsOneWidget);
        expect(find.text('Display device'), findsOneWidget);
        expect(find.byKey(const Key('btn_submit_exam')), findsOneWidget);
      },
    );

    testWidgets(
      'AssessmentRunnerScreen supports answering questions, confirmation modal, submission, and result display',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap launch
        await tester.tap(find.byKey(const Key('btn_launch_asm_101')));
        await tester.pumpAndSettle();

        // Select an answer
        await tester.tap(find.text('Rotary actuator'));
        await tester.pumpAndSettle();

        // Tap Submit Exam button in header
        await tester.tap(find.byKey(const Key('btn_header_submit')));
        await tester.pumpAndSettle();

        // Confirmation modal shows
        expect(find.text('Submit Assessment?'), findsOneWidget);
        expect(find.text('1 of 1'), findsOneWidget);
        expect(find.byKey(const Key('btn_confirm_submit')), findsOneWidget);

        // Confirm submission
        await tester.tap(find.byKey(const Key('btn_confirm_submit')));
        await tester.pumpAndSettle();

        // Result screen is displayed
        expect(find.text('Assessment Completed!'), findsOneWidget);
        expect(find.text('Score'), findsOneWidget);
        expect(find.text('85/100'), findsOneWidget);
        expect(
          find.byKey(const Key('btn_done_return_assessments')),
          findsOneWidget,
        );

        // Return to assessments
        await tester.tap(find.byKey(const Key('btn_done_return_assessments')));
        await tester.pumpAndSettle();

        // Back on assessments list
        expect(find.byType(ParentAssessmentsScreen), findsOneWidget);
      },
    );

    testWidgets(
      'AssessmentRunnerScreen back button prompts user with leave exam confirmation',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap launch
        await tester.tap(find.byKey(const Key('btn_launch_asm_101')));
        await tester.pumpAndSettle();

        // Tap back button
        await tester.tap(find.byKey(const Key('btn_back_assessment_runner')));
        await tester.pumpAndSettle();

        // Expect leave dialog
        expect(find.text('Leave Exam Attempt?'), findsOneWidget);
        expect(find.text('Stay in Exam'), findsOneWidget);
        expect(find.text('Exit Exam'), findsOneWidget);

        // Tap Stay in Exam
        await tester.tap(find.text('Stay in Exam'));
        await tester.pumpAndSettle();

        // Still in runner
        expect(find.byType(AssessmentRunnerScreen), findsOneWidget);
      },
    );

    testWidgets('renders empty state when no assessments exist', (
      tester,
    ) async {
      mockRepo.assessmentsToReturn = [];

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Assessments Scheduled'), findsOneWidget);
      expect(
        find.textContaining(
          'There are currently no active or pending assessments',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders error state and retries on tap', (tester) async {
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Could Not Load Assessments'), findsOneWidget);
      expect(find.byKey(const Key('assessments_retry_button')), findsOneWidget);

      mockRepo.shouldThrow = false;
      mockRepo.assessmentsToReturn = [testAssessment];

      await tester.tap(find.byKey(const Key('assessments_retry_button')));
      await tester.pumpAndSettle();

      expect(find.text('Robotics Midterm Test'), findsOneWidget);
    });

    testWidgets(
      'renders evaluated assessments with Passed / Needs Retake badges, scores, grade %, and NO launch button',
      (tester) async {
        final passedAssessment = AssessmentEntity(
          id: 'eval_pass_1',
          assessmentId: 'asm_pass_1',
          title: 'test234',
          type: 'quiz',
          maximumMarks: 10,
          passingMarks: 4,
          durationMinutes: 60,
          status: 'pass',
          isPassed: true,
          score: 5,
          percentage: 50.0,
          evaluatedAt: DateTime.parse('2026-10-12T11:57:01.188Z'),
        );

        final failedAssessment = AssessmentEntity(
          id: 'eval_fail_1',
          assessmentId: 'asm_fail_1',
          title: 'testing you',
          type: 'module-test',
          maximumMarks: 100,
          passingMarks: 40,
          durationMinutes: 60,
          status: 'fail',
          isPassed: false,
          score: 15,
          percentage: 15.0,
          evaluatedAt: DateTime.parse('2026-10-12T09:57:24.949Z'),
        );

        mockRepo.assessmentsToReturn = [passedAssessment, failedAssessment];

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 1. Verify passed card
        expect(find.text('test234'), findsOneWidget);
        expect(find.text('Passed'), findsOneWidget);
        expect(find.text('Score: 5/10'), findsOneWidget);
        expect(find.text('50% Grade'), findsOneWidget);
        expect(
          find.byKey(const Key('evaluated_banner_asm_pass_1')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('btn_launch_asm_pass_1')), findsNothing);

        // 2. Verify failed / needs retake card
        expect(find.text('testing you'), findsOneWidget);
        expect(find.text('Needs Retake'), findsOneWidget);
        expect(find.text('Score: 15/100'), findsOneWidget);
        expect(find.text('15% Grade'), findsOneWidget);
        expect(
          find.byKey(const Key('evaluated_banner_asm_fail_1')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('btn_launch_asm_fail_1')), findsNothing);

        // 3. Header shows Evaluated Results (2)
        expect(find.text('Evaluated Results (2)'), findsOneWidget);
      },
    );

    testWidgets(
      'renders grouped sections when both pending and evaluated assessments exist',
      (tester) async {
        final pendingAssessment = testAssessment; // asm_101
        final evaluatedAssessment = AssessmentEntity(
          id: 'eval_1',
          assessmentId: 'asm_eval_1',
          title: 'Future',
          status: 'pass',
          isPassed: true,
          score: 80,
          maximumMarks: 100,
          percentage: 80.0,
          evaluatedAt: DateTime.parse('2026-10-12T10:00:00.000Z'),
        );

        mockRepo.assessmentsToReturn = [pendingAssessment, evaluatedAssessment];

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Pending Assessments (1)'), findsOneWidget);
        expect(find.text('Evaluated Results (1)'), findsOneWidget);
        expect(find.byKey(const Key('btn_launch_asm_101')), findsOneWidget);
        expect(find.byKey(const Key('btn_launch_asm_eval_1')), findsNothing);
      },
    );
  });
}

class _MockChildrenController extends ChildrenController {
  _MockChildrenController(this.child);
  final ChildEntity child;

  @override
  ChildrenState build() {
    return ChildrenLoaded(children: [child], activeChildId: child.studentId);
  }
}
