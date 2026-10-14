import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/dashboard/data/models/add_child_request_dto.dart';
import 'package:truelearn/features/dashboard/data/models/child_dto.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_my_child_screen.dart';

class FakeChildrenController extends ChildrenController {
  final ChildrenState _initial;
  int refreshCount = 0;

  FakeChildrenController(this._initial);

  @override
  ChildrenState build() => _initial;

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {
    refreshCount++;
  }

  @override
  void setActiveChild(String studentId) {
    if (state is ChildrenLoaded) {
      final cur = state as ChildrenLoaded;
      state = ChildrenLoaded(children: cur.children, activeChildId: studentId);
    }
  }
}

class FakeAddChildRepo implements AddChildRepository {
  AddChildRequestDto? lastRequest;
  String? lastUnlinkedId;

  @override
  Future<ChildEntity> addChild(AddChildRequestDto request) async {
    lastRequest = request;
    return ChildEntity(
      studentId: 'new_child_123',
      firstName: request.firstName,
      lastName: request.lastName,
      studentCode: request.studentCode ?? 'STU-99999',
    );
  }

  @override
  Future<void> unlinkChild({required String childStudentId}) async {
    lastUnlinkedId = childStudentId;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChildDto and ChildEntity Contract Tests', () {
    test('ChildDto parses real backend JSON from GET /api/parent/children correctly', () {
      final json = {
        'linkId': '6aa8f3ee544375d59742364b',
        'studentId': '6a89117035e1245c12ebf5d6',
        'studentCode': 'STU-00008',
        'firstName': 'Sarah',
        'lastName': 'Connor',
        'gender': 'female',
        'dob': '2015-05-10T00:00:00.000Z',
        'relationshipType': 'guardian',
        'isCustodial': true,
        'isEmergencyContact': true,
        'canAccessPortal': true,
        'status': 'active',
      };

      final dto = ChildDto.fromJson(json);
      expect(dto.studentId, '6a89117035e1245c12ebf5d6');
      expect(dto.firstName, 'Sarah');
      expect(dto.lastName, 'Connor');
      expect(dto.studentCode, 'STU-00008');
      expect(dto.gender, 'female');
      expect(dto.relationshipType, 'guardian');
      expect(dto.status, 'active');
      expect(dto.dateOfBirth, '2015-05-10T00:00:00.000Z');
      expect(dto.isCustodial, true);
      expect(dto.isEmergencyContact, true);
      expect(dto.canAccessPortal, true);

      final entity = dto.toEntity();
      expect(entity.studentId, '6a89117035e1245c12ebf5d6');
      expect(entity.displayName, 'Sarah Connor');
      expect(entity.age, isNotNull);
      expect(entity.age, greaterThanOrEqualTo(10));
      expect(entity.isCustodial, true);
      expect(entity.isEmergencyContact, true);
    });

    test(
      'ChildEntity derives age accurately and returns null if dob is missing',
      () {
        const childWithoutDob = ChildEntity(
          studentId: 'c1',
          firstName: 'Ram',
          lastName: 'Pearson',
          studentCode: 'STU-00004',
          status: 'active',
        );
        expect(childWithoutDob.age, isNull);

        const childWithDob = ChildEntity(
          studentId: 'c2',
          firstName: 'Alex',
          lastName: 'Mercer',
          dateOfBirth: '2017-01-01T00:00:00.000Z',
        );
        expect(childWithDob.age, isNotNull);
        expect(childWithDob.age, greaterThanOrEqualTo(8));
      },
    );

    test('AddChildRequestDto serializes exact backend-verified fields without grade', () {
      const req = AddChildRequestDto(
        firstName: 'Emma',
        lastName: 'Stone',
        studentCode: 'STU-00010',
        relationshipType: 'mother',
        gender: 'female',
        dateOfBirth: '2016-04-12',
      );

      final json = req.toJson();
      expect(json['firstName'], 'Emma');
      expect(json['lastName'], 'Stone');
      expect(json['studentCode'], 'STU-00010');
      expect(json['relationshipType'], 'mother');
      expect(json['gender'], 'female');
      expect(json['dob'], '2016-04-12');
      expect(json.containsKey('grade'), isFalse);
    });
  });

  group('ParentMyChildScreen UI & Integration Tests', () {
    Widget createWidgetUnderTest(
      ChildrenState state, {
      FakeChildrenController? controller,
      FakeAddChildRepo? addChildRepo,
    }) {
      final ctrl = controller ?? FakeChildrenController(state);
      final repo = addChildRepo ?? FakeAddChildRepo();
      final router = GoRouter(
        initialLocation: '/children',
        routes: [
          GoRoute(
            path: '/children',
            builder: (context, state) => const ParentMyChildScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.parentDashboard,
            builder: (context, state) =>
                const Scaffold(body: Text('Dashboard')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          childrenControllerProvider.overrideWith(() => ctrl),
          childDashboardMetricsProvider.overrideWith(
            (ref, id) async => const DashboardEntity(),
          ),
          addChildRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('renders loading state when ChildrenLoading', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const ChildrenLoading()));
      await tester.pump();

      expect(find.text('Loading linked children...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state when children list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const ChildrenLoaded(children: [], activeChildId: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Children Linked Yet'), findsOneWidget);
      expect(find.text('ADD CHILD'), findsOneWidget);
    });

    testWidgets('renders real children cards and handles child selection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final children = [
        const ChildEntity(
          studentId: 'c1',
          firstName: 'Sarah',
          lastName: 'Connor',
          studentCode: 'STU-00008',
          status: 'active',
          dateOfBirth: '2015-05-10T00:00:00.000Z',
          relationshipType: 'guardian',
          isCustodial: true,
        ),
        const ChildEntity(
          studentId: 'c2',
          firstName: 'Ram',
          lastName: 'Pearson',
          studentCode: 'STU-00004',
          status: 'active',
          relationshipType: 'father',
        ),
      ];

      final fakeCtrl = FakeChildrenController(
        ChildrenLoaded(children: children, activeChildId: 'c1'),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          ChildrenLoaded(children: children, activeChildId: 'c1'),
          controller: fakeCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Top Header & Subtitle
      expect(find.text('My Child'), findsOneWidget);
      expect(
        find.text('Select a profile to view their learning journey.'),
        findsOneWidget,
      );

      // Child 1: Sarah Connor
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget); // active child badge
      expect(find.text('Custodial'), findsOneWidget);
      expect(find.byKey(const Key('view_child_button_c1')), findsOneWidget);
      expect(find.byKey(const Key('unlink_child_button_c1')), findsOneWidget);

      // Child 2: Ram Pearson
      expect(find.text('Ram Pearson'), findsOneWidget);
      expect(find.text('STU-00004'), findsWidgets);
      expect(find.byKey(const Key('view_child_button_c2')), findsOneWidget);
      expect(find.byKey(const Key('unlink_child_button_c2')), findsOneWidget);

      // Tap VIEW CHILD for Ram
      await tester.tap(find.byKey(const Key('view_child_button_c2')));
      await tester.pumpAndSettle();

      expect((fakeCtrl.state as ChildrenLoaded).activeChildId, 'c2');
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets(
      'Unlink Child: cancel does nothing, confirm triggers unlinking',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final children = [
          const ChildEntity(
            studentId: 'c1',
            firstName: 'Sarah',
            lastName: 'Connor',
            studentCode: 'STU-00008',
          ),
        ];

        final fakeRepo = FakeAddChildRepo();
        final fakeCtrl = FakeChildrenController(
          ChildrenLoaded(children: children, activeChildId: 'c1'),
        );

        await tester.pumpWidget(
          createWidgetUnderTest(
            ChildrenLoaded(children: children, activeChildId: 'c1'),
            controller: fakeCtrl,
            addChildRepo: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Tap UNLINK button
        await tester.tap(find.byKey(const Key('unlink_child_button_c1')));
        await tester.pumpAndSettle();

        // Verify confirmation dialog
        expect(find.text('Unlink Child'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Tap Cancel -> dialog dismissed, no API call
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(fakeRepo.lastUnlinkedId, isNull);

        // Tap UNLINK again and Confirm
        await tester.tap(find.byKey(const Key('unlink_child_button_c1')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_unlink_button_c1')));
        await tester.pumpAndSettle();

        expect(fakeRepo.lastUnlinkedId, 'c1');
        expect(fakeCtrl.refreshCount, greaterThan(0));
      },
    );

    testWidgets('renders error card and retry button on failure', (
      tester,
    ) async {
      final fakeCtrl = FakeChildrenController(
        const ChildrenError(message: 'Failed to fetch'),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          const ChildrenError(message: 'Failed to fetch'),
          controller: fakeCtrl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load children'), findsOneWidget);
      expect(find.text('Failed to fetch'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(fakeCtrl.refreshCount, greaterThan(0));
    });
  });
}
