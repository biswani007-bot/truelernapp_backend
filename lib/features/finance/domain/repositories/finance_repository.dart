import '../entities/invoice_entity.dart';
import '../entities/stripe_checkout_entity.dart';

/// Contract for finance and invoice operations.
abstract interface class FinanceRepository {
  /// Fetches financial overview, invoices, and payments for a specific student.
  Future<({
    FinanceOverviewEntity overview,
    List<InvoiceEntity> invoices,
    List<PaymentRecordEntity> payments,
  })> getChildFinance(String studentId, {String? studentName});

  /// Aggregates invoices across multiple linked children.
  Future<({
    FinanceOverviewEntity overview,
    List<InvoiceEntity> invoices,
  })> getAllChildrenFinance(
    List<({String studentId, String studentName})> children,
  );

  /// Retrieves full detail for a specific invoice.
  Future<InvoiceEntity?> getInvoiceDetail(
    String invoiceId, {
    String? studentId,
  });

  /// Initiates payment for a valid unpaid invoice (legacy / mock).
  Future<PaymentRecordEntity> payInvoice({
    required String studentId,
    required String invoiceId,
    String? paymentMethod,
  });

  /// Creates an authoritative Stripe Checkout Session on the backend.
  /// POST /api/finance/stripe/create-checkout
  Future<StripeCheckoutSessionEntity> createStripeCheckoutSession({
    required String invoiceId,
    required String studentId,
    required String successUrl,
    required String cancelUrl,
  });

  /// Authoritatively retrieves the latest invoice status from the backend.
  /// GET /api/finance/invoices/{invoiceId}
  Future<InvoiceEntity> verifyInvoiceStatus(String invoiceId);

  /// Fetches receipts list.
  /// GET /api/finance/receipts?limit=10
  Future<List<ReceiptEntity>> getReceipts({int limit = 10});

  /// Fetches payment history list.
  /// GET /api/finance/payments?limit=10
  Future<List<PaymentRecordEntity>> getPayments({int limit = 10});

  /// Refreshes active enrollments from the backend.
  /// GET /api/enrollments?limit=10
  Future<void> refreshEnrollments({int limit = 10});
}
