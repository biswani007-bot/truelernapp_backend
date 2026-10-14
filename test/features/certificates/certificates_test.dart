import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/certificates/data/models/certificate_dto.dart';
import 'package:truelearn/features/certificates/data/repositories/certificates_repository_impl.dart';
import 'package:truelearn/features/certificates/domain/entities/certificate_entity.dart';
import 'package:truelearn/features/certificates/domain/repositories/certificates_repository.dart';
import 'package:truelearn/features/certificates/presentation/controllers/certificates_controller.dart';
import 'package:truelearn/features/certificates/presentation/controllers/certificates_state.dart';
import 'package:truelearn/features/certificates/presentation/screens/certificates_screen.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class MockApiClient extends Fake implements ApiClient {
  dynamic responseData;
  bool shouldThrow = false;
  String? lastPath;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
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
      data: responseData as T?,
    );
  }
}

class MockCertificatesRepository implements CertificatesRepository {
  Map<String, List<CertificateEntity>> certificatesByChild = {};
  bool shouldThrow = false;
  String? lastQueriedChildId;

  @override
  Future<List<CertificateEntity>> getCertificates({
    required String childStudentId,
  }) async {
    lastQueriedChildId = childStudentId;
    if (shouldThrow) {
      throw Exception('Server error while loading certificates');
    }
    return certificatesByChild[childStudentId] ?? [];
  }
}

