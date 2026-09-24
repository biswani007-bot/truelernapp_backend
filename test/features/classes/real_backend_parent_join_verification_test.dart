import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/classes/data/repositories/classes_repository_impl.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';

// ignore_for_file: avoid_print

class RealJoinStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<void> saveAccessToken(String token) async => _data['access_token'] = token;

  @override
  Future<void> deleteAccessToken() async => _data.remove('access_token');

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> saveRefreshToken(String token) async => _data['refresh_token'] = token;

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
  Future<void> saveActiveChildId(String childId) async => _data['active_child_id'] = childId;

  @override
  Future<void> deleteActiveChildId() async => _data.remove('active_child_id');
}

void main() {
  group('Real Backend Parent Join API Verification', () {
    test(
      'authenticates and executes POST /api/parent/children/{childStudentId}/live-classes/{classId}/join with real credentials',
      () async {
        final storage = RealJoinStorage();
        final container = ProviderContainer(
          overrides: [
            secureStorageProvider.overrideWithValue(storage),
          ],
        );
        addTearDown(container.dispose);

        // 1. Authenticate with real parent credentials
        final authNotifier = container.read(authControllerProvider.notifier);
        final loginOk = await authNotifier.login(
          email: 'parent@truelern.com',
          password: 'password123',
        );

        expect(loginOk, isTrue);
        final authState = container.read(authControllerProvider);
        expect(authState, isA<Authenticated>());

        // 2. Query linked children
        final dashboardRepo = container.read(dashboardRepositoryProvider);
        final children = await dashboardRepo.getLinkedChildren();
        expect(children, isNotEmpty);
        print('----------------------------------------------------');
        print('REAL BACKEND VERIFICATION: Found ${children.length} linked children');

        final classesRepo = container.read(classesRepositoryProvider);

        // 3. Test Join for Child 1
        final child1 = children.firstWhere(
          (c) => c.firstName.toLowerCase().contains('sarah'),
          orElse: () => children.first,
        );
        final classes1 = await classesRepo.getLiveClasses(child1.studentId);
        print('Child 1: ${child1.displayName} (${child1.studentId}) - classes: ${classes1.length}');
        for (final c in classes1) {
          print('  Class: id=${c.id}, title="${c.title}", status=${c.status}');
        }

        // 3. Test Join for real class "testing" (6ab24641aabd606a21c0dbdf)
        final testingClassId = '6ab24641aabd606a21c0dbdf';
        print('Executing real classesRepo.joinLiveClass for testing class ($testingClassId)...');

        final joinResult = await classesRepo.joinLiveClass(
          childStudentId: child1.studentId,
          classId: testingClassId,
        );

        print('Join succeeded with real token: ${joinResult.token.isNotEmpty}');
        print('  roomName: ${joinResult.roomName}');
        print('  jitsiDomain: ${joinResult.jitsiDomain}');
        print('  serverUrl: ${joinResult.serverUrl}');
        print('  isModerator: ${joinResult.isModerator}');
        print('  childId: ${joinResult.childId}');
        print('  classId: ${joinResult.classId}');
        print('  classTitle: ${joinResult.classTitle}');

        expect(joinResult.token, isNotEmpty);
        expect(joinResult.roomName, 'truelern-6ab24641aabd606a21c0dbdf');
        expect(joinResult.jitsiDomain, 'livetl.visital.in');
        expect(joinResult.serverUrl, 'https://livetl.visital.in');
        expect(joinResult.isModerator, isFalse);
        expect(joinResult.classTitle, 'testing');
        print('----------------------------------------------------');
        print('REAL BACKEND PARENT JOIN VERIFICATION COMPLETE: ALL ASSERTIONS PASSED');
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );
  });
}
