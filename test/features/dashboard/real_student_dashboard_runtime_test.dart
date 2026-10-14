import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/dashboard/data/repositories/student_dashboard_repository_impl.dart';

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
  Future<void> saveActiveChildId(String childId) async =>
      _data['active_child_id'] = childId;

  @override
  Future<String?> getActiveChildId() async => _data['active_child_id'];

  @override
  Future<void> deleteActiveChildId() async => _data.remove('active_child_id');

  @override
  Future<void> clearAuthSession() async => _data.clear();

  bool hasAccessToken() =>
      _data.containsKey('access_token') && _data['access_token']!.isNotEmpty;
}

void main() {
  group('Real Student Dashboard Runtime Verification', () {
    test('authenticates as student and fetches real student dashboard data', () async {
      final storage = LiveVerificationStorage();
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );

      addTearDown(container.dispose);

      final authNotifier = container.read(authControllerProvider.notifier);

      // 1. Authenticate with real Student credentials
      print('Logging in as Student (student@truelern.com)...');
      await authNotifier.login(
        email: 'student@truelern.com',
        password: 'password123',
      );

      final authState = container.read(authControllerProvider);
      expect(authState, isA<Authenticated>());
      final user = (authState as Authenticated).user;
      print(
        'Authenticated successfully as Student: ${user?.name}, role: ${user?.role}',
      );
      expect(user?.role?.toLowerCase(), 'student');
      expect(storage.hasAccessToken(), isTrue);

      // 2. Query Student Dashboard repository
      final studentRepo = container.read(studentDashboardRepositoryProvider);
      final dashboard = await studentRepo.getStudentDashboard();

      print('============================================================');
      print('STUDENT DASHBOARD REAL RUNTIME DATA:');
      print('  studentName: ${dashboard.studentName}');
      print('  attendanceRate: ${dashboard.attendanceRate}%');
      print('  upcomingClassesCount: ${dashboard.upcomingClassesCount}');
      print('  featuredClass: ${dashboard.featuredClass?.title}');
      print('  featuredTeacher: ${dashboard.featuredClass?.teacherName}');
      print(
        '  enrolledBatches: ${dashboard.enrolledBatches.map((b) => b.batchName).toList()}',
      );
      print('  pendingAssignmentsCount: ${dashboard.pendingAssignmentsCount}');
      print('============================================================');

      expect(dashboard.studentName, isNotNull);
      expect(dashboard.featuredClass, isNotNull);
      expect(dashboard.attendanceRate, greaterThan(0));
    });
  });
}
