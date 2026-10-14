import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/dashboard/data/models/login_methods_dto.dart';
import 'package:truelearn/features/dashboard/data/repositories/login_methods_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/login_methods_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/login_methods_repository.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/login_methods_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/login_methods_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_login_methods_screen.dart';

class FakeApiClient extends Fake implements ApiClient {
  dynamic profileResponseData;
  dynamic prefResponseData;
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
        error: 'Network connection error',
        type: DioExceptionType.connectionError,
      );
    }
    if (path == '/parent/preferences') {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: prefResponseData as T?,
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: profileResponseData as T?,
    );
  }
}

class FakeLoginMethodsRepository extends Fake
    implements LoginMethodsRepository {
  LoginMethodsEntity? methodsToReturn;
  bool shouldThrow = false;

  @override
  Future<LoginMethodsEntity> getLoginMethods() async {
    if (shouldThrow) {
      throw Exception('Server unreachable');
    }
    return methodsToReturn ??
        const LoginMethodsEntity(
          email: 'default@truelern.com',
          phone: '+1 555-0123',
          hasPassword: true,
          isSecurityActive: true,
        );
  }
}

void main() {
  group('Login Methods DTO & Entity tests', () {
    test('LoginMethodsDto correctly parses profile and security json', () {
      final json = {
        'profile': {
          'id': 'p1',
          'firstName': 'Brock',
          'lastName': 'Mercer',
          'email': 'parent@truelern.com',
          'phone': '+1-582482368',
        },
        'security': {
          'email': 'parent@truelern.com',
          'hasPassword': true,
          'isActive': true,
        },
      };

      final prefJson = {
        'channelPreferences': {
          'whatsapp': true,
          'email': true,
        },
      };

      final dto = LoginMethodsDto.fromProfileJson(json, prefJson: prefJson);
      expect(dto.email, 'parent@truelern.com');
      expect(dto.phone, '+1-582482368');
      expect(dto.hasPassword, true);
      expect(dto.isSecurityActive, true);
      expect(dto.isWhatsAppPreferred, true);
      expect(dto.isEmailPreferred, true);

      final entity = dto.toEntity();
      expect(entity.email, 'parent@truelern.com');
      expect(entity.phone, '+1-582482368');
    });

    test('LoginMethodsDto handles empty/missing fields gracefully', () {
      final json = <String, dynamic>{};
      final dto = LoginMethodsDto.fromProfileJson(json);
      expect(dto.email, '');
      expect(dto.phone, '');
      expect(dto.hasPassword, true);
      expect(dto.isSecurityActive, true);
    });
  });

  group('LoginMethodsRepositoryImpl tests', () {
    late FakeApiClient fakeApiClient;
    late LoginMethodsRepositoryImpl repository;

    setUp(() {
      fakeApiClient = FakeApiClient();
      repository = LoginMethodsRepositoryImpl(apiClient: fakeApiClient);
    });

    test('getLoginMethods calls /parent/profile and returns LoginMethodsEntity',
        () async {
      fakeApiClient.profileResponseData = {
        'success': true,
        'data': {
          'profile': {
            'email': 'parent@truelern.com',
            'phone': '+1-582482368',
          },
          'security': {
            'email': 'parent@truelern.com',
            'hasPassword': true,
            'isActive': true,
          },
        },
      };

      fakeApiClient.prefResponseData = {
        'success': true,
        'data': {
          'channelPreferences': {
            'whatsapp': true,
            'email': true,
          },
        },
      };

      final result = await repository.getLoginMethods();
      expect(result.email, 'parent@truelern.com');
      expect(result.phone, '+1-582482368');
    });
  });

  group('LoginMethodsController tests', () {
    late FakeLoginMethodsRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeLoginMethodsRepository();
    });

    test('loadLoginMethods transitions from loading to loaded', () async {
      fakeRepo.methodsToReturn = const LoginMethodsEntity(
        email: 'parent@truelern.com',
        phone: '+1-582482368',
        hasPassword: true,
        isSecurityActive: true,
      );

      final container = ProviderContainer(
        overrides: [
          loginMethodsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(loginMethodsControllerProvider),
          isA<LoginMethodsInitial>());

      await container
          .read(loginMethodsControllerProvider.notifier)
          .loadLoginMethods();

      final state = container.read(loginMethodsControllerProvider);
      expect(state, isA<LoginMethodsLoaded>());
      final loaded = state as LoginMethodsLoaded;
      expect(loaded.methods.email, 'parent@truelern.com');
      expect(loaded.methods.phone, '+1-582482368');
    });

    test('loadLoginMethods transitions to error state on failure', () async {
      fakeRepo.shouldThrow = true;

      final container = ProviderContainer(
        overrides: [
          loginMethodsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(loginMethodsControllerProvider.notifier)
          .loadLoginMethods();

      final state = container.read(loginMethodsControllerProvider);
      expect(state, isA<LoginMethodsError>());
      final err = state as LoginMethodsError;
      expect(err.message, contains('Server unreachable'));
    });
  });

  group('ParentLoginMethodsScreen Widget tests', () {
    late FakeLoginMethodsRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeLoginMethodsRepository();
    });

    testWidgets(
        'renders Login Methods screen and displays real email and phone',
        (tester) async {
      fakeRepo.methodsToReturn = const LoginMethodsEntity(
        email: 'brock.mercer@truelern.com',
        phone: '+1-582482368',
        hasPassword: true,
        isSecurityActive: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginMethodsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: ParentLoginMethodsScreen(),
          ),
        ),
      );

      // Trigger post frame callback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Login Methods'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('+1-582482368'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('brock.mercer@truelern.com'), findsOneWidget);
      expect(find.text('PIN'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Biometrics'), findsOneWidget);
      expect(find.text('Device Only'), findsOneWidget);
      expect(find.textContaining('TrueLern uses secure verification'), findsOneWidget);
    });

    testWidgets('displays error card and retry button on failure',
        (tester) async {
      fakeRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginMethodsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: ParentLoginMethodsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed to load login methods'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
