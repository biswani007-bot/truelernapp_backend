import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/core/router/app_router.dart';
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/models/password_prompt_status.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:truelearn/features/finance/domain/entities/invoice_entity.dart';
import 'package:truelearn/features/finance/domain/entities/stripe_checkout_entity.dart';
import 'package:truelearn/features/finance/domain/repositories/finance_repository.dart';
import 'package:truelearn/features/finance/presentation/controllers/finance_controller.dart';

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

class FakeAuthRepo implements AuthRepository {
  @override
  Future<String?> checkPersistedSession() async => 'test_token';

  @override
  Future<AuthResponse> login(LoginRequest request) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponse> signInWithGoogle(String idToken) async =>
      throw UnimplementedError();

  @override
  Future<PasswordPromptStatus> getPasswordPromptStatus() async =>
      const PasswordPromptStatus(
        showPrompt: false,
        hasPassword: true,
        dontAskAgain: false,
        cooldownActive: false,
      );

  @override
  Future<bool> setupPassword({
    required String password,
    required String confirmPassword,
  }) async => true;

  @override
  Future<bool> dismissPasswordPrompt({required String action}) async => true;

  @override
  Future<Map<String, dynamic>> getCurrentParentContext() async => {
        'data': {
          'user': {'role': 'parent', 'id': 'parent-123', 'name': 'John Doe'},
        },
      };

  @override
  Future<Map<String, dynamic>?> getParentDemo({String? studentId}) async => null;

  @override
  Future<Map<String, dynamic>?> getParentStatus({String? studentId}) async => null;

  @override
  Future<Map<String, dynamic>?> getChildDashboard(String childStudentId) async => null;

  @override
  Future<void> logout() async {}
}

class FakeFinanceRepo implements FinanceRepository {
  List<InvoiceEntity> invoices;
  FakeFinanceRepo(this.invoices);

  @override
  Future<({
    FinanceOverviewEntity overview,
    List<InvoiceEntity> invoices,
    List<PaymentRecordEntity> payments,
  })> getChildFinance(String studentId, {String? studentName}) async {
    return (
      overview: const FinanceOverviewEntity(
        totalInvoiced: 2500,
        totalPaid: 500,
        totalDue: 2000,
      ),
      invoices: invoices,
      payments: <PaymentRecordEntity>[],
    );
  }

  @override
  Future<({
    FinanceOverviewEntity overview,
    List<InvoiceEntity> invoices,
  })> getAllChildrenFinance(
    List<({String studentId, String studentName})> children,
  ) async {
    return (
      overview: const FinanceOverviewEntity(
        totalInvoiced: 2500,
        totalPaid: 500,
        totalDue: 2000,
      ),
      invoices: invoices,
    );
  }

  @override
  Future<InvoiceEntity?> getInvoiceDetail(
    String invoiceId, {
    String? studentId,
  }) async {
    return invoices.where((i) => i.id == invoiceId).firstOrNull;
  }

  @override
  Future<PaymentRecordEntity> payInvoice({
    required String studentId,
    required String invoiceId,
    String? paymentMethod,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StripeCheckoutSessionEntity> createStripeCheckoutSession({
    required String invoiceId,
    required String studentId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    return StripeCheckoutSessionEntity(
      sessionId: 'cs_fake_123',
      url: 'https://checkout.stripe.com/c/pay/cs_fake_123',
    );
  }

  @override
  Future<InvoiceEntity> verifyInvoiceStatus(String invoiceId) async {
    final inv = invoices.where((i) => i.id == invoiceId).firstOrNull;
    if (inv != null) return inv;
    throw Exception('Invoice not found: $invoiceId');
  }

  @override
  Future<List<ReceiptEntity>> getReceipts({int limit = 10}) async {
    return <ReceiptEntity>[];
  }

  @override
  Future<List<PaymentRecordEntity>> getPayments({int limit = 10}) async {
    return <PaymentRecordEntity>[];
  }

  @override
  Future<void> refreshEnrollments({int limit = 10}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const testChild = ChildEntity(
    studentId: 'child-01',
    firstName: 'Tommy',
    lastName: 'Jenkins',
  );

  final testInvoice1 = InvoiceEntity(
    id: 'INV-001',
    invoiceNumber: 'INV-2026-0001',
    issueDate: DateTime(2026, 10, 15),
    dueDate: DateTime(2026, 10, 25),
    baseAmount: 1000,
    taxAmount: 180,
    discountAmount: 50,
    scholarshipAmount: 0,
    totalAmount: 1130,
    amountPaid: 0,
    amountDue: 1130,
    status: 'unpaid',
    courseName: 'Junior Foundation',
    courseCode: 'JF-101',
    studentId: 'child-01',
    studentName: 'Tommy Jenkins',
  );

  final testInvoice2 = InvoiceEntity(
    id: 'INV-002',
    invoiceNumber: 'INV-2026-0002',
    issueDate: DateTime(2026, 10, 10),
    dueDate: DateTime(2026, 10, 20),
    baseAmount: 800,
    taxAmount: 144,
    discountAmount: 0,
    scholarshipAmount: 0,
    totalAmount: 944,
    amountPaid: 944,
    amountDue: 0,
    status: 'paid',
    courseName: 'Public Speaking Masters',
    courseCode: 'PS-201',
    studentId: 'child-01',
    studentName: 'Tommy Jenkins',
  );

  Widget createSubject(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          return MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
          );
        },
      ),
    );
  }

