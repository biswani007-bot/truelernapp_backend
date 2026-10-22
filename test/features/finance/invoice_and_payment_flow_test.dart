import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

class MockFinanceRepository implements FinanceRepository {
  List<InvoiceEntity> mockInvoices = [];
  FinanceOverviewEntity mockOverview = const FinanceOverviewEntity(
    totalInvoiced: 1500.0,
    totalPaid: 500.0,
    totalDue: 1000.0,
  );
  PaymentRecordEntity? lastPayment;
  bool shouldFailPayment = false;

  @override
  Future<({
    FinanceOverviewEntity overview,
    List<InvoiceEntity> invoices,
    List<PaymentRecordEntity> payments,
  })> getChildFinance(String studentId, {String? studentName}) async {
    return (
      overview: mockOverview,
      invoices: mockInvoices.where((i) => i.studentId == studentId).toList(),
      payments: lastPayment != null ? [lastPayment!] : <PaymentRecordEntity>[],
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
      overview: mockOverview,
      invoices: mockInvoices,
    );
  }

  @override
  Future<InvoiceEntity?> getInvoiceDetail(
    String invoiceId, {
    String? studentId,
  }) async {
    return mockInvoices.where((i) => i.id == invoiceId).firstOrNull;
  }

  @override
  Future<PaymentRecordEntity> payInvoice({
    required String studentId,
    required String invoiceId,
    String? paymentMethod,
  }) async {
    if (shouldFailPayment) {
      throw Exception('Payment processing failed: insufficient funds');
    }
    final payment = PaymentRecordEntity(
      id: 'PMT-998877',
      paymentNumber: 'REC-2026-001',
      paymentDate: DateTime.now(),
      amount: 1000.0,
      paymentMethod: paymentMethod ?? 'online-gateway',
      transactionReference: 'TXN-ABC-12345',
      status: 'success',
    );
    lastPayment = payment;
    return payment;
  }

