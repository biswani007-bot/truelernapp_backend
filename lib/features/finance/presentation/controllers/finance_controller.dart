import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/stripe_checkout_entity.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../data/repositories/finance_repository_impl.dart';

@immutable
sealed class FinanceState {
  const FinanceState();
}

class FinanceInitial extends FinanceState {
  const FinanceInitial();
}

class FinanceLoading extends FinanceState {
  const FinanceLoading();
}

class FinanceLoaded extends FinanceState {
  const FinanceLoaded({
    required this.overview,
    required this.invoices,
    this.selectedChildId,
    this.isPaying = false,
    this.payError,
    this.checkoutState = CheckoutUiState.idle,
    this.activeSession,
  });

  final FinanceOverviewEntity overview;
  final List<InvoiceEntity> invoices;
  final String? selectedChildId; // null = All Children
  final bool isPaying;
  final String? payError;
  final CheckoutUiState checkoutState;
  final StripeCheckoutSessionEntity? activeSession;

  List<InvoiceEntity> get filteredInvoices {
    if (selectedChildId == null || selectedChildId!.isEmpty) {
      return invoices;
    }
    return invoices.where((i) => i.studentId == selectedChildId).toList();
  }

  FinanceOverviewEntity get currentOverview {
    if (selectedChildId == null || selectedChildId!.isEmpty) {
      return overview;
    }
    final childInvoices = filteredInvoices;
    final totalInvoiced =
        childInvoices.fold<double>(0.0, (sum, i) => sum + i.totalAmount);
    final totalPaid =
        childInvoices.fold<double>(0.0, (sum, i) => sum + i.amountPaid);
    final totalDue =
        childInvoices.fold<double>(0.0, (sum, i) => sum + i.amountDue);
    final String? resolvedCurrency = childInvoices
            .map((i) => i.currency)
            .where((c) => c != null && c.isNotEmpty)
            .cast<String?>()
            .firstOrNull ??
        overview.currency;

    return FinanceOverviewEntity(
      totalInvoiced: totalInvoiced,
      totalPaid: totalPaid,
      totalDue: totalDue,
      currency: resolvedCurrency,
    );
  }

  FinanceLoaded copyWith({
    FinanceOverviewEntity? overview,
    List<InvoiceEntity>? invoices,
    String? selectedChildId,
    bool clearSelectedChild = false,
    bool? isPaying,
    String? payError,
    bool clearPayError = false,
    CheckoutUiState? checkoutState,
    StripeCheckoutSessionEntity? activeSession,
    bool clearActiveSession = false,
  }) {
    return FinanceLoaded(
      overview: overview ?? this.overview,
      invoices: invoices ?? this.invoices,
      selectedChildId: clearSelectedChild
          ? null
          : (selectedChildId ?? this.selectedChildId),
      isPaying: isPaying ?? this.isPaying,
      payError: clearPayError ? null : (payError ?? this.payError),
      checkoutState: checkoutState ?? this.checkoutState,
      activeSession: clearActiveSession
          ? null
          : (activeSession ?? this.activeSession),
    );
  }
}

class FinanceError extends FinanceState {
  const FinanceError(this.message);
  final String message;
}

class FinanceController extends Notifier<FinanceState> {
  @override
  FinanceState build() => const FinanceInitial();

  FinanceRepository get _financeRepository =>
      ref.read(financeRepositoryProvider);

