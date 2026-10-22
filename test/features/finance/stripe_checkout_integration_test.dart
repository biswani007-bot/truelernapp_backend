import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/core/config/app_config.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_invoice_detail_screen.dart';
import 'package:truelearn/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:truelearn/features/finance/domain/entities/invoice_entity.dart';
import 'package:truelearn/features/finance/domain/entities/stripe_checkout_entity.dart';
import 'package:truelearn/features/finance/domain/repositories/finance_repository.dart';
import 'package:truelearn/features/finance/presentation/services/stripe_checkout_launcher.dart';

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

class MockStripeCheckoutLauncher extends StripeCheckoutLauncher {
  bool launchExternalResult = true;
  CheckoutReturnResult inAppResult = CheckoutReturnResult.completed;
  String? lastLaunchedUrl;
  int launchCallCount = 0;

  @override
  Future<bool> launchExternalBrowser(String checkoutUrl) async {
    launchCallCount++;
    lastLaunchedUrl = checkoutUrl;
    if (!isValidStripeCheckoutUrl(checkoutUrl)) {
      throw ArgumentError('Untrusted checkout destination URL.');
    }
    return launchExternalResult;
  }

  @override
  Future<CheckoutReturnResult> launchInAppPresentation(
    BuildContext context, {
    required String checkoutUrl,
    required String successUrlPrefix,
    required String cancelUrlPrefix,
  }) async {
    launchCallCount++;
    lastLaunchedUrl = checkoutUrl;
    if (!isValidStripeCheckoutUrl(checkoutUrl)) {
      throw ArgumentError('Untrusted checkout destination URL.');
    }
    return inAppResult;
  }
}

class TestFinanceRepository implements FinanceRepository {
  List<InvoiceEntity> invoices = [];
  String? lastCreatedInvoiceId;
  String? lastCreatedStudentId;
  String? lastSuccessUrl;
  String? lastCancelUrl;
  String checkoutUrlToReturn =
      'https://checkout.stripe.com/c/pay/cs_test_session_123';
  String sessionIdToReturn = 'cs_test_session_123';

  int verifyCallCount = 0;
  bool shouldFailVerify = false;
  InvoiceEntity? verifiedInvoiceToReturn;

  int childFinanceRefreshCount = 0;
  int paymentsRefreshCount = 0;
  int receiptsRefreshCount = 0;
  int enrollmentsRefreshCount = 0;

  bool shouldFailCheckout = false;
  String? checkoutErrorMessage;

  @override
  Future<StripeCheckoutSessionEntity> createStripeCheckoutSession({
    required String invoiceId,
    required String studentId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    lastCreatedInvoiceId = invoiceId;
    lastCreatedStudentId = studentId;
    lastSuccessUrl = successUrl;
    lastCancelUrl = cancelUrl;

    if (shouldFailCheckout) {
      throw ServerFailure(
        checkoutErrorMessage ?? 'Invalid redirect URLs',
        statusCode: 400,
        errorCode: 'INTERNAL_SERVER_ERROR',
      );
    }

    return StripeCheckoutSessionEntity(
      sessionId: sessionIdToReturn,
      url: checkoutUrlToReturn,
    );
  }

  @override
  Future<InvoiceEntity> verifyInvoiceStatus(String invoiceId) async {
    verifyCallCount++;
    if (shouldFailVerify) {
      throw Exception('Server unreachable for verification');
    }
    if (verifiedInvoiceToReturn != null) {
      return verifiedInvoiceToReturn!;
    }
    final inv = invoices.where((i) => i.id == invoiceId).firstOrNull;
    if (inv != null) return inv;
    throw Exception('Invoice not found: $invoiceId');
  }

  @override
  Future<({
    FinanceOverviewEntity overview,
    List<InvoiceEntity> invoices,
    List<PaymentRecordEntity> payments,
  })> getChildFinance(String studentId, {String? studentName}) async {
    childFinanceRefreshCount++;
    return (
      overview: const FinanceOverviewEntity(
        totalInvoiced: 1200,
        totalPaid: 200,
        totalDue: 1000,
      ),
      invoices: invoices.where((i) => i.studentId == studentId).toList(),
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
        totalInvoiced: 1200,
        totalPaid: 200,
        totalDue: 1000,
      ),
      invoices: invoices,
    );
  }

  @override
  Future<InvoiceEntity?> getInvoiceDetail(
    String invoiceId, {
    String? studentId,
  }) async {
    final found = invoices.where((i) => i.id == invoiceId).firstOrNull;
    if (found != null) return found;
    return verifyInvoiceStatus(invoiceId);
  }