void main() {
  group('1. Certificate API Response Parsing', () {
    test('parses real backend certificate JSON structure correctly', () {
      final json = {
        'certificateId': '6a87011ffae35df7c876b0f9',
        'certificateNumber': 'CRT-000001',
        'issueDate': '2026-08-20T13:29:03.907Z',
        'status': 'issued',
        'downloadUrl': null,
      };

      final dto = CertificateDto.fromJson(json);
      expect(dto.certificateId, '6a87011ffae35df7c876b0f9');
      expect(dto.certificateNumber, 'CRT-000001');
      expect(dto.issueDate, DateTime.parse('2026-08-20T13:29:03.907Z'));
      expect(dto.status, 'issued');
      expect(dto.downloadUrl, isNull);

      final entity = dto.toEntity(childStudentId: 'alex_mercer');
      expect(entity.certificateId, '6a87011ffae35df7c876b0f9');
      expect(entity.certificateNumber, 'CRT-000001');
      expect(entity.statusLabel, 'ISSUED');
      expect(entity.displayTitle, 'Course Completion Certificate');
      expect(entity.hasDownloadUrl, isFalse);
      expect(entity.childStudentId, 'alex_mercer');
    });

    test('parses populated downloadUrl and custom title if provided', () {
      final json = {
        'certificateId': 'cert_123',
        'certificateNumber': 'CRT-999999',
        'title': 'Advanced Robotics Master',
        'programName': 'Senior Robotics',
        'issueDate': '2026-09-15T00:00:00.000Z',
        'status': 'issued',
        'downloadUrl': 'https://truelern.visital.in/certificates/cert_123.pdf',
      };

      final dto = CertificateDto.fromJson(json);
      final entity = dto.toEntity();
      expect(entity.displayTitle, 'Advanced Robotics Master');
      expect(entity.hasDownloadUrl, isTrue);
      expect(entity.downloadUrl, 'https://truelern.visital.in/certificates/cert_123.pdf');
    });

    test('handles fallback when fields are missing or null safely', () {
      final json = <String, dynamic>{};
      final dto = CertificateDto.fromJson(json);
      expect(dto.certificateId, '');
      expect(dto.certificateNumber, '');
      expect(dto.status, 'issued');
      expect(dto.downloadUrl, isNull);
    });
  });

  group('2. Certificate Repository', () {
    late MockApiClient mockApiClient;
    late CertificatesRepository repository;

    setUp(() {
      mockApiClient = MockApiClient();
      repository = CertificatesRepositoryImpl(apiClient: mockApiClient);
    });

    test('fetches certificates for child using the verified parent API path', () async {
      mockApiClient.responseData = {
        'success': true,
        'data': [
          {
            'certificateId': 'cert_abc',
            'certificateNumber': 'CRT-000042',
            'issueDate': '2026-10-01T12:00:00.000Z',
            'status': 'issued',
            'downloadUrl': null,
          }
        ]
      };

      final certificates = await repository.getCertificates(
        childStudentId: 'child_student_123',
      );

      expect(mockApiClient.lastPath, '/parent/children/child_student_123/certificates');
      expect(certificates.length, 1);
      expect(certificates.first.certificateNumber, 'CRT-000042');
      expect(certificates.first.childStudentId, 'child_student_123');
    });

    test('returns empty list when data is empty array', () async {
      mockApiClient.responseData = {
        'success': true,
        'data': [],
      };

      final certificates = await repository.getCertificates(
        childStudentId: 'child_empty',
      );

      expect(certificates, isEmpty);
    });

    test('throws exception when network fails', () async {
      mockApiClient.shouldThrow = true;

      expect(
        () => repository.getCertificates(childStudentId: 'child_err'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('3-7. Certificate Controller & State Transitions', () {
    late MockCertificatesRepository mockRepo;

    setUp(() {
      mockRepo = MockCertificatesRepository();
    });

    test('initial state is CertificatesInitial', () {
      final container = ProviderContainer(
        overrides: [
          certificatesRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(certificatesControllerProvider);
      expect(state, isA<CertificatesInitial>());
    });

    test('success state contains certificates', () async {
      mockRepo.certificatesByChild['child_1'] = [
        const CertificateEntity(
          certificateId: 'c1',
          certificateNumber: 'CRT-001',
          status: 'issued',
          childStudentId: 'child_1',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          certificatesRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(certificatesControllerProvider.notifier);
      await controller.loadCertificates(childStudentId: 'child_1');

      final state = container.read(certificatesControllerProvider);
      expect(state, isA<CertificatesLoaded>());
      final loaded = state as CertificatesLoaded;
      expect(loaded.certificates.length, 1);
      expect(loaded.certificates.first.certificateNumber, 'CRT-001');
      expect(loaded.activeChildId, 'child_1');
    });

    test('empty certificate state produces CertificatesLoaded with empty list', () async {
      mockRepo.certificatesByChild['child_empty'] = [];

      final container = ProviderContainer(
        overrides: [
          certificatesRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(certificatesControllerProvider.notifier);
      await controller.loadCertificates(childStudentId: 'child_empty');

      final state = container.read(certificatesControllerProvider);
      expect(state, isA<CertificatesLoaded>());
      final loaded = state as CertificatesLoaded;
      expect(loaded.certificates, isEmpty);
      expect(loaded.activeChildId, 'child_empty');
    });

    test('error state produces CertificatesError with message', () async {
      mockRepo.shouldThrow = true;

      final container = ProviderContainer(
        overrides: [
          certificatesRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(certificatesControllerProvider.notifier);
      await controller.loadCertificates(childStudentId: 'child_error');

      final state = container.read(certificatesControllerProvider);
      expect(state, isA<CertificatesError>());
      final err = state as CertificatesError;
      expect(err.message, contains('Unable to load certificates'));
      expect(err.activeChildId, 'child_error');
    });

    test('child switching loads different certificates per child', () async {
      mockRepo.certificatesByChild['child_sarah'] = [];
      mockRepo.certificatesByChild['child_alex'] = [
        const CertificateEntity(
          certificateId: 'cert_alex_1',
          certificateNumber: 'CRT-000001',
          status: 'issued',
          childStudentId: 'child_alex',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          certificatesRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(certificatesControllerProvider.notifier);

      // 1. Fetch for Sarah -> Empty
      await controller.loadCertificates(childStudentId: 'child_sarah');
      var state = container.read(certificatesControllerProvider) as CertificatesLoaded;
      expect(state.certificates, isEmpty);
      expect(state.activeChildId, 'child_sarah');

      // 2. Switch to Alex -> Loaded 1 certificate
      await controller.loadCertificates(childStudentId: 'child_alex');
      state = container.read(certificatesControllerProvider) as CertificatesLoaded;
      expect(state.certificates.length, 1);
      expect(state.certificates.first.certificateNumber, 'CRT-000001');
      expect(state.activeChildId, 'child_alex');
    });
  });

  group('8. Certificate Screen & Card Widget Rendering', () {
    const testChild = ChildEntity(
      studentId: 'child_1',
      firstName: 'Alex',
      lastName: 'Mercer',
      grade: 'Grade 5',
    );

    testWidgets('renders certificate card with certificate number and status badge', (tester) async {
      final mockRepo = MockCertificatesRepository();
      mockRepo.certificatesByChild['child_1'] = [
        CertificateEntity(
          certificateId: 'c_test_1',
          certificateNumber: 'CRT-000001',
          issueDate: DateTime(2026, 8, 20),
          status: 'issued',
          childStudentId: 'child_1',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            certificatesRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(() => MockChildrenController(
                  ChildrenLoaded(
                    children: const [testChild],
                    activeChildId: 'child_1',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: ParentCertificatesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Certificates'), findsOneWidget);
      expect(find.text('Official Credentials'), findsOneWidget);
      expect(find.text('CRT-000001'), findsOneWidget);
      expect(find.text('ISSUED'), findsOneWidget);
      expect(find.text('Course Completion Certificate'), findsOneWidget);
      expect(find.text('View Certificate Details'), findsOneWidget);
    });

    testWidgets('renders empty state when no certificates found for student', (tester) async {
      final mockRepo = MockCertificatesRepository();
      mockRepo.certificatesByChild['child_1'] = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            certificatesRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(() => MockChildrenController(
                  ChildrenLoaded(
                    children: const [testChild],
                    activeChildId: 'child_1',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: ParentCertificatesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('certificates_empty_state')), findsOneWidget);
      expect(find.text('No Certificates Yet'), findsOneWidget);
    });

    testWidgets('renders error card with retry button when failure occurs', (tester) async {
      final mockRepo = MockCertificatesRepository();
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            certificatesRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(() => MockChildrenController(
                  ChildrenLoaded(
                    children: const [testChild],
                    activeChildId: 'child_1',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: ParentCertificatesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('certificates_error_card')), findsOneWidget);
      expect(find.text('Unable to Load Certificates'), findsOneWidget);
      expect(find.byKey(const Key('certificates_retry_button')), findsOneWidget);
    });
  });
}

class MockChildrenController extends ChildrenController {
  MockChildrenController(this.initialState);
  final ChildrenState initialState;

  @override
  ChildrenState build() => initialState;
}
