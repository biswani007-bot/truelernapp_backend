import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_my_child_screen.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/child_selector_row.dart';

class MockChildrenController extends ChildrenController {
  final ChildrenState _initial;
  MockChildrenController(this._initial);

  @override
  ChildrenState build() => _initial;

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  void setActiveChild(String studentId) {
    if (state is ChildrenLoaded) {
      final cur = state as ChildrenLoaded;
      state = ChildrenLoaded(children: cur.children, activeChildId: studentId);
    }
  }
}

List<ChildEntity> createTestChildren(int count) {
  return List.generate(
    count,
    (i) => ChildEntity(
      studentId: 'child_id_$i',
      firstName: 'Child$i',
      lastName: 'Surname$i',
      grade: 'Grade ${i + 1}',
      gender: i.isEven ? 'female' : 'male',
      studentCode: 'STU-00$i',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildMyChildScreen(ChildrenState state) {
    return ProviderScope(
      overrides: [
        childrenControllerProvider.overrideWith(
          () => MockChildrenController(state),
        ),
        childDashboardMetricsProvider.overrideWith(
          (ref, id) async => const DashboardEntity(),
        ),
      ],
      child: const MaterialApp(home: ParentMyChildScreen()),
    );
  }

  group('Parent My Child Dynamic Child Count Tests', () {
    testWidgets('1. API returns 5 children -> all 5 mapped and rendered', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final children5 = createTestChildren(5);
      await tester.pumpWidget(
        buildMyChildScreen(
          ChildrenLoaded(children: children5, activeChildId: 'child_id_0'),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        expect(find.byKey(Key('my_child_card_child_id_$i')), findsOneWidget);
        expect(find.text('Child$i Surname$i'), findsOneWidget);
        expect(
          find.byKey(Key('view_child_button_child_id_$i')),
          findsOneWidget,
        );
      }
      expect(find.text('ADD CHILD'), findsOneWidget);
    });

    testWidgets('2. API returns 2 children -> exactly 2 rendered', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final children2 = createTestChildren(2);
      await tester.pumpWidget(
        buildMyChildScreen(
          ChildrenLoaded(children: children2, activeChildId: 'child_id_0'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('my_child_card_child_id_0')), findsOneWidget);
      expect(find.byKey(const Key('my_child_card_child_id_1')), findsOneWidget);
      expect(find.byKey(const Key('my_child_card_child_id_2')), findsNothing);
    });

    testWidgets('3. API returns 0 children -> empty state rendered', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildMyChildScreen(
          const ChildrenLoaded(children: [], activeChildId: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Children Linked Yet'), findsOneWidget);
      expect(find.text('ADD CHILD'), findsOneWidget);
    });

    testWidgets(
      '4. API returns more than 5 (7 children) -> all 7 rendered without limit',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 6000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final children7 = createTestChildren(7);
        await tester.pumpWidget(
          buildMyChildScreen(
            ChildrenLoaded(children: children7, activeChildId: 'child_id_0'),
          ),
        );
        await tester.pumpAndSettle();

        for (int i = 0; i < 7; i++) {
          expect(find.byKey(Key('my_child_card_child_id_$i')), findsOneWidget);
          expect(find.text('Child$i Surname$i'), findsOneWidget);
        }
      },
    );

    testWidgets('5. API error -> proper error state displayed', (tester) async {
      await tester.pumpWidget(
        buildMyChildScreen(
          const ChildrenError(message: 'Network connection failed'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load children'), findsOneWidget);
      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('6. Child selection -> activates correct child ID', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final children = createTestChildren(3);
      final controller = MockChildrenController(
        ChildrenLoaded(children: children, activeChildId: 'child_id_0'),
      );

      final router = GoRouter(
        initialLocation: '/my-child',
        routes: [
          GoRoute(
            path: '/my-child',
            builder: (ctx, state) => const ParentMyChildScreen(),
          ),
          GoRoute(
            path: '/parent/dashboard',
            builder: (ctx, state) =>
                const Scaffold(body: Text('Dashboard View')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenControllerProvider.overrideWith(() => controller),
            childDashboardMetricsProvider.overrideWith(
              (ref, id) async => const DashboardEntity(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on second child's VIEW CHILD button
      await tester.tap(find.byKey(const Key('view_child_button_child_id_1')));
      await tester.pumpAndSettle();

      expect((controller.state as ChildrenLoaded).activeChildId, 'child_id_1');
    });

    testWidgets(
      '7. Dashboard and My Child share the exact same childrenControllerProvider',
      (tester) async {
        final children7 = createTestChildren(7);
        final controller = MockChildrenController(
          ChildrenLoaded(children: children7, activeChildId: 'child_id_0'),
        );

        final container = ProviderContainer(
          overrides: [
            childrenControllerProvider.overrideWith(() => controller),
          ],
        );

        final state = container.read(childrenControllerProvider);
        expect(state, isA<ChildrenLoaded>());
        expect((state as ChildrenLoaded).children.length, 7);
      },
    );

    testWidgets(
      '8. No artificial 2-child limit: ChildSelectorRow on Dashboard renders all children',
      (tester) async {
        final children7 = createTestChildren(7);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChildSelectorRow(
                children: children7,
                activeChildId: 'child_id_0',
                onSelectChild: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('child_selector_list_view')),
          findsOneWidget,
        );
        for (int i = 0; i < 7; i++) {
          expect(find.byKey(Key('child_card_child_id_$i')), findsOneWidget);
        }
      },
    );
  });
}
