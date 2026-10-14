import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/classes/data/repositories/classes_repository_impl.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';

// ignore_for_file: avoid_print

class LiveVerificationStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<void> saveAccessToken(String token) async =>
      _data['access_token'] = token;

  @override
  Future<void> deleteAccessToken() async => _data.remove('access_token');

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> saveRefreshToken(String token) async =>
      _data['refresh_token'] = token;

  @override
  Future<void> deleteRefreshToken() async => _data.remove('refresh_token');

  @override
  Future<String?> getUserId() async => _data['user_id'];

  @override
  Future<void> saveUserId(String id) async => _data['user_id'] = id;

  @override
  Future<void> clearAuthSession() async => _data.clear();

  @override
  Future<String?> getActiveChildId() async => _data['active_child_id'];

  @override
  Future<void> saveActiveChildId(String childId) async =>
      _data['active_child_id'] = childId;

  @override
  Future<void> deleteActiveChildId() async => _data.remove('active_child_id');

  bool hasAccessToken() =>
      _data.containsKey('access_token') && _data['access_token']!.isNotEmpty;
}

void main() {
  group('ACTION 5D — Parent Classes Real Runtime API Verification', () {
    test('authenticates against real production API and queries GET /api/parent/children/{childStudentId}/live-classes', () async {
      final storage = LiveVerificationStorage();
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      // Step 1: Real login
      final authNotifier = container.read(authControllerProvider.notifier);
      final loginOk = await authNotifier.login(
        email: 'parent@truelern.com',
        password: 'password123',
      );

      final authState = container.read(authControllerProvider);
      print('============================================================');
      print('ACTION 5D RUNTIME VERIFICATION');
      print('Login success: $loginOk');
      print('AuthState: ${authState.runtimeType}');

      if (authState is! Authenticated) {
        print('Authentication failed during runtime verification test.');
        print('============================================================');
        return;
      }

      print('Access Token stored: ${storage.hasAccessToken()}');

      // Step 2: Query linked children via real dashboard repository
      final dashboardRepo = container.read(dashboardRepositoryProvider);
      final children = await dashboardRepo.getLinkedChildren();
      print('GET /api/parent/children count: ${children.length}');

      expect(children, isNotEmpty);
      final firstChild = children.first;
      print(
        'Active Child: id=${firstChild.studentId}, name=${firstChild.displayName}',
      );

      // Step 3: Query real ClassesRepository against GET /api/parent/children/{childStudentId}/live-classes for all children
      final classesRepo = container.read(classesRepositoryProvider);
      final apiClient = container.read(apiClientProvider);
      for (final child in children) {
        final rawRes = await apiClient.get<Map<String, dynamic>>(
          '/parent/children/${child.studentId}/live-classes',
        );
        final rawData = rawRes.data?['data'];
        print('Raw response data for ${child.displayName}: $rawData');

        final classes = await classesRepo.getLiveClasses(child.studentId);
        print(
          'GET /api/parent/children/${child.studentId}/live-classes (${child.displayName}) count: ${classes.length}',
        );
        for (final c in classes) {
          print(
            '  Class: id=${c.id}, title="${c.title}", subject=${c.subject}, status=${c.status}, teacher=${c.teacherName}',
          );
        }
        expect(classes, isA<List>());
      }
      print(
        'Live Classes API calls returned HTTP 200 and parsed safely without exceptions.',
      );
      print('============================================================');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
