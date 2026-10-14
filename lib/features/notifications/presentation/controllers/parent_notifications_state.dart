import '../../domain/entities/parent_notification_entity.dart';

sealed class ParentNotificationsState {
  const ParentNotificationsState();
}

class ParentNotificationsInitial extends ParentNotificationsState {
  const ParentNotificationsInitial();
}

class ParentNotificationsLoading extends ParentNotificationsState {
  const ParentNotificationsLoading({this.childStudentId});

  final String? childStudentId;
}

class ParentNotificationsLoaded extends ParentNotificationsState {
  const ParentNotificationsLoaded({
    required this.notifications,
    this.selectedTab = 'All',
    this.childStudentId,
  });

  final List<ParentNotificationItemEntity> notifications;
  final String selectedTab;
  final String? childStudentId;

  List<ParentNotificationItemEntity> get filteredNotifications {
    if (selectedTab == 'All') return notifications;
    if (selectedTab == 'Classes') {
      return notifications
          .where((n) => n.category == NotificationCategory.classes)
          .toList();
    }
    if (selectedTab == 'Assignments') {
      return notifications
          .where((n) => n.category == NotificationCategory.assignments)
          .toList();
    }
    if (selectedTab == 'Updates') {
      return notifications
          .where((n) => n.category == NotificationCategory.updates)
          .toList();
    }
    return notifications;
  }

  ParentNotificationsLoaded copyWith({
    List<ParentNotificationItemEntity>? notifications,
    String? selectedTab,
    String? childStudentId,
  }) {
    return ParentNotificationsLoaded(
      notifications: notifications ?? this.notifications,
      selectedTab: selectedTab ?? this.selectedTab,
      childStudentId: childStudentId ?? this.childStudentId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentNotificationsLoaded &&
          runtimeType == other.runtimeType &&
          notifications == other.notifications &&
          selectedTab == other.selectedTab &&
          childStudentId == other.childStudentId;

  @override
  int get hashCode =>
      notifications.hashCode ^
      selectedTab.hashCode ^
      (childStudentId?.hashCode ?? 0);
}

class ParentNotificationsError extends ParentNotificationsState {
  const ParentNotificationsError({
    required this.message,
    this.childStudentId,
  });

  final String message;
  final String? childStudentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentNotificationsError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          childStudentId == other.childStudentId;

  @override
  int get hashCode => message.hashCode ^ (childStudentId?.hashCode ?? 0);
}
