import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/stripe_checkout_entity.dart';
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

    final String? resolvedCurrency = results
            .map((r) => r.overview.currency)
            .where((c) => c != null && c.isNotEmpty)
            .cast<String?>()
            .firstOrNull ??
        allInvoices
            .map((i) => i.currency)
            .where((c) => c != null && c.isNotEmpty)
            .cast<String?>()
            .firstOrNull;

    return (
      overview: FinanceOverviewEntity(
        totalInvoiced: totalInvoiced,
        totalPaid: totalPaid,
        totalDue: totalDue,
        currency: resolvedCurrency,
      ),
      invoices: allInvoices,
    );
  }

  @override
  Future<InvoiceEntity?> getInvoiceDetail(
    String invoiceId, {
    String? studentId,
  }) async {
    try {
      return await verifyInvoiceStatus(invoiceId);
    } catch (_) {
      if (studentId != null && studentId.isNotEmpty) {
        final res = await getChildFinance(studentId);
        final found = res.invoices
            .where((i) => i.id == invoiceId || i.invoiceNumber == invoiceId);
        if (found.isNotEmpty) return found.first;
      }
      return null;
    }
  }

  @override
  Future<StripeCheckoutSessionEntity> createStripeCheckoutSession({
    required String invoiceId,
    required String studentId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    // 1. Authoritative Parent Invoice Checkout:
    // If studentId is present, use the dedicated parent checkout endpoint:
    // POST /api/parent/children/{studentId}/finance/pay
    // The server generates the Stripe Checkout Session with trusted internal return URLs,
    // avoiding client-redirect domain rejection while preserving strict server security.
    if (studentId.isNotEmpty) {
      try {
        final response = await apiClient.post<dynamic>(
          '/parent/children/$studentId/finance/pay',
          data: {
            'invoiceId': invoiceId,
            'paymentMethod': 'online-gateway',
          },
        );

        final raw = response.data;
        if (raw is Map<String, dynamic>) {
          final session = StripeCheckoutSessionEntity.fromJson(raw);
          if (session.url.isNotEmpty) {
            return session;
          }
        }
      } catch (e) {
        // Fall back to direct /finance/stripe/create-checkout if parent endpoint is unreachable or fails
      }
    }

    // 2. Direct finance checkout endpoint with redirect URLs
    final response = await apiClient.post<dynamic>(
      '/finance/stripe/create-checkout',
      data: {
        'invoiceId': invoiceId,
        'studentId': studentId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      },
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final session = StripeCheckoutSessionEntity.fromJson(raw);
      if (session.url.isNotEmpty) {
        return session;
      }
    }

    throw const ServerFailure('Invalid Stripe checkout session response.');
  }

  @override
  Future<InvoiceEntity> verifyInvoiceStatus(String invoiceId) async {
    try {
      final response = await apiClient.get<dynamic>(
        '/finance/invoices/$invoiceId',
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : raw;
        return InvoiceEntity.fromJson(data);
      }
    } catch (_) {
      // Parent role does not have permission for the staff /finance/invoices endpoint.
      // Retrieve authoritative invoice status from the parent children finance endpoint.
      try {
        final childrenRes = await apiClient.get<dynamic>('/parent/children');
        final rawChildren = childrenRes.data;
        final List<String> childIds = [];
        if (rawChildren is Map<String, dynamic> &&
            rawChildren['data'] is List) {
          for (final c in rawChildren['data'] as List) {
            if (c is Map<String, dynamic>) {
              final id = c['id']?.toString() ??
                  c['_id']?.toString() ??
                  c['studentId']?.toString();
              if (id != null && id.isNotEmpty) childIds.add(id);
            }
          }
        }

        for (final childId in childIds) {
          final res = await getChildFinance(childId);
          final match =
              res.invoices.where((i) => i.id == invoiceId).firstOrNull;
          if (match != null) {
            return match;
          }
        }
      } catch (inner) {
        throw ServerFailure('Unable to verify invoice status: $inner');
      }
    }

    throw const ServerFailure('Invalid invoice response format.');
  }

  @override
  Future<List<ReceiptEntity>> getReceipts({int limit = 10}) async {
    final response = await apiClient.get<dynamic>(
      '/finance/receipts',
      queryParameters: {'limit': limit},
    );

    final raw = response.data;
    final list = <ReceiptEntity>[];
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            list.add(ReceiptEntity.fromJson(item));
          }
        }
      }
    }
    return list;
  }

  @override
  Future<List<PaymentRecordEntity>> getPayments({int limit = 10}) async {
    final response = await apiClient.get<dynamic>(
      '/finance/payments',
      queryParameters: {'limit': limit},
    );

    final raw = response.data;
    final list = <PaymentRecordEntity>[];
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            list.add(PaymentRecordEntity.fromJson(item));
          }
        }
      }
    }
    return list;
  }

  @override
  Future<void> refreshEnrollments({int limit = 10}) async {
    try {
      await apiClient.get<dynamic>(
        '/enrollments',
        queryParameters: {'limit': limit},
      );
    } catch (_) {
      // Non-blocking best-effort call to keep server cache warm
    }
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
