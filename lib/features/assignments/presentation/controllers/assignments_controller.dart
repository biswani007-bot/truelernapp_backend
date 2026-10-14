import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../domain/repositories/assignments_repository.dart';
import '../../data/repositories/assignments_repository_impl.dart';
import 'assignments_state.dart';

class AssignmentsController extends Notifier<AssignmentsState> {
  int _requestToken = 0;

  @override
  AssignmentsState build() {
    // Listen to ChildrenController to handle active child switches globally
    ref.listen<ChildrenState>(childrenControllerProvider, (prev, next) {
      if (next is ChildrenLoaded) {
        final prevChildId = prev is ChildrenLoaded ? prev.activeChildId : null;
        if (next.activeChildId != prevChildId) {
          loadAssignments(childStudentId: next.activeChildId, isRefresh: true);
        }
      } else if (next is ChildrenInitial || next is ChildrenLoading) {
        state = const AssignmentsLoading();
      }
    });

    final children = ref.watch(childrenControllerProvider);
    if (children is ChildrenLoaded && children.activeChildId != null) {
      Future.microtask(
        () => loadAssignments(childStudentId: children.activeChildId),
      );
    }

    return const AssignmentsInitial();
  }

  AssignmentsRepository get _repository =>
      ref.read(assignmentsRepositoryProvider);

  /// Loads assignments strictly for the specified [childStudentId].
  ///
  /// Requirements:
  /// 1. Immediately clears previous child's data and transitions to [AssignmentsLoading].
  /// 2. If [childStudentId] is null or empty, transitions cleanly to empty list.
  /// 3. Request token prevents out-of-order race conditions when switching quickly.
  /// 4. Filters out any assignments not matching [childStudentId] (defense-in-depth).
  Future<void> loadAssignments({
    String? childStudentId,
    bool isRefresh = false,
  }) async {
    final token = ++_requestToken;

    final current = state;
    // On pull-to-refresh for the same child, preserve current loaded state and filter
    final bool preserveExisting =
        isRefresh &&
        current is AssignmentsLoaded &&
        current.childStudentId == childStudentId;

    if (!preserveExisting) {
      state = AssignmentsLoading(childStudentId: childStudentId);
    }

    if (childStudentId == null || childStudentId.isEmpty) {
      state = const AssignmentsLoaded(
        allAssignments: [],
        childStudentId: null,
        selectedFilter: 'All',
      );
      return;
    }

    try {
      final items = await _repository.getAssignments(
        childStudentId: childStudentId,
      );

      // Race condition check: if a new request was issued, discard this response
      if (token != _requestToken) return;

      // Filter defensively to guarantee no data leakage
      final childItems = items
          .where(
            (a) =>
                a.childStudentId == null || a.childStudentId == childStudentId,
          )
          .toList();

      final String filterToUse = preserveExisting
          ? current.selectedFilter
          : 'All';

      state = AssignmentsLoaded(
        allAssignments: childItems,
        childStudentId: childStudentId,
        selectedFilter: filterToUse,
      );
    } catch (e) {
      if (token != _requestToken) return;
      if (!preserveExisting) {
        state = AssignmentsError(
          'Unable to load assignments: ${e.toString()}',
          childStudentId: childStudentId,
        );
      }
    }
  }

  void setFilter(String filter) {
    final current = state;
    if (current is AssignmentsLoaded) {
      state = current.copyWith(selectedFilter: filter);
    }
  }
}

/// Provider for [AssignmentsController].
final assignmentsControllerProvider =
    NotifierProvider<AssignmentsController, AssignmentsState>(() {
      return AssignmentsController();
    });
