import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/dashboard_state.dart';

class FakeDashboardRepository implements DashboardRepository {
  DashboardEntity? dashboardToReturn;
  Failure? failureToThrow;
  String? lastRequestedChildId;
  int callCount = 0;

  @override
  Future<List<ChildEntity>> getLinkedChildren() async => [];

  @override
  Future<DashboardEntity> getChildDashboard({
    required String childStudentId,
  }) async {
    callCount++;
    lastRequestedChildId = childStudentId;
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
    return dashboardToReturn ??
        const DashboardEntity(
          attendanceRate: 95.0,
          upcomingClassesCount: 3,
          pendingAssignmentsCount: 2,
          totalBalanceDue: 150.0,
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDashboardRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeDashboardRepository();
    container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(fakeRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state is DashboardInitial', () {
    final state = container.read(dashboardControllerProvider);
    expect(state, isA<DashboardInitial>());
  });

  test('loadDashboard with null childStudentId transitions to DashboardNoChild without API call', () async {
    await container
        .read(dashboardControllerProvider.notifier)
        .loadDashboard(childStudentId: null);

    final state = container.read(dashboardControllerProvider);
    expect(state, isA<DashboardNoChild>());
    expect(fakeRepo.callCount, 0);
  });

  test('loadDashboard with empty childStudentId transitions to DashboardNoChild without API call', () async {
    await container
        .read(dashboardControllerProvider.notifier)
        .loadDashboard(childStudentId: '');

    final state = container.read(dashboardControllerProvider);
    expect(state, isA<DashboardNoChild>());
    expect(fakeRepo.callCount, 0);
  });

  test('loadDashboard with valid childStudentId fetches data and emits DashboardLoaded', () async {
    const expected = DashboardEntity(
      attendanceRate: 92.5,
      upcomingClassesCount: 5,
      pendingAssignmentsCount: 3,
      totalBalanceDue: 450.0,
    );
    fakeRepo.dashboardToReturn = expected;

    await container
        .read(dashboardControllerProvider.notifier)
        .loadDashboard(childStudentId: 'stud_999');

    expect(fakeRepo.lastRequestedChildId, 'stud_999');
    final state = container.read(dashboardControllerProvider);
    expect(state, isA<DashboardLoaded>());
    final loaded = state as DashboardLoaded;
    expect(loaded.dashboard.attendanceRate, 92.5);
    expect(loaded.dashboard.upcomingClassesCount, 5);
    expect(loaded.dashboard.pendingAssignmentsCount, 3);
    expect(loaded.dashboard.totalBalanceDue, 450.0);
  });

  test(
    'loadDashboard emits DashboardError when repository throws failure',
    () async {
      fakeRepo.failureToThrow = const ServerFailure('Internal server error');

      await container
          .read(dashboardControllerProvider.notifier)
          .loadDashboard(childStudentId: 'stud_999');

      final state = container.read(dashboardControllerProvider);
      expect(state, isA<DashboardError>());
      final error = state as DashboardError;
      expect(error.message, isNotEmpty);
    },
  );

  test('retry uses activeChildId from childrenControllerProvider', () async {
    fakeRepo.dashboardToReturn = const DashboardEntity(
      attendanceRate: 88.0,
      upcomingClassesCount: 1,
      pendingAssignmentsCount: 0,
      totalBalanceDue: 0.0,
    );

    // Initial fetch
    await container
        .read(dashboardControllerProvider.notifier)
        .loadDashboard(childStudentId: 'stud_123');
    expect(fakeRepo.callCount, 1);

    // Call retry
    await container.read(dashboardControllerProvider.notifier).retry();
    // Since childrenControllerProvider has not loaded, activeChildId is null -> DashboardNoChild
    final state = container.read(dashboardControllerProvider);
    expect(state, isA<DashboardNoChild>());
  });
}
