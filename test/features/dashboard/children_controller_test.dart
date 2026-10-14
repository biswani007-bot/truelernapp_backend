import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class FakeDashboardRepository implements DashboardRepository {
  List<ChildEntity> childrenToReturn = [];
  Failure? failureToThrow;
  int callCount = 0;

  @override
  Future<List<ChildEntity>> getLinkedChildren() async {
    callCount++;
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
    return childrenToReturn;
  }

  @override
  Future<DashboardEntity> getChildDashboard({
    required String childStudentId,
  }) async {
    throw UnimplementedError();
  }
}

class FakeSecureStorage implements SecureStorageService {
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
  Future<String?> getActiveChildId() async => _data['active_child_id'];

  @override
  Future<void> saveActiveChildId(String childId) async =>
      _data['active_child_id'] = childId;

  @override
  Future<void> deleteActiveChildId() async => _data.remove('active_child_id');

  @override
  Future<void> clearAuthSession() async => _data.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDashboardRepository fakeRepo;
  late FakeSecureStorage fakeStorage;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeDashboardRepository();
    fakeStorage = FakeSecureStorage();
    container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(fakeRepo),
        secureStorageProvider.overrideWithValue(fakeStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state is ChildrenInitial', () {
    final state = container.read(childrenControllerProvider);
    expect(state, isA<ChildrenInitial>());
  });

  test('loadChildren emits ChildrenLoaded with children and selects first by default', () async {
    const child1 = ChildEntity(
      studentId: 'stud_1',
      firstName: 'Alice',
      lastName: 'Smith',
      grade: 'Grade 5',
    );
    const child2 = ChildEntity(
      studentId: 'stud_2',
      firstName: 'Bob',
      lastName: 'Smith',
      grade: 'Grade 3',
    );
    fakeRepo.childrenToReturn = [child1, child2];

    await container.read(childrenControllerProvider.notifier).loadChildren();

    final state = container.read(childrenControllerProvider);
    expect(state, isA<ChildrenLoaded>());
    final loaded = state as ChildrenLoaded;
    expect(loaded.children.length, 2);
    expect(loaded.activeChildId, 'stud_1');
    expect(loaded.activeChild?.firstName, 'Alice');
    expect(await fakeStorage.getActiveChildId(), 'stud_1');
  });

  test('loadChildren with isRefresh: true preserves currently selected active child', () async {
    const child1 = ChildEntity(studentId: 'stud_1', firstName: 'Alice');
    const child2 = ChildEntity(studentId: 'stud_2', firstName: 'Bob');
    fakeRepo.childrenToReturn = [child1, child2];

    // Initial load selects stud_1
    await container.read(childrenControllerProvider.notifier).loadChildren();
    // User selects stud_2
    container
        .read(childrenControllerProvider.notifier)
        .setActiveChild('stud_2');
    expect(
      (container.read(
        childrenControllerProvider,
      ) as ChildrenLoaded).activeChildId,
      'stud_2',
    );

    // Pull-to-refresh
    await container
        .read(childrenControllerProvider.notifier)
        .loadChildren(isRefresh: true);

    final refreshed =
        container.read(childrenControllerProvider) as ChildrenLoaded;
    // CRITICAL BUG FIX CHECK: Must remain stud_2, not reset to stud_1
    expect(refreshed.activeChildId, 'stud_2');
    expect(refreshed.activeChild?.firstName, 'Bob');
    expect(await fakeStorage.getActiveChildId(), 'stud_2');
  });

  test('loadChildren restores active child from secure storage when state is not loaded', () async {
    await fakeStorage.saveActiveChildId('stud_2');

    const child1 = ChildEntity(studentId: 'stud_1', firstName: 'Alice');
    const child2 = ChildEntity(studentId: 'stud_2', firstName: 'Bob');
    fakeRepo.childrenToReturn = [child1, child2];

    await container.read(childrenControllerProvider.notifier).loadChildren();

    final loaded = container.read(childrenControllerProvider) as ChildrenLoaded;
    expect(loaded.activeChildId, 'stud_2');
    expect(loaded.activeChild?.firstName, 'Bob');
  });

  test('loadChildren emits ChildrenLoaded with empty list when parent has no children', () async {
    fakeRepo.childrenToReturn = [];

    await container.read(childrenControllerProvider.notifier).loadChildren();

    final state = container.read(childrenControllerProvider);
    expect(state, isA<ChildrenLoaded>());
    final loaded = state as ChildrenLoaded;
    expect(loaded.children, isEmpty);
    expect(loaded.activeChildId, isNull);
    expect(loaded.hasChildren, isFalse);
  });

  test('loadChildren emits ChildrenError on repository failure', () async {
    fakeRepo.failureToThrow = const ServerFailure('Backend unavailable');

    await container.read(childrenControllerProvider.notifier).loadChildren();

    final state = container.read(childrenControllerProvider);
    expect(state, isA<ChildrenError>());
    final error = state as ChildrenError;
    expect(error.message, contains('Backend unavailable'));
  });

  test(
    'setActiveChild updates activeChildId and persists to storage',
    () async {
      const child1 = ChildEntity(studentId: 'stud_1', firstName: 'Alice');
      const child2 = ChildEntity(studentId: 'stud_2', firstName: 'Bob');
      fakeRepo.childrenToReturn = [child1, child2];

      await container.read(childrenControllerProvider.notifier).loadChildren();
      container
          .read(childrenControllerProvider.notifier)
          .setActiveChild('stud_2');

      final state =
          container.read(childrenControllerProvider) as ChildrenLoaded;
      expect(state.activeChildId, 'stud_2');
      expect(state.activeChild?.firstName, 'Bob');
      expect(await fakeStorage.getActiveChildId(), 'stud_2');
    },
  );

  test('setActiveChild ignores non-existent child ID', () async {
    const child1 = ChildEntity(studentId: 'stud_1', firstName: 'Alice');
    fakeRepo.childrenToReturn = [child1];

    await container.read(childrenControllerProvider.notifier).loadChildren();
    container
        .read(childrenControllerProvider.notifier)
        .setActiveChild('non_existent');

    final state = container.read(childrenControllerProvider) as ChildrenLoaded;
    expect(state.activeChildId, 'stud_1');
  });

  test('retry invokes loadChildren again', () async {
    fakeRepo.childrenToReturn = [
      const ChildEntity(studentId: 'stud_1', firstName: 'Alice'),
    ];

    await container.read(childrenControllerProvider.notifier).loadChildren();
    expect(fakeRepo.callCount, 1);

    await container.read(childrenControllerProvider.notifier).retry();
    expect(fakeRepo.callCount, 2);
  });
}
