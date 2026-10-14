import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/core/router/route_names.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/presentation/screens/assignment_submitted_screen.dart';
import 'package:truelearn/features/classes/presentation/screens/current_program_screen.dart';

void main() {
  testWidgets(
    'Flow 1 & 2: View Class Details opens Active Track; BACK TO LEARNING opens Dashboard',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testAssignment = AssignmentEntity(
        id: 'test-101',
        title: 'Design a Rube Goldberg Machine',
        topic: 'Practical Thinking',
        status: AssignmentStatus.pending,
        dueDate: 'Due: Friday, 11:59 PM',
      );

      final router = GoRouter(
        initialLocation: '/parent/assignments/test-101/submitted',
        routes: [
          GoRoute(
            path: '/parent/dashboard',
            name: AppRouteNames.parentDashboard,
            builder: (context, state) => const Scaffold(
              key: Key('parent_dashboard_mock'),
              body: Center(child: Text('Parent Dashboard Screen')),
            ),
          ),
          GoRoute(
            path: '/parent/assignments/:assignmentId/submitted',
            name: AppRouteNames.assignmentSubmitted,
            builder: (context, state) => AssignmentSubmittedScreen(
              assignmentId: state.pathParameters['assignmentId'],
              assignment: testAssignment,
            ),
          ),
          GoRoute(
            path: '/parent/classes/program',
            name: AppRouteNames.currentProgram,
            builder: (context, state) => const CurrentProgramScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      // 1. Verify on AssignmentSubmittedScreen
      expect(find.text('Assignment Submitted'), findsOneWidget);
      expect(find.byKey(const Key('view_class_details_link')), findsOneWidget);
      expect(find.byKey(const Key('back_to_learning_button')), findsOneWidget);

      // 2. FLOW 1: Tap "View Class Details ->" => Navigates to Active Track (CurrentProgramScreen)
      await tester.ensureVisible(
        find.byKey(const Key('view_class_details_link')),
      );
      await tester.tap(find.byKey(const Key('view_class_details_link')));
      await tester.pumpAndSettle();

      // Verify arrived on CurrentProgramScreen (Active Track)
      expect(
        find.byKey(const Key('current_program_back_button')),
        findsOneWidget,
      );
      expect(find.text('Skills in Focus'), findsOneWidget);

      // 3. Back Navigation: Tapping top back button returns to AssignmentSubmittedScreen
      await tester.tap(find.byKey(const Key('current_program_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Assignment Submitted'), findsOneWidget);

      // 4. FLOW 2: Tap "BACK TO LEARNING" => Navigates directly to Parent Dashboard
      await tester.ensureVisible(
        find.byKey(const Key('back_to_learning_button')),
      );
      await tester.tap(find.byKey(const Key('back_to_learning_button')));
      await tester.pumpAndSettle();

      expect(find.text('Parent Dashboard Screen'), findsOneWidget);
      expect(find.text('Assignment Submitted'), findsNothing);
    },
  );
}
