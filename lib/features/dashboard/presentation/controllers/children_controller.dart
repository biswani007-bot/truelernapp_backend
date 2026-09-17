import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'children_state.dart';

/// Manages the list of linked children and the active child context.
///
/// Governance:
/// - Calls GET /api/parent/children via DashboardRepository
/// - Preserves previously active child ID across reloads/refreshes
/// - Persists activeChildId in SecureStorageService
/// - If no children: transitions to ChildrenLoaded with empty list
/// - No hardcoded children, no invented child IDs
class ChildrenController extends Notifier<ChildrenState> {
  @override
  ChildrenState build() => const ChildrenInitial();

  DashboardRepository get _repository => ref.read(dashboardRepositoryProvider);
  SecureStorageService get _storage => ref.read(secureStorageProvider);

  /// Fetches linked children. Retains the active child across refreshes.
  Future<void> loadChildren({bool isRefresh = false}) async {
    final current = state;
    if (!isRefresh || current is! ChildrenLoaded) {
      state = const ChildrenLoading();
    }
    try {
      final persistedChildId = await _storage.getActiveChildId();
      final children = await _repository.getLinkedChildren();

      // Determine active student deterministically:
      // 1. Current in-memory active child if still present in children list
      // 2. Persisted active child ID from secure storage if present
      // 3. First child in list as initial fallback
      // 4. Null if empty
      String? resolvedActiveId;
      if (current is ChildrenLoaded &&
          current.activeChildId != null &&
          children.any((c) => c.studentId == current.activeChildId)) {
        resolvedActiveId = current.activeChildId;
      } else if (persistedChildId != null &&
          children.any((c) => c.studentId == persistedChildId)) {
        resolvedActiveId = persistedChildId;
      } else if (children.isNotEmpty) {
        resolvedActiveId = children.first.studentId;
      }

      if (resolvedActiveId != null) {
        await _storage.saveActiveChildId(resolvedActiveId);
      }

      state = ChildrenLoaded(
        children: children,
        activeChildId: resolvedActiveId,
      );
    } catch (error) {
      if (!isRefresh || state is! ChildrenLoaded) {
        state = ChildrenError(message: _messageFrom(error));
      }
    }
  }

  /// Retries the children fetch after a failure.
  Future<void> retry() => loadChildren();

  /// Switches the active child context, persists the selection, and triggers dashboard reload.
  void setActiveChild(String studentId) {
    final current = state;
    if (current is ChildrenLoaded) {
      final exists = current.children.any((c) => c.studentId == studentId);
      if (!exists) return;
      _storage.saveActiveChildId(studentId);
      state = ChildrenLoaded(
        children: current.children,
        activeChildId: studentId,
      );
    }
  }

  String _messageFrom(Object error) {
    // Failure types are already user-friendly messages from ErrorHandler
    return error.toString().replaceFirst(RegExp(r'^.*\(message: '), '').replaceFirst(RegExp(r',.*$'), '');
  }
}

/// Global provider for [ChildrenController].
final childrenControllerProvider =
    NotifierProvider<ChildrenController, ChildrenState>(ChildrenController.new);
