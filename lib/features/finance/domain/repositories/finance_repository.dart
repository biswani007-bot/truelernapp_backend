import '../entities/invoice_entity.dart';

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

  /// Initiates payment for a valid unpaid invoice.
  Future<PaymentRecordEntity> payInvoice({
    required String studentId,
    required String invoiceId,
    String? paymentMethod,
  });
}
