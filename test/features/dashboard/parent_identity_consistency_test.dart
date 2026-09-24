import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/parent_profile_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/parent_profile_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/parent_profile_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_account_settings_screen.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_profile_screen.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/parent_hamburger_drawer.dart';

const kMockParentProfile = ParentProfileEntity(
  id: 'usr_rock_mercer',
  parentId: 'PAR-1001',
  firstName: 'Rock',
  middleName: '',
  lastName: 'Mercer',
  email: 'parent@truelern.com',
  phone: '+1 555-0199',
  alternatePhone: '+1 555-0198',
  address: '400 Castro Street Suite 500',
  city: 'San Francisco',
  state: 'CA',
  country: 'USA',
  postalCode: '94114',
  status: 'active',
  occupation: 'Architect',
  organization: 'Tech Corp',
  designation: 'Principal',
);

const List<ChildEntity> kMockChildren = [
  ChildEntity(
    studentId: 'child_1',
    firstName: 'Ethan',
    lastName: 'Mercer',
    grade: 'Grade 5',
  ),
  ChildEntity(
    studentId: 'child_2',
    firstName: 'Alex',
    lastName: 'Mercer',
    grade: 'Grade 3',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Parent Identity Consistency Across All UI Screens', () {
    testWidgets('Hamburger Drawer displays authenticated parent Rock Mercer and email',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => FakeAuthController(
                  Authenticated(
                    accessToken: 'token_123',
                    user: const UserDto(
                      id: 'usr_rock_mercer',
                      name: 'Rock Mercer',
                      email: 'parent@truelern.com',
                      role: 'parent',
                    ),
                  ),
                )),
            parentProfileControllerProvider.overrideWith(() => FakeParentProfileController(
                  const ParentProfileLoaded(profile: kMockParentProfile),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              drawer: ParentHamburgerDrawer(),
              body: Center(child: Text('Dashboard')),
            ),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify Parent Name & Email
      expect(find.byKey(const Key('drawer_parent_name')), findsOneWidget);
      expect(find.text('Rock Mercer'), findsOneWidget);
      expect(find.byKey(const Key('drawer_parent_email')), findsOneWidget);
      expect(find.text('parent@truelern.com'), findsOneWidget);

      // Verify old hardcoded name is NOT present
      expect(find.text('Hi, PPs'), findsNothing);
      expect(find.text('PPs Mercer'), findsNothing);
      expect(find.text('alex.mercer@truelern.com'), findsNothing);
    });

    testWidgets('Parent Profile Screen displays authenticated parent Rock Mercer and email',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => FakeAuthController(
                  Authenticated(
                    accessToken: 'token_123',
                    user: const UserDto(
                      id: 'usr_rock_mercer',
                      name: 'Rock Mercer',
                      email: 'parent@truelern.com',
                      role: 'parent',
                    ),
                  ),
                )),
            parentProfileControllerProvider.overrideWith(() => FakeParentProfileController(
                  const ParentProfileLoaded(profile: kMockParentProfile),
                )),
          ],
          child: const MaterialApp(
            home: ParentProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Parent Profile Hero
      expect(find.byKey(const Key('profile_parent_name')), findsOneWidget);
      expect(find.text('Rock Mercer'), findsOneWidget);
      expect(find.byKey(const Key('profile_parent_email')), findsOneWidget);
      expect(find.text('parent@truelern.com'), findsOneWidget);

      // Verify old hardcoded name is NOT present
      expect(find.text('PPs Mercer'), findsNothing);
      expect(find.text('alex.mercer@truelern.com'), findsNothing);
    });

    testWidgets('Parent Account Settings Screen displays authenticated parent Rock Mercer and email',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => FakeAuthController(
                  Authenticated(
                    accessToken: 'token_123',
                    user: const UserDto(
                      id: 'usr_rock_mercer',
                      name: 'Rock Mercer',
                      email: 'parent@truelern.com',
                      role: 'parent',
                    ),
                  ),
                )),
            parentProfileControllerProvider.overrideWith(() => FakeParentProfileController(
                  const ParentProfileLoaded(profile: kMockParentProfile),
                )),
          ],
          child: const MaterialApp(
            home: ParentAccountSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Parent Header & Personal Card
      expect(find.byKey(const Key('account_settings_parent_name')), findsOneWidget);
      expect(find.text('Rock Mercer'), findsNWidgets(2)); // Header + Personal row
      expect(find.text('parent@truelern.com'), findsOneWidget);
      expect(find.text('Parent Account'), findsOneWidget);

      // Verify old hardcoded name is NOT present
      expect(find.text('PPs'), findsNothing);
      expect(find.text('PPs Mercher'), findsNothing);
      expect(find.text('alex@rivers.com'), findsNothing);
      expect(find.text('Student Account'), findsNothing);
    });

    testWidgets('Switching active child NEVER changes authenticated Parent identity',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => FakeAuthController(
                  Authenticated(
                    accessToken: 'token_123',
                    user: const UserDto(
                      id: 'usr_rock_mercer',
                      name: 'Rock Mercer',
                      email: 'parent@truelern.com',
                      role: 'parent',
                    ),
                  ),
                )),
            parentProfileControllerProvider.overrideWith(() => FakeParentProfileController(
                  const ParentProfileLoaded(profile: kMockParentProfile),
                )),
            childrenControllerProvider.overrideWith(() => FakeChildrenController(
                  const ChildrenLoaded(
                    children: kMockChildren,
                    activeChildId: 'child_1', // Ethan
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              drawer: ParentHamburgerDrawer(),
              body: Center(child: Text('Dashboard Content')),
            ),
          ),
        ),
      );

      // Open drawer while child 1 (Ethan) is active
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Rock Mercer'), findsOneWidget);
      expect(find.text('parent@truelern.com'), findsOneWidget);

      // Switch active child to child 2 (Alex) using the active container's notifier
      final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
      (container.read(childrenControllerProvider.notifier) as FakeChildrenController)
          .setActiveChild('child_2');
      await tester.pumpAndSettle();

      // Parent identity MUST REMAIN Rock Mercer
      expect(find.text('Rock Mercer'), findsOneWidget);
      expect(find.text('parent@truelern.com'), findsOneWidget);
      expect(find.text('Alex Mercer'), findsNothing);
      expect(find.text('Ethan Mercer'), findsNothing);
    });
  });
}

class FakeAuthController extends AuthController {
  final AuthState _initialState;
  FakeAuthController(this._initialState);

  @override
  AuthState build() => _initialState;
}

class FakeParentProfileController extends ParentProfileController {
  final ParentProfileState _initialState;
  FakeParentProfileController(this._initialState);

  @override
  ParentProfileState build() => _initialState;

  @override
  Future<void> loadProfile({bool refresh = false}) async {}
}

class FakeChildrenController extends ChildrenController {
  final ChildrenState _initialState;
  FakeChildrenController(this._initialState);

  @override
  ChildrenState build() => _initialState;

  @override
  void setActiveChild(String childId) {
    if (state is ChildrenLoaded) {
      state = ChildrenLoaded(
        children: (state as ChildrenLoaded).children,
        activeChildId: childId,
      );
    }
  }
}
