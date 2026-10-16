import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/repositories/student_dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/student_dashboard_repository.dart';
import 'children_controller.dart';
import 'children_state.dart';
import 'dashboard_state.dart';

/// Manages the dashboard data for the currently active child (Parent role)
/// or directly for the authenticated Student (Student role).
class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() => const DashboardInitial();

  DashboardRepository get _repository => ref.read(dashboardRepositoryProvider);
  StudentDashboardRepository get _studentRepository =>
      ref.read(studentDashboardRepositoryProvider);

  int _requestToken = 0;
  String? _currentlyLoadingChildId;
  String? _sessionUserId;

  /// Resets state on logout or account switching to prevent cross-account leakage.
  void reset() {
    _requestToken++;
    _currentlyLoadingChildId = null;
    _sessionUserId = null;
    state = const DashboardInitial();
  }

  /// Loads dashboard data directly for the authenticated Student using
  /// verified Student APIs (live-classes, assignments, attendance summary).
  Future<void> loadStudentDashboard({bool isRefresh = false}) async {
    final token = ++_requestToken;
    _currentlyLoadingChildId = 'student_self';

    final authState = ref.read(authControllerProvider);
    final currentUserId = authState is Authenticated
        ? authState.user?.id
        : null;
    _sessionUserId = currentUserId;

    final current = state;
    if (!isRefresh || current is! DashboardLoaded) {
      state = const DashboardLoading();
    }

    try {
      final entity = await _studentRepository.getStudentDashboard();

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

      state = DashboardLoaded(
        childStudentId: 'student_self',
        dashboard: entity,
      );
    } catch (error) {
      if (token != _requestToken) {
        return;
      }
      if (!isRefresh || state is! DashboardLoaded) {
        state = DashboardError(message: _messageFrom(error));
      }
    }
  }

  /// Loads dashboard data for the given [childStudentId].
  ///
  /// Caller must provide the activeChildId from ChildrenController.
  /// If null, transitions to [DashboardNoChild].
  Future<void> loadDashboard({
    required String? childStudentId,
    bool isRefresh = false,
  }) async {
    if (childStudentId == null || childStudentId.isEmpty) {
      state = const DashboardNoChild();
      return;
    }

    final token = ++_requestToken;
    _currentlyLoadingChildId = childStudentId;

    final authState = ref.read(authControllerProvider);
    final currentUserId = authState is Authenticated
        ? authState.user?.id
        : null;
    _sessionUserId = currentUserId;

    final current = state;
    // On refresh of the same child, preserve current DashboardLoaded state during fetch
    if (!isRefresh ||
        current is! DashboardLoaded ||
        current.childStudentId != childStudentId) {
      state = const DashboardLoading();
    }

    try {
      final entity = await _repository.getChildDashboard(
        childStudentId: childStudentId,
      );

      // Race condition check: ensure response is still for the active child context
      if (token != _requestToken ||
          _currentlyLoadingChildId != childStudentId) {
        return;
      }

      final latestAuthState = ref.read(authControllerProvider);
      final latestUserId = latestAuthState is Authenticated
          ? latestAuthState.user?.id
          : null;
      if (latestUserId != _sessionUserId) {
        return;
      }

      state = DashboardLoaded(
        childStudentId: childStudentId,
        dashboard: entity,
      );
    } catch (error) {
      if (token != _requestToken ||
          _currentlyLoadingChildId != childStudentId) {
        return;
      }
      if (!isRefresh || state is! DashboardLoaded) {
        state = DashboardError(message: _messageFrom(error));
      }
    }
  }

  /// Retries the dashboard fetch using the current active child or student session.
  Future<void> retry() async {
    if (_currentlyLoadingChildId == 'student_self') {
      await loadStudentDashboard();
      return;
    }
    final childrenState = ref.read(childrenControllerProvider);
    final childId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;
    await loadDashboard(childStudentId: childId);
  }

  String _messageFrom(Object error) {
    final s = error.toString();
    // Extract user-friendly message from Failure.toString()
    final match = RegExp(r'message: (.+?)(,|$)').firstMatch(s);
    return match?.group(1) ?? 'Unable to load dashboard. Please try again.';
  }
}

/// Global provider for [DashboardController].
final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );
