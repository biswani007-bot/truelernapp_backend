import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/classes/data/repositories/classes_repository_impl.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/class_join_entity.dart';
import 'package:truelearn/features/classes/domain/repositories/classes_repository.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_state.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';

class FakeClassesRepository implements ClassesRepository {
  List<ClassEntity>? classesToReturn;
  Failure? failureToThrow;
  String? lastRequestedChildId;
  int callCount = 0;

  @override
  Future<List<ClassEntity>> getLiveClasses(String childStudentId) async {
    callCount++;
    lastRequestedChildId = childStudentId;
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
    return classesToReturn ?? [];
  }

  @override
  Future<ClassJoinEntity> joinLiveClass({
    required String childStudentId,
    required String classId,
  }) async {
    return ClassJoinEntity(
      token: 'fake-token',
      roomName: 'truelern-$classId',
      jitsiDomain: 'livetl.visital.in',
      serverUrl: 'https://livetl.visital.in',
      meetingUrl: 'https://livetl.visital.in/truelern-$classId?jwt=fake-token',
      isModerator: false,
    );
  }
}

class FakeDashboardRepository implements DashboardRepository {
  List<ChildEntity> childrenToReturn = [];
  @override
  Future<List<ChildEntity>> getLinkedChildren() async => childrenToReturn;
  @override
  Future<DashboardEntity> getChildDashboard({required String childStudentId}) async =>
      const DashboardEntity();
}

class FakeSecureStorage implements SecureStorageService {
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
  Future<String?> getActiveChildId() async => _data['active_child_id'];

  @override
  Future<void> saveActiveChildId(String childId) async => _data['active_child_id'] = childId;

  @override
  Future<void> deleteActiveChildId() async => _data.remove('active_child_id');

  @override
  Future<void> clearAuthSession() async => _data.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeClassesRepository fakeRepo;
  late FakeDashboardRepository fakeDashRepo;
  late FakeSecureStorage fakeStorage;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeClassesRepository();
    fakeDashRepo = FakeDashboardRepository();
    fakeStorage = FakeSecureStorage();
    container = ProviderContainer(
      overrides: [
        classesRepositoryProvider.overrideWithValue(fakeRepo),
        dashboardRepositoryProvider.overrideWithValue(fakeDashRepo),
        secureStorageProvider.overrideWithValue(fakeStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state is ClassesInitial', () {
    final state = container.read(classesControllerProvider);
    expect(state, isA<ClassesInitial>());
  });

  test('loadClasses with null childStudentId transitions to ClassesNoChild without calling repository', () async {
    await container
        .read(classesControllerProvider.notifier)
        .loadClasses(childStudentId: null);

    final state = container.read(classesControllerProvider);
    expect(state, isA<ClassesNoChild>());
    expect(fakeRepo.callCount, 0);
  });

  test('loadClasses with empty childStudentId transitions to ClassesNoChild without calling repository', () async {
    await container
        .read(classesControllerProvider.notifier)
        .loadClasses(childStudentId: '');

    final state = container.read(classesControllerProvider);
    expect(state, isA<ClassesNoChild>());
    expect(fakeRepo.callCount, 0);
  });

  test('loadClasses with valid childStudentId fetches schedule and emits ClassesLoaded (empty list)', () async {
    fakeRepo.classesToReturn = [];

    await container
        .read(classesControllerProvider.notifier)
        .loadClasses(childStudentId: 'child_123');

    expect(fakeRepo.lastRequestedChildId, 'child_123');
    expect(fakeRepo.callCount, 1);
    final state = container.read(classesControllerProvider);
    expect(state, isA<ClassesLoaded>());
    final loaded = state as ClassesLoaded;
    expect(loaded.classes, isEmpty);
    expect(loaded.hasClasses, isFalse);
  });

  test('loadClasses with populated schedule emits ClassesLoaded with sessions', () async {
    final session = ClassEntity(
      id: 'session_1',
      title: 'Mathematics Algebra',
      subject: 'Mathematics',
      status: 'UPCOMING',
      scheduledStartTime: DateTime(2026, 9, 10, 10, 0),
      scheduledEndTime: DateTime(2026, 9, 10, 11, 0),
      teacherName: 'Prof. Sharma',
    );
    fakeRepo.classesToReturn = [session];

    await container
        .read(classesControllerProvider.notifier)
        .loadClasses(childStudentId: 'child_123');

    final state = container.read(classesControllerProvider);
    expect(state, isA<ClassesLoaded>());
    final loaded = state as ClassesLoaded;
    expect(loaded.classes.length, 1);
    expect(loaded.hasClasses, isTrue);
    expect(loaded.classes.first.title, 'Mathematics Algebra');
  });

  test('loadClasses emits ClassesError when repository throws failure', () async {
    fakeRepo.failureToThrow = const ServerFailure('Server connection failed');

    await container
        .read(classesControllerProvider.notifier)
        .loadClasses(childStudentId: 'child_123');

    final state = container.read(classesControllerProvider);
    expect(state, isA<ClassesError>());
    final error = state as ClassesError;
    expect(error.message, contains('Server connection failed'));
  });

  test('retry invokes loadClasses using active child from ChildrenController', () async {
    const child = ChildEntity(studentId: 'child_active', firstName: 'Alice');
    fakeDashRepo.childrenToReturn = [child];

    // Load children first so activeChildId is set
    await container.read(childrenControllerProvider.notifier).loadChildren();
    final childState = container.read(childrenControllerProvider);
    expect((childState as dynamic).activeChildId, 'child_active');

    // Call retry
    await container.read(classesControllerProvider.notifier).retry();

    expect(fakeRepo.lastRequestedChildId, 'child_active');
    expect(fakeRepo.callCount, 1);
  });
}