  group('Invoice Navigation & Route Key Verification', () {
    testWidgets('1. Opening Invoice Detail from the Invoices screen works cleanly',
        (tester) async {
      final fakeFinanceRepo = FakeFinanceRepo([testInvoice1]);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepo()),
          financeRepositoryProvider.overrideWithValue(fakeFinanceRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [testChild],
                activeChildId: 'child-01',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).checkSession();
      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      router.go(AppRoutePaths.parentInvoices);
      await tester.pumpAndSettle();

      expect(find.text('Invoice #INV-2026-0001'), findsOneWidget);

      final viewInvoiceBtn = find.byKey(const Key('view_invoice_INV-001'));
      expect(viewInvoiceBtn, findsOneWidget);

      await tester.tap(viewInvoiceBtn);
      await tester.pumpAndSettle();

      expect(find.text('Invoice Detail'), findsOneWidget);
      expect(find.text('INV-2026-0001'), findsOneWidget);
    });

    testWidgets('2. Opening different invoices consecutively updates detail view',
        (tester) async {
      final fakeFinanceRepo = FakeFinanceRepo([testInvoice1, testInvoice2]);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepo()),
          financeRepositoryProvider.overrideWithValue(fakeFinanceRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [testChild],
                activeChildId: 'child-01',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).checkSession();
      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      router.go(AppRoutePaths.parentInvoices);
      await tester.pumpAndSettle();

      // Open first invoice
      final btn1 = find.byKey(const Key('view_invoice_INV-001'));
      await tester.ensureVisible(btn1);
      await tester.tap(btn1);
      await tester.pumpAndSettle();

      expect(find.text('Invoice Detail'), findsOneWidget);
      expect(find.text('INV-2026-0001'), findsOneWidget);

      // Return back
      await tester.tap(find.byKey(const Key('invoice_detail_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invoices'), findsOneWidget);

      // Open second invoice
      final btn2 = find.byKey(const Key('view_invoice_INV-002'));
      await tester.ensureVisible(btn2);
      await tester.tap(btn2);
      await tester.pumpAndSettle();

      expect(find.text('Invoice Detail'), findsOneWidget);
      expect(find.text('INV-2026-0002'), findsOneWidget);
    });

    testWidgets('3. Rapidly tapping View Invoice is debounced without duplicate route push',
        (tester) async {
      final fakeFinanceRepo = FakeFinanceRepo([testInvoice1]);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepo()),
          financeRepositoryProvider.overrideWithValue(fakeFinanceRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [testChild],
                activeChildId: 'child-01',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).checkSession();
      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      router.go(AppRoutePaths.parentInvoices);
      await tester.pumpAndSettle();

      final viewInvoiceBtn = find.byKey(const Key('view_invoice_INV-001'));

      // Rapidly double tap
      await tester.tap(viewInvoiceBtn);
      await tester.tap(viewInvoiceBtn);
      await tester.pumpAndSettle();

      expect(find.text('Invoice Detail'), findsOneWidget);

      // Popping once returns directly to Invoices screen (proves duplicate route was not pushed)
      await tester.tap(find.byKey(const Key('invoice_detail_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invoices'), findsOneWidget);
    });

    testWidgets('4. Rebuilding Invoices screen while data loads is stable and preserves keys',
        (tester) async {
      final fakeFinanceRepo = FakeFinanceRepo([testInvoice1]);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepo()),
          financeRepositoryProvider.overrideWithValue(fakeFinanceRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [testChild],
                activeChildId: 'child-01',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).checkSession();
      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      router.go(AppRoutePaths.parentInvoices);
      await tester.pumpAndSettle();

      // Trigger loadFinance reload
      container.read(financeControllerProvider.notifier).loadFinance();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Invoice #INV-2026-0001'), findsOneWidget);
    });

