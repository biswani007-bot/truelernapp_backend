import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/parent_hamburger_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParentHamburgerDrawer Route Active Mapping Tests', () {
    test(
      'correctly maps all existing and nested routes to active drawer items',
      () {
        // 1. My Classes & subroutes
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.parentClasses,
          ),
          'My Classes',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            '/parent/classes/cls_123',
          ),
          'My Classes',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            '/parent/classes/cls_123/preview',
          ),
          'My Classes',
        );

        // 2. My Programs & subroutes
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.currentProgram,
          ),
          'My Programs',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.topicDetail,
          ),
          'My Programs',
        );

        // 3. Assignments & subroutes
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.parentAssignments,
          ),
          'Assignments',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            '/parent/assignments/asg_1/submission',
          ),
          'Assignments',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            '/parent/assignments/asg_1/submitted',
          ),
          'Assignments',
        );

        // 4. Learning Progress
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.learningProgress,
          ),
          'Learning Progress',
        );

        // 5. Assessments
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.assessments,
          ),
          'Assessments',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.achievements,
          ),
          'Assessments',
        );

        // 6. Messages
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.parentMessages,
          ),
          'Messages',
        );

        // 7. Notifications
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.notifications,
          ),
          'Notifications',
        );

        // 9. Account Settings
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.accountSettings,
          ),
          'Account Settings',
        );

        // 10. Security & Privacy + Login Methods & Devices
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.parentSecurityPrivacy,
          ),
          'Security & Privacy',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.parentLoginMethods,
          ),
          'Security & Privacy',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.parentLoginDevices,
          ),
          'Security & Privacy',
        );

        // 11. Profile + My Child + Invoices
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.parentProfile,
          ),
          'My Profile',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.myChildren,
          ),
          'My Profile',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.parentInvoices,
          ),
          'My Profile',
        );

        // 12. Dashboard / Root (no drawer item selected)
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(
            AppRoutePaths.parentDashboard,
          ),
          '',
        );
        expect(
          ParentHamburgerDrawer.getDrawerActiveItemForPath(AppRoutePaths.root),
          '',
        );
      },
    );
  });

  group(
    'ParentHamburgerDrawer Navigation and Active-Highlight Widget Tests',
    () {
      late GoRouter testRouter;

      setUp(() {
        final binding = TestWidgetsFlutterBinding.ensureInitialized();
        binding.platformDispatcher.views.first.physicalSize = const Size(
          1080,
          2400,
        );
        binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
      });

      tearDown(() {
        final binding = TestWidgetsFlutterBinding.ensureInitialized();
        binding.platformDispatcher.views.first.resetPhysicalSize();
        binding.platformDispatcher.views.first.resetDevicePixelRatio();
      });

      Widget buildTestApp({
        String initialLocation = AppRoutePaths.parentClasses,
      }) {
        testRouter = GoRouter(
          initialLocation: initialLocation,
          routes: [
            GoRoute(
              path: AppRoutePaths.parentClasses,
              builder: (context, state) => Scaffold(
                key: const Key('screen_classes'),
                appBar: AppBar(title: const Text('Classes Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('Classes Content'),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.parentAssignments,
              builder: (context, state) => Scaffold(
                key: const Key('screen_assignments'),
                appBar: AppBar(title: const Text('Assignments Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('Assignments Content'),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.currentProgram,
              builder: (context, state) => Scaffold(
                key: const Key('screen_programs'),
                appBar: AppBar(title: const Text('Programs Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('Programs Content'),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.parentMessages,
              builder: (context, state) => Scaffold(
                key: const Key('screen_messages'),
                appBar: AppBar(title: const Text('Messages Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('Messages Content'),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.notifications,
              builder: (context, state) => Scaffold(
                key: const Key('screen_notifications'),
                appBar: AppBar(title: const Text('Notifications Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('Notifications Content'),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.accountSettings,
              builder: (context, state) => Scaffold(
                key: const Key('screen_account_settings'),
                appBar: AppBar(title: const Text('Account Settings Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('Account Settings Content'),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.parentSecurityPrivacy,
              builder: (context, state) => Scaffold(
                key: const Key('screen_security_privacy'),
                appBar: AppBar(title: const Text('Security & Privacy Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('Security & Privacy Content'),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.parentProfile,
              builder: (context, state) => Scaffold(
                key: const Key('screen_profile'),
                appBar: AppBar(title: const Text('Profile Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('Profile Content'),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.myChildren,
              builder: (context, state) => Scaffold(
                key: const Key('screen_my_child'),
                appBar: AppBar(title: const Text('My Child Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('My Child Content'),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.assessments,
              builder: (context, state) => Scaffold(
                key: const Key('screen_assessments'),
                appBar: AppBar(title: const Text('Assessments Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('Assessments Content'),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.learningProgress,
              builder: (context, state) => Scaffold(
                key: const Key('screen_learning_progress'),
                appBar: AppBar(title: const Text('Learning Progress Screen')),
                drawer: const ParentHamburgerDrawer(),
                body: const Text('Learning Progress Content'),
              ),
            ),
          ],
        );

        return ProviderScope(
          child: MaterialApp.router(routerConfig: testRouter),
        );
      }

      testWidgets(
        'highlights My Classes when drawer opens on /parent/classes',
        (tester) async {
          await tester.pumpWidget(
            buildTestApp(initialLocation: AppRoutePaths.parentClasses),
          );
          await tester.pumpAndSettle();

          // Open drawer
          final scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_classes')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          // Verify My Classes container has blue active background Color(0xFF1E4ED8)
          final myClassesContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('drawer_item_my_classes')),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(myClassesContainer.decoration, isA<BoxDecoration>());
          final decoration = myClassesContainer.decoration as BoxDecoration;
          expect(decoration.color, const Color(0xFF1E4ED8));

          // Verify other items are transparent
          final assignmentsContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('drawer_item_assignments')),
                  matching: find.byType(Container),
                )
                .first,
          );
          final asgDec = assignmentsContainer.decoration as BoxDecoration;
          expect(asgDec.color, Colors.transparent);
        },
      );

      testWidgets(
        'navigates from My Classes to Assignments and updates active highlight',
        (tester) async {
          await tester.pumpWidget(
            buildTestApp(initialLocation: AppRoutePaths.parentClasses),
          );
          await tester.pumpAndSettle();

          // Open drawer
          var scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_classes')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          // Tap Assignments
          await tester.tap(find.byKey(const Key('drawer_item_assignments')));
          await tester.pumpAndSettle();

          // Verify navigated to Assignments screen
          expect(find.byKey(const Key('screen_assignments')), findsOneWidget);

          // Reopen drawer on Assignments screen
          scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_assignments')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          // Verify Assignments is now active (blue)
          final assignmentsContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('drawer_item_assignments')),
                  matching: find.byType(Container),
                )
                .first,
          );
          final asgDec = assignmentsContainer.decoration as BoxDecoration;
          expect(asgDec.color, const Color(0xFF1E4ED8));

          // Verify My Classes is no longer active
          final myClassesContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('drawer_item_my_classes')),
                  matching: find.byType(Container),
                )
                .first,
          );
          final clsDec = myClassesContainer.decoration as BoxDecoration;
          expect(clsDec.color, Colors.transparent);
        },
      );

      testWidgets(
        'navigates to My Programs, Messages, and Account Settings (Teacher Updates removed)',
        (tester) async {
          await tester.pumpWidget(
            buildTestApp(initialLocation: AppRoutePaths.parentAssignments),
          );
          await tester.pumpAndSettle();

          // Open drawer from Assignments
          var scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_assignments')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          // Verify Teacher Updates is NOT present in the drawer
          expect(
            find.byKey(const Key('drawer_item_teacher_updates')),
            findsNothing,
          );
          expect(find.text('Teacher Updates'), findsNothing);

          // 1. Navigate to My Programs
          await tester.tap(find.byKey(const Key('drawer_item_my_programs')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('screen_programs')), findsOneWidget);

          // Verify active highlight on My Programs
          scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_programs')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          final progContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('drawer_item_my_programs')),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(
            (progContainer.decoration as BoxDecoration).color,
            const Color(0xFF1E4ED8),
          );

          // 3. Navigate to Messages
          await tester.tap(find.byKey(const Key('drawer_item_messages')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('screen_messages')), findsOneWidget);

          // Verify active highlight on Messages
          scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_messages')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          final msgContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('drawer_item_messages')),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(
            (msgContainer.decoration as BoxDecoration).color,
            const Color(0xFF1E4ED8),
          );

          // 4. Navigate to Account Settings
          await tester.tap(
            find.byKey(const Key('drawer_item_account_settings')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('screen_account_settings')),
            findsOneWidget,
          );

          // Verify active highlight on Account Settings
          scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_account_settings')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          final settingsContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('drawer_item_account_settings')),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(
            (settingsContainer.decoration as BoxDecoration).color,
            const Color(0xFF1E4ED8),
          );
        },
      );

      testWidgets(
        'tapping currently active item closes drawer without duplicate navigation',
        (tester) async {
          await tester.pumpWidget(
            buildTestApp(initialLocation: AppRoutePaths.parentClasses),
          );
          await tester.pumpAndSettle();

          // Open drawer
          final scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_classes')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          // Tap My Classes while already on My Classes
          await tester.tap(find.byKey(const Key('drawer_item_my_classes')));
          await tester.pumpAndSettle();

          // Drawer is closed, still on classes screen
          expect(find.byKey(const Key('screen_classes')), findsOneWidget);
          expect(
            find.byKey(const Key('parent_hamburger_drawer')),
            findsNothing,
          );
        },
      );

      testWidgets('My Child screen correctly highlights My Profile in drawer', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestApp(initialLocation: AppRoutePaths.myChildren),
        );
        await tester.pumpAndSettle();

        final scaffoldState = tester.state<ScaffoldState>(
          find.byKey(const Key('screen_my_child')),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        final profileContainer = tester.widget<Container>(
          find
              .descendant(
                of: find.byKey(const Key('drawer_item_my_profile')),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (profileContainer.decoration as BoxDecoration).color,
          const Color(0xFF1E4ED8),
        );
      });

      testWidgets(
        'navigates to Notifications, Achievements, and Security & Privacy',
        (tester) async {
          await tester.pumpWidget(
            buildTestApp(initialLocation: AppRoutePaths.parentClasses),
          );
          await tester.pumpAndSettle();

          // 1. Notifications
          var scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_classes')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('drawer_item_notifications')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('screen_notifications')), findsOneWidget);

          scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_notifications')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          final notifContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('drawer_item_notifications')),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(
            (notifContainer.decoration as BoxDecoration).color,
            const Color(0xFF1E4ED8),
          );

          // 2. Assessments
          await tester.tap(find.byKey(const Key('drawer_item_assessments')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('screen_assessments')), findsOneWidget);

          scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_assessments')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          final assessContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('drawer_item_assessments')),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(
            (assessContainer.decoration as BoxDecoration).color,
            const Color(0xFF1E4ED8),
          );

          // 3. Security & Privacy
          await tester.tap(
            find.byKey(const Key('drawer_item_security_&_privacy')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('screen_security_privacy')),
            findsOneWidget,
          );

          scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_security_privacy')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          final secContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('drawer_item_security_&_privacy')),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(
            (secContainer.decoration as BoxDecoration).color,
            const Color(0xFF1E4ED8),
          );
        },
      );

      testWidgets(
        'Teacher Updates is completely removed from COMMUNICATION group in ParentHamburgerDrawer',
        (tester) async {
          await tester.pumpWidget(
            buildTestApp(initialLocation: AppRoutePaths.parentAssignments),
          );
          await tester.pumpAndSettle();

          final scaffoldState = tester.state<ScaffoldState>(
            find.byKey(const Key('screen_assignments')),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          // Section header exists
          expect(find.text('COMMUNICATION'), findsOneWidget);

          // Allowed communication items exist
          expect(find.text('Messages'), findsOneWidget);
          expect(find.text('Notifications'), findsOneWidget);
          expect(find.byKey(const Key('drawer_item_messages')), findsOneWidget);
          expect(
            find.byKey(const Key('drawer_item_notifications')),
            findsOneWidget,
          );

          // Teacher Updates is completely removed
          expect(find.text('Teacher Updates'), findsNothing);
          expect(
            find.byKey(const Key('drawer_item_teacher_updates')),
            findsNothing,
          );
        },
      );
    },
  );
}
