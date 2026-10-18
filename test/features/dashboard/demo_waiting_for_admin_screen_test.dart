import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_booking_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_waiting_for_admin_screen.dart';

class _FakeChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  _FakeChildrenController(this._initial);
  final ChildrenState _initial;

  @override
  ChildrenState build() => _initial;

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  Future<void> retry() async {}

  @override
  void setActiveChild(String studentId) {}

  @override
  void reset() {}
}

class MockAuthRepositoryWaitingTest implements AuthRepository {
  Map<String, dynamic>? statusResponse;

  @override
  Future<Map<String, dynamic>?> getParentStatus({String? studentId}) async {
    return statusResponse;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testChild = ChildEntity(
    studentId: 'STU-123456',
    firstName: 'ABANI PRASAD',
    lastName: 'TRIPATHY',
  );

  final testBooking = DemoBookingEntity(
    bookingId: 'DEMO-778899',
    demoCode: 'DEMO-778899',
    courseName: 'Junior Foundation',
    studentName: 'ABANI PRASAD TRIPATHY',
    studentId: 'STU-123456',
    startDateTime: DateTime(2026, 10, 16, 10, 0),
    endDateTime: DateTime(2026, 10, 16, 10, 45),
    status: 'completed',
    teacherName: 'Elizabeth Vance',
  );

  testWidgets(
      'DemoWaitingForAdminScreen displays course, student, booking ref, and review message',
      (tester) async {
    final mockAuthRepo = MockAuthRepositoryWaitingTest();
    mockAuthRepo.statusResponse = {
      'state': 'STATE_3',
      'action': 'awaiting_admin',
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [testChild],
                activeChildId: 'STU-123456',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: DemoWaitingForAdminScreen(booking: testBooking),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Waiting for Admin Enrollment'), findsOneWidget);

    // Verify Status badge
    expect(
      find.text('Demo Completed — Awaiting Review'),
      findsOneWidget,
    );

    // Verify Heading
    expect(find.text('Demo Session Completed'), findsOneWidget);

    // Verify Required Review message
    expect(
      find.textContaining('Your demo session has ended. Our academic team will review the session and update your enrollment status.'),
      findsOneWidget,
    );

    // Verify Details
    expect(find.text('Junior Foundation'), findsOneWidget);
    expect(find.text('ABANI PRASAD TRIPATHY'), findsOneWidget);
    expect(find.text('DEMO-778899'), findsOneWidget);

    // Verify Action button
    expect(find.byKey(const Key('waiting_admin_check_status_button')), findsOneWidget);
  });

  testWidgets(
      'DemoWaitingForAdminScreen updates to Approved & Invoice Ready when admin enrolls child',
      (tester) async {
    final mockAuthRepo = MockAuthRepositoryWaitingTest();
    // Simulate admin approved enrollment (STATE_4 with action 'payment')
    mockAuthRepo.statusResponse = {
      'state': 'STATE_4',
      'action': 'payment',
      'invoiceId': 'INV-998877',
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [testChild],
                activeChildId: 'STU-123456',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: DemoWaitingForAdminScreen(booking: testBooking),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Approved Status
    expect(
      find.text('Enrollment Approved — Invoice Ready'),
      findsOneWidget,
    );

    expect(find.text('Enrollment Approved!'), findsOneWidget);
    expect(
      find.textContaining('Your tuition invoice is now ready for payment'),
      findsOneWidget,
    );

    // Verify CTA button to view invoice
    expect(
      find.byKey(const Key('waiting_admin_view_invoice_button')),
      findsOneWidget,
    );
  });
}