    testWidgets('5. Returning from Invoice Detail to Invoices preserves back navigation',
        (tester) async {
      final fakeFinanceRepo = FakeFinanceRepo([testInvoice1]);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepo()),
          financeRepositoryProvider.overrideWithValue(fakeFinanceRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [testChild],
                activeChildId: 'child-01',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).checkSession();
      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      router.go(AppRoutePaths.parentInvoices);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('view_invoice_INV-001')));
      await tester.pumpAndSettle();

      expect(find.text('Invoice Detail'), findsOneWidget);

      // Back navigation via back button
      await tester.tap(find.byKey(const Key('invoice_detail_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invoices'), findsOneWidget);
    });

    testWidgets('6. Handling a failed or unknown invoice-detail request displays error fallback',
        (tester) async {
      final fakeFinanceRepo = FakeFinanceRepo([]);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepo()),
          financeRepositoryProvider.overrideWithValue(fakeFinanceRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [testChild],
                activeChildId: 'child-01',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).checkSession();
      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      // Ensure finance loaded state is established
      await container.read(financeControllerProvider.notifier).loadFinance();

      final router = container.read(routerProvider);
      router.go('/parent/invoices/NON-EXISTENT-INV');
      await tester.pumpAndSettle();

      expect(find.text('Invoice Not Found'), findsOneWidget);
      expect(find.text('Unable to retrieve the requested billing record.'), findsOneWidget);

      // Tap Return to Invoices
      await tester.tap(find.byKey(const Key('invoice_detail_return_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invoices'), findsOneWidget);
    });

    testWidgets('7. Invoice list keys remain unique even when duplicate IDs exist',
        (tester) async {
      // Create duplicate invoice with same ID
      final duplicateInvoice = InvoiceEntity(
        id: 'INV-001',
        invoiceNumber: 'INV-2026-0001-COPY',
        issueDate: DateTime(2026, 10, 15),
        dueDate: DateTime(2026, 10, 25),
        baseAmount: 1000,
        taxAmount: 180,
        discountAmount: 50,
        scholarshipAmount: 0,
        totalAmount: 1130,
        amountPaid: 0,
        amountDue: 1130,
        status: 'unpaid',
        courseName: 'Junior Foundation',
        courseCode: 'JF-101',
        studentId: 'child-01',
      );

      final fakeFinanceRepo = FakeFinanceRepo([testInvoice1, duplicateInvoice]);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepo()),
          financeRepositoryProvider.overrideWithValue(fakeFinanceRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [testChild],
                activeChildId: 'child-01',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).checkSession();
      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      router.go(AppRoutePaths.parentInvoices);
      await tester.pumpAndSettle();

      // Deduplication guarantees exactly one widget with key invoice_item_INV-001
      expect(find.byKey(const ValueKey('invoice_item_INV-001')), findsOneWidget);
    });

    testWidgets('8. No duplicate route is pushed by state changes on Invoices screen',
        (tester) async {
      final fakeFinanceRepo = FakeFinanceRepo([testInvoice1]);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepo()),
          financeRepositoryProvider.overrideWithValue(fakeFinanceRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [testChild],
                activeChildId: 'child-01',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).checkSession();
      await tester.pumpWidget(createSubject(container));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      router.go(AppRoutePaths.parentInvoices);
      await tester.pumpAndSettle();

      // Update state
      container.read(financeControllerProvider.notifier).selectChildFilter('child-01');
      await tester.pumpAndSettle();

      // Ensure user remains on Invoices and has not been pushed to another route
      expect(router.state.matchedLocation, AppRoutePaths.parentInvoices);
      expect(find.text('Invoices'), findsOneWidget);
    });
  });
}
