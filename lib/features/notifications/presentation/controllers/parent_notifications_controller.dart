import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/domain/entities/child_entity.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../data/repositories/parent_notifications_repository_impl.dart';
import '../../domain/entities/parent_notification_entity.dart';
import '../../domain/repositories/parent_notifications_repository.dart';
import 'parent_notifications_state.dart';

/// Controller managing parent notifications scoped to the currently active child.
///
/// Governance rules:
/// - Authoritative API: GET /api/parent/notifications
/// - Prevents cross-child leakage: Child-specific notifications are filtered
///   strictly to the active child context.
/// - Preserves shared parent-level notifications (e.g. Welcome notices, global alerts).
/// - Race-condition safe: Older in-flight requests cannot overwrite newly selected child state.
/// - Scoped caching: Switching back to a previously loaded child restores their cached feed instantly.
class ParentNotificationsController extends Notifier<ParentNotificationsState> {
  late final ParentNotificationsRepository _repository;

  int _requestToken = 0;
  String? _currentChildStudentId;
  final Map<String, List<ParentNotificationItemEntity>> _scopedCache = {};

  @override
  ParentNotificationsState build() {
    _repository = ref.watch(parentNotificationsRepositoryProvider);
    return const ParentNotificationsInitial();
  }

  /// Loads notifications scoped for [activeChild].
  ///
  /// If [activeChild] is omitted, derives the active child from [childrenControllerProvider].
  Future<void> loadNotifications({
    ChildEntity? activeChild,
    List<ChildEntity> allChildren = const [],
    bool isRefresh = false,
  }) async {
    // 1. Resolve effective active child
    ChildEntity? effectiveChild = activeChild;
    List<ChildEntity> effectiveChildren = allChildren;

    if (effectiveChild == null) {
      final childrenState = ref.read(childrenControllerProvider);
      if (childrenState is ChildrenLoaded) {
        effectiveChild = childrenState.activeChild;
        if (effectiveChildren.isEmpty) {
          effectiveChildren = childrenState.children;
        }
      }
    }

    final targetChildId = effectiveChild?.studentId;
    final current = state;
    final currentTab =
        current is ParentNotificationsLoaded ? current.selectedTab : 'All';

    // 2. Skip redundant fetch if already loaded for same child and not refreshing
    if (!isRefresh &&
        current is ParentNotificationsLoaded &&
        current.childStudentId == targetChildId &&
        targetChildId != null) {
      return;
    }

    // 3. Fast restore from cache on child switch if available
    if (!isRefresh &&
        targetChildId != null &&
        _scopedCache.containsKey(targetChildId)) {
      final cachedItems = _scopedCache[targetChildId]!;
      _currentChildStudentId = targetChildId;
      state = ParentNotificationsLoaded(
        notifications: cachedItems,
        selectedTab: currentTab,
        childStudentId: targetChildId,
      );
      return;
    }

    final token = ++_requestToken;
    _currentChildStudentId = targetChildId;

    if (!isRefresh ||
        current is! ParentNotificationsLoaded ||
        current.childStudentId != targetChildId) {
      state = ParentNotificationsLoading(childStudentId: targetChildId);
    }

    try {
      final rawList = await _repository.getNotifications(
        childStudentId: targetChildId,
      );

      // 4. Race condition guard: discard if request is no longer active
      if (token != _requestToken ||
          _currentChildStudentId != targetChildId) {
        return;
      }

      // 5. Apply child scoping rules
      final List<ParentNotificationItemEntity> scopedList;
      if (effectiveChild != null) {
        scopedList = rawList
            .where((n) => n.belongsToChild(
                  activeChild: effectiveChild!,
                  allChildren: effectiveChildren,
                ))
            .toList();
      } else {
        // Without active child, show parent-level general notifications
        scopedList = rawList;
      }

      if (targetChildId != null) {
        _scopedCache[targetChildId] = scopedList;
      }

      state = ParentNotificationsLoaded(
        notifications: scopedList,
        selectedTab: currentTab,
        childStudentId: targetChildId,
      );
    } catch (e) {
      if (token != _requestToken ||
          _currentChildStudentId != targetChildId) {
        return;
      }
      final errorMsg =
          e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      state = ParentNotificationsError(
        message: errorMsg,
        childStudentId: targetChildId,
      );
    }
  }

  void setTab(String tab) {
    final current = state;
    if (current is ParentNotificationsLoaded) {
      state = current.copyWith(selectedTab: tab);
    }
  }

  void markAsRead(String notificationId) {
    final current = state;
    if (current is ParentNotificationsLoaded) {
      final updated = current.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      if (current.childStudentId != null) {
        _scopedCache[current.childStudentId!] = updated;
      }

      state = current.copyWith(notifications: updated);
    }
  }

  void clearCache() {
    _scopedCache.clear();
  }
}

final parentNotificationsControllerProvider =
    NotifierProvider<ParentNotificationsController, ParentNotificationsState>(
  ParentNotificationsController.new,
);