  @override
  Future<StripeCheckoutSessionEntity> createStripeCheckoutSession({
    required String invoiceId,
    required String studentId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    return StripeCheckoutSessionEntity(
      sessionId: 'cs_test_mock_123',
      url: 'https://checkout.stripe.com/c/pay/cs_test_mock_123',
    );
  }

  @override
  Future<InvoiceEntity> verifyInvoiceStatus(String invoiceId) async {
    final inv = mockInvoices.where((i) => i.id == invoiceId).firstOrNull;
    if (inv != null) return inv;
    throw Exception('Invoice not found');
  }

  @override
  Future<List<ReceiptEntity>> getReceipts({int limit = 10}) async {
    return <ReceiptEntity>[];
  }

  @override
  Future<List<PaymentRecordEntity>> getPayments({int limit = 10}) async {
    return lastPayment != null ? [lastPayment!] : <PaymentRecordEntity>[];
  }

  @override
  Future<void> refreshEnrollments({int limit = 10}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testInvoiceJson = {
    'id': 'INV-1001',
    'invoiceNumber': 'INV-2026-0001',
    'issueDate': '2026-10-15T10:00:00.000Z',
    'dueDate': '2026-10-25T10:00:00.000Z',
    'baseAmount': 100000,
    'taxAmount': 18000,
    'discountAmount': 5000,
    'scholarshipAmount': 0,
    'totalAmount': 113000,
    'amountPaid': 0,
    'amountDue': 113000,
    'status': 'unpaid',
    'courseName': 'Robotics Level 1',
    'courseCode': 'ROB-101',
    'studentId': 'child-01',
    'studentName': 'Alex Smith',
    'items': [
      {
        'description': 'Robotics Kit & Tuition',
        'amount': 100000,
        'quantity': 1,
      }
    ],
  };

  group('InvoiceEntity Deserialization and Calculations', () {
    test('Correctly parses API response into InvoiceEntity', () {
      final invoice = InvoiceEntity.fromJson(testInvoiceJson);

      expect(invoice.id, 'INV-1001');
      expect(invoice.invoiceNumber, 'INV-2026-0001');
      expect(invoice.totalAmount, 1130.0);
      expect(invoice.amountDue, 1130.0);
      expect(invoice.amountPaid, 0.0);
      expect(invoice.isDue, isTrue);
      expect(invoice.isPaid, isFalse);
      expect(invoice.items.length, 1);
      expect(invoice.items.first.description, 'Robotics Kit & Tuition');
      expect(invoice.items.first.amount, 1000.0);
    });

    test('Correctly parses and formats INV-000036 from server minor units to web-equivalent major units', () {
      final inv36Json = {
        'id': '6ad52bed59fc8560344d91c9',
        'invoiceNumber': 'INV-000036',
        'issueDate': '2026-10-19T00:00:00.000Z',
        'dueDate': '2026-11-02T00:00:00.000Z',
        'baseAmount': 2290000,
        'taxAmount': 229000,
        'discountAmount': 0,
        'scholarshipAmount': 0,
        'totalAmount': 2519000,
        'amountPaid': 0,
        'amountDue': 2519000,
        'status': 'issued',
        'currency': 'USD',
        'courseName': 'Emotional Intelligence',
        'studentId': '6ad5215f59fc8560344d89fe',
        'studentName': 'Tarun Sahoo',
      };

      final invoice = InvoiceEntity.fromJson(inv36Json);

      expect(invoice.baseAmount, 22900.0);
      expect(invoice.taxAmount, 2290.0);
      expect(invoice.totalAmount, 25190.0);
      expect(invoice.amountDue, 25190.0);
      expect(invoice.baseAmount + invoice.taxAmount, invoice.totalAmount);
      expect(invoice.formattedBase, '\$22,900.00');
      expect(invoice.formattedTax, '\$2,290.00');
      expect(invoice.formattedTotal, '\$25,190.00');
      expect(invoice.formattedDue, '\$25,190.00');
      expect(invoice.currencySymbol, '\$');
    });

    test('Identifies paid and settled invoices properly', () {
      final paidInvoiceJson = Map<String, dynamic>.from(testInvoiceJson);
      paidInvoiceJson['status'] = 'paid';
      paidInvoiceJson['amountPaid'] = 113000;
      paidInvoiceJson['amountDue'] = 0;

      final invoice = InvoiceEntity.fromJson(paidInvoiceJson);
      expect(invoice.isPaid, isTrue);
      expect(invoice.isDue, isFalse);
    });
  });

  group('FinanceController State Management and Payment Flow', () {
    late MockFinanceRepository mockRepo;
    late ProviderContainer container;

    const child1 = ChildEntity(
      studentId: 'child-01',
      firstName: 'Alex',
      lastName: 'Smith',
    );
    const child2 = ChildEntity(
      studentId: 'child-02',
      firstName: 'Emma',
      lastName: 'Smith',
    );

    setUp(() {
      mockRepo = MockFinanceRepository();
      mockRepo.mockInvoices = [
        InvoiceEntity.fromJson(testInvoiceJson),
        InvoiceEntity.fromJson({
          ...testInvoiceJson,
          'id': 'INV-1002',
          'invoiceNumber': 'INV-2026-0002',
          'studentId': 'child-02',
          'studentName': 'Emma Smith',
          'status': 'paid',
          'amountPaid': 50000,
          'amountDue': 0,
        }),
      ];

      container = ProviderContainer(
        overrides: [
          financeRepositoryProvider.overrideWithValue(mockRepo),
          childrenControllerProvider.overrideWith(
            () => _FakeChildrenController(
              const ChildrenLoaded(
                children: [child1, child2],
                activeChildId: 'child-01',
              ),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loadFinance loads aggregated invoices for all children', () async {
      final controller = container.read(financeControllerProvider.notifier);
      await controller.loadFinance();

      final state = container.read(financeControllerProvider);
      expect(state, isA<FinanceLoaded>());

      final loaded = state as FinanceLoaded;
      expect(loaded.invoices.length, 2);
      expect(loaded.overview.totalInvoiced, 1500.0);
      expect(loaded.selectedChildId, isNull);
    });

    test('selectChildFilter filters invoices by childId', () async {
      final controller = container.read(financeControllerProvider.notifier);
      await controller.loadFinance();

      controller.selectChildFilter('child-01');
      var state = container.read(financeControllerProvider) as FinanceLoaded;
      expect(state.filteredInvoices.length, 1);
      expect(state.filteredInvoices.first.studentId, 'child-01');

      controller.selectChildFilter('child-02');
      state = container.read(financeControllerProvider) as FinanceLoaded;
      expect(state.filteredInvoices.length, 1);
      expect(state.filteredInvoices.first.studentId, 'child-02');

      controller.selectChildFilter(null);
      state = container.read(financeControllerProvider) as FinanceLoaded;
      expect(state.filteredInvoices.length, 2);
    });

    test('processPayment successfully executes payment and records transaction', () async {
      final controller = container.read(financeControllerProvider.notifier);
      await controller.loadFinance();

      final invoiceToPay = InvoiceEntity.fromJson(testInvoiceJson);
      final payment = await controller.processPayment(invoiceToPay);

      expect(payment, isNotNull);
      expect(payment!.transactionReference, 'TXN-ABC-12345');
      expect(payment.amount, 1000.0);

      final state = container.read(financeControllerProvider) as FinanceLoaded;
      expect(state.isPaying, isFalse);
      expect(state.payError, isNull);
    });

    test('processPayment records error on failure', () async {
      mockRepo.shouldFailPayment = true;
      final controller = container.read(financeControllerProvider.notifier);
      await controller.loadFinance();

      final invoiceToPay = InvoiceEntity.fromJson(testInvoiceJson);
      await expectLater(
        () => controller.processPayment(invoiceToPay),
        throwsA(isA<Exception>()),
      );

      final state = container.read(financeControllerProvider) as FinanceLoaded;
      expect(state.isPaying, isFalse);
      expect(state.payError, contains('insufficient funds'));
    });
  });
}