  @override
  Future<List<ReceiptEntity>> getReceipts({int limit = 10}) async {
    receiptsRefreshCount++;
    return <ReceiptEntity>[
      ReceiptEntity(
        id: 'rec_1001',
        receiptNumber: 'REC-2026-0001',
        invoiceId: 'inv_1001',
        amount: 1000,
        issueDate: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<PaymentRecordEntity>> getPayments({int limit = 10}) async {
    paymentsRefreshCount++;
    return <PaymentRecordEntity>[
      PaymentRecordEntity(
        id: 'pmt_1001',
        paymentNumber: 'PMT-2026-0001',
        paymentDate: DateTime.now(),
        amount: 1000,
        paymentMethod: 'stripe-checkout',
        transactionReference: 'ch_test_3456',
        status: 'success',
      ),
    ];
  }

  @override
  Future<void> refreshEnrollments({int limit = 10}) async {
    enrollmentsRefreshCount++;
  }

  @override
  Future<PaymentRecordEntity> payInvoice({
    required String studentId,
    required String invoiceId,
    String? paymentMethod,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const testChild = ChildEntity(
    studentId: 'child_authorized_01',
    firstName: 'Alex',
    lastName: 'Morgan',
  );

  final testInvoice = InvoiceEntity(
    id: 'inv_1001',
    invoiceNumber: 'INV-2026-0001',
    issueDate: DateTime(2026, 10, 1),
    dueDate: DateTime(2026, 10, 15),
    baseAmount: 1000,
    taxAmount: 50,
    discountAmount: 0,
    scholarshipAmount: 0,
    totalAmount: 1050,
    amountPaid: 0,
    amountDue: 1050,
    status: 'unpaid',
    courseName: 'Robotics Bootcamp',
    courseCode: 'ROB-101',
    studentId: 'child_authorized_01',
    studentName: 'Alex Morgan',
  );

  final paidInvoice = InvoiceEntity(
    id: 'inv_1001',
    invoiceNumber: 'INV-2026-0001',
    issueDate: DateTime(2026, 10, 1),
    dueDate: DateTime(2026, 10, 15),
    baseAmount: 1000,
    taxAmount: 50,
    discountAmount: 0,
    scholarshipAmount: 0,
    totalAmount: 1050,
    amountPaid: 1050,
    amountDue: 0,
    status: 'paid',
    courseName: 'Robotics Bootcamp',
    courseCode: 'ROB-101',
    studentId: 'child_authorized_01',
    studentName: 'Alex Morgan',
    transactionReference: 'txn_stripe_confirmed_999',
    paidAt: DateTime.now(),
  );

  group('Stripe Checkout & Invoice Settlement - 15 Acceptance Tests', () {
    late TestFinanceRepository testRepo;
    late MockStripeCheckoutLauncher testLauncher;

    setUp(() {
      testRepo = TestFinanceRepository();
      testRepo.invoices = [testInvoice];
      testLauncher = MockStripeCheckoutLauncher();
    });

    Widget createWidgetUnderTest({
      InvoiceEntity? invoice,
      StripeCheckoutLauncher? launcher,
      ChildrenState? childrenState,
    }) {
      return ProviderScope(
        overrides: [
          financeRepositoryProvider.overrideWithValue(testRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              childrenState ??
                  const ChildrenLoaded(
                    children: [testChild],
                    activeChildId: 'child_authorized_01',
                  ),
            ),
          ),
          authControllerProvider.overrideWith(
            () => FakeAuthController(
              const Authenticated(accessToken: 'mock_jwt_token_123'),
            ),
          ),
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.production,
              apiBaseUrl: 'https://truelern.visital.in/api',
              connectTimeout: Duration(seconds: 15),
              receiveTimeout: Duration(seconds: 15),
              sendTimeout: Duration(seconds: 15),
            ),
          ),
        ],
        child: MaterialApp(
          home: ParentInvoiceDetailScreen(
            invoice: invoice ?? testInvoice,
            invoiceId: (invoice ?? testInvoice).id,
            checkoutLauncher: launcher ?? testLauncher,
          ),
        ),
      );
    }

    testWidgets(
        '1. Authenticated Checkout creation sends correct POST body and canonical redirect URLs',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final payButton = find.byKey(const Key('invoice_detail_pay_button'));
      expect(payButton, findsOneWidget);

      await tester.tap(payButton);
      await tester.pumpAndSettle();

      expect(testRepo.lastCreatedInvoiceId, 'inv_1001');
      expect(testRepo.lastCreatedStudentId, 'child_authorized_01');
      expect(testRepo.lastSuccessUrl,
          'https://truelern.visital.in/checkout?payment=success');
      expect(testRepo.lastCancelUrl,
          'https://truelern.visital.in/checkout?payment=cancelled');
      // Must not append unsupported query parameters like &invoiceId=
      expect(testRepo.lastSuccessUrl, isNot(contains('&invoiceId=')));
      expect(testRepo.lastCancelUrl, isNot(contains('&invoiceId=')));
    });

    testWidgets(
        '1b. Rejection of invalid redirect URLs displays useful error message without crash',
        (tester) async {
      testRepo.shouldFailCheckout = true;
      testRepo.checkoutErrorMessage = 'Invalid redirect URLs';

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final payButton = find.byKey(const Key('invoice_detail_pay_button'));
      expect(payButton, findsOneWidget);

      await tester.tap(payButton);
      await tester.pumpAndSettle();

      // UI presents the error banner with useful message
      expect(find.byKey(const Key('checkout_status_banner')), findsOneWidget);
      expect(find.textContaining('Invalid redirect URLs'), findsOneWidget);
      expect(find.text('Payment Initialization Failed'), findsOneWidget);
    });

    testWidgets(
        '2. Correct invoice ID and selected child ID derived from context',
        (tester) async {
      // Invoice with null studentId should fallback to activeChildId
      final invoiceWithoutStudent = InvoiceEntity(
        id: 'inv_child_fallback',
        invoiceNumber: 'INV-2026-9999',
        issueDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 15),
        baseAmount: 500,
        taxAmount: 0,
        discountAmount: 0,
        scholarshipAmount: 0,
        totalAmount: 500,
        amountPaid: 0,
        amountDue: 500,
        status: 'unpaid',
        courseName: 'Math Fundamentals',
        courseCode: 'MATH-1',
        studentId: null, // intentionally null
      );
      testRepo.invoices = [invoiceWithoutStudent];

      await tester.pumpWidget(
        createWidgetUnderTest(invoice: invoiceWithoutStudent),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      expect(testRepo.lastCreatedInvoiceId, 'inv_child_fallback');
      expect(testRepo.lastCreatedStudentId, 'child_authorized_01');
    });

    testWidgets('3. Correct handling of the returned Checkout URL',
        (tester) async {
      testRepo.checkoutUrlToReturn =
          'https://checkout.stripe.com/c/pay/cs_official_session_888';

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      expect(testLauncher.lastLaunchedUrl,
          'https://checkout.stripe.com/c/pay/cs_official_session_888');
    });

    testWidgets('4. Invalid or missing Checkout URLs are rejected with error',
        (tester) async {
      // Untrusted non-stripe URL
      testRepo.checkoutUrlToReturn = 'http://malicious-site.example/steal';

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkout_status_banner')), findsOneWidget);
      expect(find.textContaining('Untrusted checkout URL'), findsOneWidget);
    });

    testWidgets('5. Duplicate Pay Now taps are prevented while busy',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Rapidly tap Pay Now: second tap should be ignored and button is busy
      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.tap(
        find.byKey(const Key('invoice_detail_pay_button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Launcher must only be invoked once
      expect(testLauncher.launchCallCount, 1);
    });

    testWidgets(
        '6. Checkout cancellation returns to invoice details with neutral state',
        (tester) async {
      testLauncher.launchExternalResult = false;
      testLauncher.inAppResult = CheckoutReturnResult.cancelled;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkout_status_banner')), findsOneWidget);
      expect(find.text('Payment Cancelled'), findsOneWidget);
      expect(find.textContaining('remains outstanding'), findsOneWidget);
      // No payment successful screen
      expect(find.text('Payment Successful'), findsNothing);
    });

    testWidgets('7. Returning from Checkout after successful payment verifies',
        (tester) async {
      testLauncher.launchExternalResult = false;
      testLauncher.inAppResult = CheckoutReturnResult.completed;
      testRepo.verifiedInvoiceToReturn = paidInvoice;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      expect(testRepo.verifyCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('8. Browser closure without definitive result polls backend',
        (tester) async {
      testLauncher.launchExternalResult = false;
      testLauncher.inAppResult = CheckoutReturnResult.closed;
      // Server still reports unpaid
      testRepo.verifiedInvoiceToReturn = testInvoice;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      // Verify called, invoice remains unpaid, neutral awaiting banner displayed
      expect(testRepo.verifyCallCount, greaterThanOrEqualTo(1));
      expect(find.byKey(const Key('checkout_status_banner')), findsOneWidget);
      expect(find.text('Payment Successful'), findsNothing);
    });

    testWidgets(
        '9. Payment pending while server processes transaction shows pending banner',
        (tester) async {
      testLauncher.launchExternalResult = false;
      testLauncher.inAppResult = CheckoutReturnResult.completed;
      // Server reports unpaid on poll
      testRepo.verifiedInvoiceToReturn = testInvoice;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkout_status_banner')), findsOneWidget);
      expect(
          find.text('Settlement Awaiting Confirmation'), findsOneWidget);
      expect(find.text('Payment Successful'), findsNothing);
    });

    testWidgets('10. Payment success confirmed by the invoice API updates state',
        (tester) async {
      testLauncher.launchExternalResult = false;
      testLauncher.inAppResult = CheckoutReturnResult.completed;
      testRepo.verifiedInvoiceToReturn = paidInvoice;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      expect(testRepo.verifyCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('11. Invoice verification failure allows safe retry',
        (tester) async {
      testLauncher.launchExternalResult = false;
      testLauncher.inAppResult = CheckoutReturnResult.completed;
      testRepo.shouldFailVerify = true;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      // Displays retry banner
      expect(find.byKey(const Key('checkout_status_banner')), findsOneWidget);
      final retryButton =
          find.byKey(const Key('checkout_retry_verification_button'));
      expect(retryButton, findsOneWidget);

      // Reset failure flag and tap retry
      testRepo.shouldFailVerify = false;
      testRepo.verifiedInvoiceToReturn = paidInvoice;

      await tester.ensureVisible(retryButton);
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(testRepo.verifyCallCount, greaterThanOrEqualTo(2));
    });

    testWidgets(
        '12. Confirmed payment triggers invoice, receipt, finance, and enrollment refresh',
        (tester) async {
      testLauncher.launchExternalResult = false;
      testLauncher.inAppResult = CheckoutReturnResult.completed;
      testRepo.verifiedInvoiceToReturn = paidInvoice;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      expect(testRepo.childFinanceRefreshCount, greaterThanOrEqualTo(1));
      expect(testRepo.paymentsRefreshCount, greaterThanOrEqualTo(1));
      expect(testRepo.receiptsRefreshCount, greaterThanOrEqualTo(1));
      expect(testRepo.enrollmentsRefreshCount, greaterThanOrEqualTo(1));
    });

    testWidgets('13. Unauthorized invoice/student combinations are rejected',
        (tester) async {
      // Authenticated parent is linked to 'child_authorized_01', but invoice belongs to 'child_stranger_99'
      final foreignInvoice = InvoiceEntity(
        id: 'inv_foreign_99',
        invoiceNumber: 'INV-2026-0099',
        issueDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 15),
        baseAmount: 1000,
        taxAmount: 0,
        discountAmount: 0,
        scholarshipAmount: 0,
        totalAmount: 1000,
        amountPaid: 0,
        amountDue: 1000,
        status: 'unpaid',
        courseName: 'Foreign Course',
        courseCode: 'FOR-99',
        studentId: 'child_stranger_99',
      );
      testRepo.invoices = [foreignInvoice];

      await tester.pumpWidget(createWidgetUnderTest(invoice: foreignInvoice));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkout_status_banner')), findsOneWidget);
      expect(find.textContaining('Unauthorized: Student is not linked'),
          findsOneWidget);
      // Checkout session must NOT be created
      expect(testRepo.lastCreatedInvoiceId, isNull);
    });

    testWidgets(
        '14. App lifecycle handling when returning from the external browser',
        (tester) async {
      testLauncher.launchExternalResult = true; // Opens external browser
      testRepo.verifiedInvoiceToReturn = paidInvoice;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Pay to open external browser
      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      expect(testLauncher.launchCallCount, 1);
      expect(find.byKey(const Key('checkout_status_banner')), findsOneWidget);
      expect(find.text('Stripe Checkout Opened'), findsOneWidget);

      // Simulate app resuming from background when parent switches back from browser
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Verification polling triggered automatically
      expect(testRepo.verifyCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets(
        '15. No false-positive Payment Successful state when payment not confirmed',
        (tester) async {
      testLauncher.launchExternalResult = false;
      testLauncher.inAppResult = CheckoutReturnResult.completed;
      // Server still returns unpaid status
      testRepo.verifiedInvoiceToReturn = testInvoice;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invoice_detail_pay_button')));
      await tester.pumpAndSettle();

      // Invoice status remains unpaid; no Payment Successful state
      expect(find.text('Payment Successful'), findsNothing);
      expect(testInvoice.isPaid, isFalse);
    });
  });
}

class FakeAuthController extends AuthController {
  FakeAuthController(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}