  Future<void> loadFinance({String? childId}) async {
    state = const FinanceLoading();
    try {
      var childrenState = ref.read(childrenControllerProvider);
      if (childrenState is! ChildrenLoaded) {
        await ref.read(childrenControllerProvider.notifier).loadChildren();
        childrenState = ref.read(childrenControllerProvider);
      }

      if (childrenState is ChildrenLoaded &&
          childrenState.children.isNotEmpty) {
        final childrenList = childrenState.children
            .map((c) => (studentId: c.studentId, studentName: c.displayName))
            .toList();

        if (childId != null && childId.isNotEmpty) {
          final targetChild = childrenState.children
              .where((c) => c.studentId == childId)
              .firstOrNull;
          final result = await _financeRepository.getChildFinance(
            childId,
            studentName: targetChild?.displayName,
          );
          state = FinanceLoaded(
            overview: result.overview,
            invoices: result.invoices,
            selectedChildId: childId,
          );
        } else {
          final result =
              await _financeRepository.getAllChildrenFinance(childrenList);
          state = FinanceLoaded(
            overview: result.overview,
            invoices: result.invoices,
            selectedChildId: null,
          );
        }
      } else {
        // Fallback for direct student/child query
        final activeChildId = childrenState is ChildrenLoaded
            ? childrenState.activeChildId
            : null;
        if (activeChildId != null && activeChildId.isNotEmpty) {
          final result =
              await _financeRepository.getChildFinance(activeChildId);
          state = FinanceLoaded(
            overview: result.overview,
            invoices: result.invoices,
            selectedChildId: activeChildId,
          );
        } else {
          state = const FinanceLoaded(
            overview: FinanceOverviewEntity.zero,
            invoices: [],
          );
        }
      }
    } catch (e) {
      state = FinanceError(e.toString());
    }
  }

  void selectChildFilter(String? childId) {
    final current = state;
    if (current is FinanceLoaded) {
      state = current.copyWith(
        selectedChildId: childId,
        clearSelectedChild: childId == null || childId.isEmpty,
      );
    }
  }

  void setCheckoutState(CheckoutUiState newState) {
    final current = state;
    if (current is FinanceLoaded) {
      state = current.copyWith(checkoutState: newState);
    }
  }

  /// Initiates an official Stripe Checkout Session for [invoice] and [studentId].
  Future<StripeCheckoutSessionEntity> createCheckoutSession({
    required InvoiceEntity invoice,
    required String studentId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final current = state;
    if (current is FinanceLoaded) {
      state = current.copyWith(
        isPaying: true,
        clearPayError: true,
        checkoutState: CheckoutUiState.creatingCheckout,
      );
    }

    try {
      // Security check: verify linked child relationship
      final childrenState = ref.read(childrenControllerProvider);
      if (childrenState is ChildrenLoaded &&
          childrenState.children.isNotEmpty) {
        final isLinked = childrenState.children.any(
          (c) => c.studentId == studentId,
        );
        if (!isLinked) {
          throw Exception(
            'Unauthorized: Selected student is not linked to the authenticated parent.',
          );
        }
      }

      final session = await _financeRepository.createStripeCheckoutSession(
        invoiceId: invoice.id,
        studentId: studentId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      final latest = state;
      if (latest is FinanceLoaded) {
        state = latest.copyWith(
          isPaying: false,
          checkoutState: CheckoutUiState.checkoutOpened,
          activeSession: session,
        );
      }

      return session;
    } catch (e) {
      final latest = state;
      if (latest is FinanceLoaded) {
        state = latest.copyWith(
          isPaying: false,
          payError: e.toString(),
          checkoutState: CheckoutUiState.paymentFailed,
        );
      }
      rethrow;
    }
  }

  /// Bounded verification polling against GET /api/finance/invoices/{invoiceId}.
  ///
  /// Never confirms payment unless the backend reports status == 'paid' or settled.
  Future<InvoiceEntity> verifyAndPollInvoicePayment(
    String invoiceId, {
    int maxAttempts = 5,
    Duration pollInterval = const Duration(seconds: 2),
    String? studentId,
  }) async {
    final current = state;
    if (current is FinanceLoaded) {
      state = current.copyWith(
        checkoutState: CheckoutUiState.pendingVerification,
      );
    }

    InvoiceEntity? lastInvoice;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final verified = await _financeRepository.verifyInvoiceStatus(invoiceId);
        lastInvoice = verified;

        if (verified.isPaid) {
          final latest = state;
          if (latest is FinanceLoaded) {
            state = latest.copyWith(
              checkoutState: CheckoutUiState.paymentConfirmed,
              clearActiveSession: true,
            );
          }

          // Trigger full authoritative post-settlement refresh across all finance & enrollment records
          await refreshAllAfterConfirmedPayment(
            studentId: studentId ?? verified.studentId ?? '',
            invoiceId: invoiceId,
          );

          return verified;
        }
      } catch (_) {
        // Network or server glitch during poll; retry if attempts remain
        if (attempt == maxAttempts && lastInvoice == null) {
          final latest = state;
          if (latest is FinanceLoaded) {
            state = latest.copyWith(
              checkoutState: CheckoutUiState.verificationUnavailable,
            );
          }
          rethrow;
        }
      }

      if (attempt < maxAttempts) {
        await Future.delayed(pollInterval);
      }
    }

    // Polling bounded limit reached without paid confirmation
    final latest = state;
    if (latest is FinanceLoaded) {
      state = latest.copyWith(
        checkoutState: CheckoutUiState.pendingVerification,
      );
    }

    return lastInvoice ??
        (await _financeRepository.verifyInvoiceStatus(invoiceId));
  }

