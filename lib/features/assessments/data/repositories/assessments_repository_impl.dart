import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/assessment_attempt_details_entity.dart';
import '../../domain/entities/assessment_entity.dart';
import '../../domain/entities/assessment_question_entity.dart';
import '../../domain/entities/assessment_session_entity.dart';
import '../../domain/entities/assessment_submission_result_entity.dart';
import '../../domain/repositories/assessments_repository.dart';
import '../models/assessment_dto.dart';
import '../models/assessment_question_dto.dart';
import '../storage/assessment_proxy_storage.dart';

/// Concrete implementation of [AssessmentsRepository].
class AssessmentsRepositoryImpl implements AssessmentsRepository {
  const AssessmentsRepositoryImpl({
    required this.apiClient,
    this.storageService,
  });

  final ApiClient apiClient;
  final SecureStorageService? storageService;

  @override
  Future<List<AssessmentEntity>> getChildAssessments({
    required String studentId,
  }) async {
    final response = await apiClient.get<dynamic>(
      '/parent/children/$studentId/assessments',
    );

    return _parseAssessments(response.data);
  }

  @override
  Future<List<AssessmentEntity>> getStudentAssessments() async {
    final response = await apiClient.get<dynamic>('/assessments');
    return _parseAssessments(response.data);
  }

