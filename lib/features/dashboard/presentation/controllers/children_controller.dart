import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_entity.dart';
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

  int _requestToken = 0;
  String? _sessionUserId;

  /// Resets state on logout or account switching to prevent cross-account leakage.
  void reset() {
    _requestToken++;
    _sessionUserId = null;
    state = const ChildrenInitial();
    _storage.deleteActiveChildId();
  }

  /// Fetches linked children. Retains the active child across refreshes.
  Future<void> loadChildren({bool isRefresh = false}) async {
    final token = ++_requestToken;
    final current = state;

    final authState = ref.read(authControllerProvider);
    final currentUserId = authState is Authenticated
        ? authState.user?.id
        : null;
    _sessionUserId = currentUserId;

    if (!isRefresh || current is! ChildrenLoaded) {
      state = const ChildrenLoading();
    }
    try {
      final persistedChildId = await _storage.getActiveChildId();
      final children = await _repository.getLinkedChildren();

      // Guard against race conditions and account switching
      if (token != _requestToken) {
        return;
      }

      final latestAuthState = ref.read(authControllerProvider);
      final latestUserId = latestAuthState is Authenticated
          ? latestAuthState.user?.id
          : null;
      if (latestUserId != _sessionUserId) {
        return;
      }

      // Determine active student deterministically:
      // STRICT RULE: Must be present in the newly fetched children list!
      // 1. Current in-memory active child if still present in children list
      // 2. Persisted active child ID from secure storage if present
      // 3. First child in list as initial fallback
      // 4. Null if empty
      String? resolvedActiveId;
      if (children.isEmpty) {
        resolvedActiveId = null;
        await _storage.deleteActiveChildId();
      } else if (current is ChildrenLoaded &&
          current.activeChildId != null &&
          children.any((c) => c.studentId == current.activeChildId)) {
        resolvedActiveId = current.activeChildId;
      } else if (persistedChildId != null &&
          children.any((c) => c.studentId == persistedChildId)) {
        resolvedActiveId = persistedChildId;
      } else {
        resolvedActiveId = children.first.studentId;
      }

      if (resolvedActiveId != null) {
        await _storage.saveActiveChildId(resolvedActiveId);
      } else {
        await _storage.deleteActiveChildId();
      }

      state = ChildrenLoaded(
        children: children,
        activeChildId: resolvedActiveId,
      );
    } catch (error) {
      if (token != _requestToken) return;
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
    return error
        .toString()
        .replaceFirst(RegExp(r'^.*\(message: '), '')
        .replaceFirst(RegExp(r',.*$'), '');
  }
}

/// Global provider for [ChildrenController].
final childrenControllerProvider =
    NotifierProvider<ChildrenController, ChildrenState>(ChildrenController.new);

/// Provider for fetching a specific child's dashboard metrics (course, attendance rate).
final childDashboardMetricsProvider = FutureProvider.autoDispose
    .family<DashboardEntity, String>((ref, studentId) async {
      final repo = ref.watch(dashboardRepositoryProvider);
      return repo.getChildDashboard(childStudentId: studentId);
    });