  /// Authoritatively refreshes invoice, child finance, payments, receipts, and enrollments.
  Future<void> refreshAllAfterConfirmedPayment({
    required String studentId,
    required String invoiceId,
  }) async {
    try {
      final current = state;
      final selectedChild = current is FinanceLoaded ? current.selectedChildId : null;

      // 1. Refresh active finance overview and invoice list
      await loadFinance(childId: selectedChild ?? (studentId.isNotEmpty ? studentId : null));

      // 2. Refresh selected child finance if studentId is provided
      if (studentId.isNotEmpty) {
        await _financeRepository.getChildFinance(studentId).catchError(
          (_) => (
            overview: FinanceOverviewEntity.zero,
            invoices: const <InvoiceEntity>[],
            payments: const <PaymentRecordEntity>[],
          ),
        );
      }

      // 3. Refresh payments history (limit=10)
      await _financeRepository.getPayments(limit: 10).catchError((_) => <PaymentRecordEntity>[]);

      // 4. Refresh receipts (limit=10)
      await _financeRepository.getReceipts(limit: 10).catchError((_) => <ReceiptEntity>[]);

      // 5. Refresh enrollments (limit=10)
      await _financeRepository.refreshEnrollments(limit: 10);
    } catch (_) {
      // Best-effort non-blocking refresh
    }
  }

  /// Legacy processPayment method preserved for backward-compatibility and tests.
  Future<PaymentRecordEntity?> processPayment(InvoiceEntity invoice) async {
    final current = state;
    if (current is! FinanceLoaded) return null;

    state = current.copyWith(isPaying: true, clearPayError: true);

    try {
      final studentId = invoice.studentId ??
          current.selectedChildId ??
          (ref.read(childrenControllerProvider) is ChildrenLoaded
              ? (ref.read(childrenControllerProvider) as ChildrenLoaded)
                  .activeChildId
              : null);

      if (studentId == null || studentId.isEmpty) {
        throw Exception('Student identifier required to process payment.');
      }

      final payment = await _financeRepository.payInvoice(
        studentId: studentId,
        invoiceId: invoice.id,
      );

      // Refresh finance records
      await loadFinance(childId: current.selectedChildId);
      return payment;
    } catch (e) {
      final latest = state;
      if (latest is FinanceLoaded) {
        state = latest.copyWith(
          isPaying: false,
          payError: e.toString(),
        );
      }
      rethrow;
    }
  }
}

/// Provider exposing [FinanceController].
final financeControllerProvider =
    NotifierProvider<FinanceController, FinanceState>(FinanceController.new);