  @override
  Future<AssessmentSessionEntity> getAssessmentSession({
    required String studentId,
    required String assessmentId,
  }) async {
    final response = await apiClient.get<dynamic>(
      '/parent/children/$studentId/assessments/$assessmentId/session',
    );

    String? extractedProxyToken;
    final setCookieHeaders = response.headers['set-cookie'];
    if (setCookieHeaders != null) {
      for (final cookie in setCookieHeaders) {
        final match = RegExp(r'assessment_proxy_token=([^;]+)')
            .firstMatch(cookie);
        if (match != null) {
          extractedProxyToken = match.group(1);
          break;
        }
      }
    }

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        extractedProxyToken ??=
            (data['proxyToken'] ?? data['assessmentProxyToken'])?.toString();
        if (extractedProxyToken != null && extractedProxyToken.isNotEmpty) {
          await AssessmentProxyStorage.saveToken(extractedProxyToken);
        }

        final child = data['child'] is Map<String, dynamic>
            ? data['child'] as Map<String, dynamic>
            : null;
        final assessment = data['assessment'] is Map<String, dynamic>
            ? data['assessment'] as Map<String, dynamic>
            : null;

        return AssessmentSessionEntity(
          studentId: child?['id']?.toString() ?? studentId,
          studentName:
              child?['fullName']?.toString() ?? child?['firstName']?.toString(),
          studentCode: child?['studentCode']?.toString(),
          assessmentId: assessment?['id']?.toString() ?? assessmentId,
          assessmentTitle: assessment?['title']?.toString(),
          description: assessment?['description']?.toString(),
          durationMinutes: (assessment?['duration'] as num?)?.toInt(),
          maximumMarks: (assessment?['maximumMarks'] as num?)?.toInt(),
          passingMarks: (assessment?['passingMarks'] as num?)?.toInt(),
          proxyToken: extractedProxyToken,
        );
      }
    }

    return AssessmentSessionEntity(
      studentId: studentId,
      assessmentId: assessmentId,
      proxyToken: extractedProxyToken,
    );
  }

  @override
  Future<AssessmentAttemptDetailsEntity> prepareAssessmentAttempt({
    required String studentId,
    required String assessmentId,
    String? studentName,
  }) async {
    // 1. Retrieve authorized session and proxy token
    final session = await getAssessmentSession(
      studentId: studentId,
      assessmentId: assessmentId,
    );

    final proxyOptions = await _buildProxyOptions(session.proxyToken);

    // 2. Query assessment details and question set with child context
    final detailResponse = await apiClient.get<dynamic>(
      '/assessments/$assessmentId',
      queryParameters: {'childId': studentId},
      options: proxyOptions,
    );

    List<AssessmentQuestionEntity> parsedQuestions = [];
    int duration = session.durationMinutes ?? 30;
    int? maxMarks = session.maximumMarks;
    int? passMarks = session.passingMarks;
    String title = session.assessmentTitle ?? 'Assessment';
    String? description = session.description;
    String? instructions;
    Map<String, dynamic>? activeAttemptJson;

    final detailBody = detailResponse.data;
    if (detailBody is Map<String, dynamic>) {
      final data = detailBody['data'];
      if (data is Map<String, dynamic>) {
        title = data['title']?.toString() ?? title;
        description = data['description']?.toString() ?? description;
        instructions = data['instructions']?.toString();
        duration = (data['duration'] as num?)?.toInt() ?? duration;
        maxMarks = (data['maximumMarks'] as num?)?.toInt() ?? maxMarks;
        passMarks = (data['passingMarks'] as num?)?.toInt() ?? passMarks;

        if (data['questions'] is List) {
          parsedQuestions = (data['questions'] as List)
              .whereType<Map<String, dynamic>>()
              .map((json) => AssessmentQuestionDto.fromJson(json).toEntity())
              .toList();
        }

        if (data['activeAttempt'] is Map<String, dynamic>) {
          activeAttemptJson = data['activeAttempt'] as Map<String, dynamic>;
        }
      }
    }

    // Fallback: If questions list wasn't embedded in detail, fetch via dedicated endpoint
    if (parsedQuestions.isEmpty) {
      parsedQuestions = await getAssessmentQuestions(
        assessmentId: assessmentId,
      );
    }

    // 3. Handle attempt lifecycle: Resume existing active attempt or start a new one
    String realAttemptId;
    DateTime startedAt;
    final initialAnswers = <String, dynamic>{};
    bool isResumed = false;

    if (activeAttemptJson != null && activeAttemptJson['_id'] != null) {
      realAttemptId = activeAttemptJson['_id'].toString();
      startedAt =
          DateTime.tryParse(activeAttemptJson['startedAt']?.toString() ?? '') ??
          DateTime.now();
      isResumed = true;

      if (activeAttemptJson['answers'] is List) {
        for (final item in activeAttemptJson['answers']) {
          if (item is Map && item['questionId'] != null) {
            initialAnswers[item['questionId'].toString()] =
                item['answerValue'] ?? item['answer'];
          }
        }
      }
    } else {
      final startResponse = await apiClient.post<dynamic>(
        '/assessments/$assessmentId/start',
        data: {},
        options: proxyOptions,
      );

      final startBody = startResponse.data;
      if (startBody is Map<String, dynamic> &&
          startBody['data'] is Map<String, dynamic>) {
        final startData = startBody['data'] as Map<String, dynamic>;
        realAttemptId =
            (startData['_id'] ?? startData['attemptId'] ?? startData['id'])
                ?.toString() ??
            '';
        startedAt =
            DateTime.tryParse(startData['startedAt']?.toString() ?? '') ??
            DateTime.now();
      } else {
        throw Exception(
          'Failed to obtain attempt ID from assessment start endpoint.',
        );
      }
    }

    if (realAttemptId.isEmpty) {
      throw Exception(
        'Assessment attempt could not be initialized (missing attempt ID).',
      );
    }

    return AssessmentAttemptDetailsEntity(
      assessmentId: assessmentId,
      assessmentTitle: title,
      studentId: studentId,
      studentName: session.studentName ?? studentName ?? 'Student',
      attemptId: realAttemptId,
      startedAt: startedAt,
      questions: parsedQuestions,
      description: description,
      instructions: instructions,
      durationMinutes: duration,
      maximumMarks: maxMarks,
      passingMarks: passMarks,
      initialAnswers: initialAnswers,
      isResumed: isResumed,
    );
  }

  @override
  Future<String?> launchAssessment({
    required String studentId,
    required String assessmentId,
    String? notes,
  }) async {
    final payload = {
      'notes': (notes != null && notes.trim().isNotEmpty)
          ? notes.trim()
          : 'Authorized quiz launch from parent portal',
    };

    final response = await apiClient.post<dynamic>(
      '/parent/children/$studentId/assessments/$assessmentId/launch',
      data: payload,
    );

    final setCookieHeaders = response.headers['set-cookie'];
    if (setCookieHeaders != null) {
      for (final cookie in setCookieHeaders) {
        final match = RegExp(r'assessment_proxy_token=([^;]+)')
            .firstMatch(cookie);
        if (match != null) {
          final proxyToken = match.group(1);
          if (proxyToken != null && proxyToken.isNotEmpty) {
            await AssessmentProxyStorage.saveToken(proxyToken);
          }
          break;
        }
      }
    }

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data['redirectUrl']?.toString() ??
            '/student/assessments/$assessmentId';
      }
    }
    return '/student/assessments/$assessmentId';
  }

  @override
  Future<List<AssessmentQuestionEntity>> getAssessmentQuestions({
    required String assessmentId,
  }) async {
    final response = await apiClient.get<dynamic>(
      '/assessments/$assessmentId/questions',
    );

    final body = response.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => AssessmentQuestionDto.fromJson(json).toEntity())
          .toList();
    } else if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((json) => AssessmentQuestionDto.fromJson(json).toEntity())
          .toList();
    }

    return const [];
  }

  @override
  Future<bool> startAssessment({
    required String assessmentId,
    String? notes,
  }) async {
    final response = await apiClient.post<dynamic>(
      '/assessments/$assessmentId/start',
      data: {'status': 'active', 'notes': notes ?? 'Started via mobile app'},
    );

    final statusCode = response.statusCode ?? 200;
    return statusCode >= 200 && statusCode < 300;
  }

  @override
  Future<bool> submitAssessment({
    required String assessmentId,
    String? submissionNotes,
    String? fileUrl,
    List<Map<String, dynamic>>? answers,
    bool autoSubmitted = false,
  }) async {
    final data = <String, dynamic>{};
    if (answers != null && answers.isNotEmpty) {
      data['answers'] = answers;
      data['autoSubmitted'] = autoSubmitted;
    }
    if (submissionNotes != null && submissionNotes.isNotEmpty) {
      data['submissionNotes'] = submissionNotes;
    }
    if (fileUrl != null && fileUrl.isNotEmpty) {
      data['fileUrl'] = fileUrl;
    }

    final response = await apiClient.post<dynamic>(
      '/assessments/$assessmentId/submit',
      data: data,
    );

    final statusCode = response.statusCode ?? 200;
    return statusCode >= 200 && statusCode < 300;
  }

  @override
  Future<AssessmentSubmissionResultEntity> submitAssessmentAnswers({
    required String assessmentId,
    required String attemptId,
    required Map<String, dynamic> answers,
    bool autoSubmitted = false,
  }) async {
    final proxyOptions = await _buildProxyOptions(null);

    final answersPayload = answers.entries.map((entry) {
      return {'questionId': entry.key, 'answer': entry.value};
    }).toList();

    final response = await apiClient.post<dynamic>(
      '/assessments/$assessmentId/submit',
      data: {
        'attemptId': attemptId,
        'answers': answersPayload,
        'autoSubmitted': autoSubmitted,
      },
      options: proxyOptions,
    );

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        final scoreVal =
            (data['totalMarksObtained'] as num?)?.toInt() ??
            (data['score'] as num?)?.toInt();
        final maxMarksVal = (data['maximumMarks'] as num?)?.toInt();
        final passMarksVal = (data['passingMarks'] as num?)?.toInt();
        final percentageVal = (data['percentage'] as num?)?.toDouble();
        final statusVal = data['status']?.toString() ?? 'submitted';
        final isPassedVal = data['isPassed'] is bool
            ? data['isPassed'] as bool
            : null;
        final timeTakenVal = (data['timeTaken'] as num?)?.toInt();
        final submittedAtVal = DateTime.tryParse(
          data['submittedAt']?.toString() ?? '',
        );

        final isPending =
            statusVal.toLowerCase() == 'submitted' ||
            statusVal.toLowerCase() == 'pending_evaluation' ||
            statusVal.toLowerCase() == 'pending-review';

        return AssessmentSubmissionResultEntity(
          isSuccess: true,
          status: statusVal,
          attemptId: (data['_id'] ?? attemptId).toString(),
          score: scoreVal,
          totalMarksObtained: scoreVal,
          maximumMarks: maxMarksVal,
          passingMarks: passMarksVal,
          percentage: percentageVal,
          grade: data['grade']?.toString(),
          isPassed: isPassedVal,
          timeTakenSeconds: timeTakenVal,
          submittedAt: submittedAtVal,
          message: body['message']?.toString(),
          isPendingEvaluation: isPending,
        );
      }
    }

    return AssessmentSubmissionResultEntity(
      isSuccess: true,
      status: 'submitted',
      attemptId: attemptId,
      isPendingEvaluation: true,
      message: 'Assessment submitted successfully.',
    );
  }

  Future<Options?> _buildProxyOptions(String? proxyToken) async {
    final effectiveProxy =
        proxyToken ?? await AssessmentProxyStorage.getToken();
    final accessToken = await storageService?.getAccessToken();
    final cookies = <String>[];
    if (effectiveProxy != null && effectiveProxy.isNotEmpty) {
      cookies.add('assessment_proxy_token=$effectiveProxy');
    }
    if (accessToken != null && accessToken.isNotEmpty) {
      cookies.add('accessToken=$accessToken');
    }
    if (cookies.isEmpty) return null;
    return Options(headers: {'Cookie': cookies.join('; ')});
  }

  List<AssessmentEntity> _parseAssessments(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((json) => AssessmentDto.fromJson(json).toEntity())
            .toList();
      } else if (data is Map<String, dynamic>) {
        return [AssessmentDto.fromJson(data).toEntity()];
      }
    } else if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map((json) => AssessmentDto.fromJson(json).toEntity())
          .toList();
    }
    return const [];
  }
}

/// Provider for [AssessmentsRepository].
final assessmentsRepositoryProvider = Provider<AssessmentsRepository>((ref) {
  return AssessmentsRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    storageService: ref.watch(secureStorageProvider),
  );
});
