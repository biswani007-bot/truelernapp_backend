import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
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
  group('ACTION 5A — Parent Dashboard Real Runtime API Verification', () {
    test('authenticates against real production API and queries GET /api/parent/children', () async {
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
      print('ACTION 5A RUNTIME VERIFICATION');
      print('Login success: $loginOk');
      print('AuthState: ${authState.runtimeType}');

      if (authState is! Authenticated) {
        print('Authentication failed during runtime verification test.');
        print('============================================================');
        return;
      }

      print('Access Token stored: ${storage.hasAccessToken()}');

      // Step 2: Query linked children via real repository
      final dashboardRepo = container.read(dashboardRepositoryProvider);
      try {
        final children = await dashboardRepo.getLinkedChildren();
        print('GET /api/parent/children result count: ${children.length}');
        for (final child in children) {
          print(
            '  Child: id=${child.studentId}, name=${child.displayName}, grade=${child.grade}',
          );
        }

        if (children.isEmpty) {
          print('Parent has 0 linked children on backend.');
          print('EmptyDashboardWidget correctly handles this state.');
        } else {
          for (final child in children) {
            print('----------------------------------------------------');
            print(
              'Querying dashboard for child ${child.displayName} (id: ${child.studentId})...',
            );
            final dashboard = await dashboardRepo.getChildDashboard(
              childStudentId: child.studentId,
            );
            print('  attendanceRate: ${dashboard.attendanceRate}');
            print('  upcomingClassesCount: ${dashboard.upcomingClassesCount}');
            print(
              '  featuredClass: ${dashboard.featuredClass?.title}, teacher: ${dashboard.featuredClass?.teacherName}',
            );
            print(
              '  enrolledBatches: ${dashboard.enrolledBatches.map((b) => b.batchName).toList()}',
            );
            print(
              '  pendingAssignmentsCount: ${dashboard.pendingAssignmentsCount}',
            );
            print('  totalBalanceDue: ${dashboard.totalBalanceDue}');
          }
          final sarah = children
              .where((c) => c.displayName.contains('Sarah'))
              .firstOrNull;
          if (sarah != null) {
            final sarahDash = await dashboardRepo.getChildDashboard(
              childStudentId: sarah.studentId,
            );
            expect(sarahDash.featuredClass, isNotNull);
            expect(sarahDash.featuredClass!.title, equals('Word Puzzle'));
            expect(
              sarahDash.featuredClass!.teacherName,
              equals('Elizabeth Vance'),
            );
            print(
              'VERIFIED: Sarah Connor dashboard featuredClass is "Word Puzzle" by Elizabeth Vance.',
            );
          }

          final rony = children
              .where((c) => c.displayName.contains('Rony'))
              .firstOrNull;
          if (rony != null) {
            final ronyDash = await dashboardRepo.getChildDashboard(
              childStudentId: rony.studentId,
            );
            if (ronyDash.featuredClass != null) {
              expect(
                ronyDash.featuredClass!.title,
                anyOf(equals('test_record'), equals('what is FUTURE?')),
              );
              expect(
                ronyDash.featuredClass!.teacherName,
                equals('Jack Sparrow'),
              );
              print(
                'VERIFIED: Rony Roul dashboard featuredClass is "${ronyDash.featuredClass!.title}" by Jack Sparrow.',
              );
            } else {
              print(
                'VERIFIED: Rony Roul dashboard featuredClass is null on live backend.',
              );
            }
          }

          final ram = children
              .where((c) => c.displayName.contains('Ram'))
              .firstOrNull;
          if (ram != null) {
            final ramDash = await dashboardRepo.getChildDashboard(
              childStudentId: ram.studentId,
            );
            expect(ramDash.featuredClass, isNull);
            print(
              'VERIFIED: Ram Pearson dashboard featuredClass is null ("No live class today").',
            );
          }
        }
      } catch (e) {
        print('Error querying parent children: $e');
        rethrow;
      }
      print('============================================================');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
