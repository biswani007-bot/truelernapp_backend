import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../domain/entities/invoice_entity.dart';
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
  });

  final FinanceOverviewEntity overview;
  final List<InvoiceEntity> invoices;
  final String? selectedChildId; // null = All Children
  final bool isPaying;
  final String? payError;

  List<InvoiceEntity> get filteredInvoices {
    if (selectedChildId == null || selectedChildId!.isEmpty) {
      return invoices;
    }
    return invoices.where((i) => i.studentId == selectedChildId).toList();
  }

  FinanceLoaded copyWith({
    FinanceOverviewEntity? overview,
    List<InvoiceEntity>? invoices,
    String? selectedChildId,
    bool clearSelectedChild = false,
    bool? isPaying,
    String? payError,
    bool clearPayError = false,
  }) {
    return FinanceLoaded(
      overview: overview ?? this.overview,
      invoices: invoices ?? this.invoices,
      selectedChildId: clearSelectedChild
          ? null
          : (selectedChildId ?? this.selectedChildId),
      isPaying: isPaying ?? this.isPaying,
      payError: clearPayError ? null : (payError ?? this.payError),
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
      final childrenState = ref.read(childrenControllerProvider);

      if (childrenState is ChildrenLoaded && childrenState.children.isNotEmpty) {
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

final financeControllerProvider =
    NotifierProvider<FinanceController, FinanceState>(FinanceController.new);
