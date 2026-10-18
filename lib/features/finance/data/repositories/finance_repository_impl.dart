import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/finance_repository.dart';

/// Provider exposing [FinanceRepository].
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FinanceRepositoryImpl(apiClient: apiClient);
});

class FinanceRepositoryImpl implements FinanceRepository {
  const FinanceRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<({
    FinanceOverviewEntity overview,
    List<InvoiceEntity> invoices,
    List<PaymentRecordEntity> payments,
  })> getChildFinance(String studentId, {String? studentName}) async {
    final response = await apiClient.get<dynamic>(
      '/parent/children/$studentId/finance',
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final overviewMap = data['overview'] is Map<String, dynamic>
            ? data['overview'] as Map<String, dynamic>
            : <String, dynamic>{};
        final overview = FinanceOverviewEntity.fromJson(overviewMap);

        final invoicesList = <InvoiceEntity>[];
        final rawInvoices = data['invoices'];
        if (rawInvoices is List) {
          for (final item in rawInvoices) {
            if (item is Map<String, dynamic>) {
              invoicesList.add(
                InvoiceEntity.fromJson(
                  item,
                  fallbackStudentName: studentName,
                  fallbackStudentId: studentId,
                ),
              );
            }
          }
        }

        final paymentsList = <PaymentRecordEntity>[];
        final rawPayments = data['payments'];
        if (rawPayments is List) {
          for (final item in rawPayments) {
            if (item is Map<String, dynamic>) {
              paymentsList.add(PaymentRecordEntity.fromJson(item));
            }
          }
        }

        return (
          overview: overview,
          invoices: invoicesList,
          payments: paymentsList,
        );
      }
    }

    return (
      overview: FinanceOverviewEntity.zero,
      invoices: const <InvoiceEntity>[],
      payments: const <PaymentRecordEntity>[],
    );
  }

  @override
  Future<({
    FinanceOverviewEntity overview,
    List<InvoiceEntity> invoices,
  })> getAllChildrenFinance(
    List<({String studentId, String studentName})> children,
  ) async {
    if (children.isEmpty) {
      return (
        overview: FinanceOverviewEntity.zero,
        invoices: const <InvoiceEntity>[],
      );
    }

    double totalInvoiced = 0;
    double totalPaid = 0;
    double totalDue = 0;
    final allInvoices = <InvoiceEntity>[];

    final results = await Future.wait(
      children.map(
        (c) => getChildFinance(c.studentId, studentName: c.studentName).catchError(
          (_) => (
            overview: FinanceOverviewEntity.zero,
            invoices: const <InvoiceEntity>[],
            payments: const <PaymentRecordEntity>[],
          ),
        ),
      ),
    );

    for (final res in results) {
      totalInvoiced += res.overview.totalInvoiced;
      totalPaid += res.overview.totalPaid;
      totalDue += res.overview.totalDue;
      allInvoices.addAll(res.invoices);
    }

    // Sort by issue date descending
    allInvoices.sort((a, b) => b.issueDate.compareTo(a.issueDate));

    return (
      overview: FinanceOverviewEntity(
        totalInvoiced: totalInvoiced,
        totalPaid: totalPaid,
        totalDue: totalDue,
      ),
      invoices: allInvoices,
    );
  }

  @override
  Future<InvoiceEntity?> getInvoiceDetail(
    String invoiceId, {
    String? studentId,
  }) async {
    if (studentId != null && studentId.isNotEmpty) {
      final res = await getChildFinance(studentId);
      final found = res.invoices.where((i) => i.id == invoiceId || i.invoiceNumber == invoiceId);
      if (found.isNotEmpty) return found.first;
    }
    return null;
  }

  @override
  Future<PaymentRecordEntity> payInvoice({
    required String studentId,
    required String invoiceId,
    String? paymentMethod,
  }) async {
    final response = await apiClient.post<dynamic>(
      '/parent/children/$studentId/finance/pay',
      data: {
        'invoiceId': invoiceId,
        'paymentMethod': paymentMethod ?? 'online-gateway',
      },
    );

    final raw = response.data;
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return PaymentRecordEntity.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return PaymentRecordEntity(
      id: 'PMT-${DateTime.now().millisecondsSinceEpoch}',
      paymentNumber: 'PMT-${DateTime.now().millisecondsSinceEpoch}',
      paymentDate: DateTime.now(),
      amount: 0,
      paymentMethod: paymentMethod ?? 'online-gateway',
      transactionReference: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      status: 'success',
    );
  }
}
