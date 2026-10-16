import '../../../dashboard/domain/entities/child_entity.dart';

enum NotificationCategory { classes, assignments, updates }

class ParentNotificationItemEntity {
  const ParentNotificationItemEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.createdAt,
    this.actionUrl,
    this.studentId,
    this.studentName,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String content;
  final String type; // e.g. 'system', 'live_class', 'assignment'
  final DateTime? createdAt;
  final String? actionUrl;
  final String? studentId;
  final String? studentName;
  final bool isRead;

  ParentNotificationItemEntity copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    DateTime? createdAt,
    String? actionUrl,
    String? studentId,
    String? studentName,
    bool? isRead,
  }) {
    return ParentNotificationItemEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      actionUrl: actionUrl ?? this.actionUrl,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      isRead: isRead ?? this.isRead,
    );
  }

  NotificationCategory get category {
    final lowerTitle = title.toLowerCase();
    final lowerContent = content.toLowerCase();
    final lowerType = type.toLowerCase();

    if (lowerType.contains('class') ||
        lowerTitle.contains('class') ||
        lowerContent.contains('class') ||
        lowerTitle.contains('speaking') ||
        lowerContent.contains('session')) {
      return NotificationCategory.classes;
    }

    if (lowerType.contains('assignment') ||
        lowerTitle.contains('assignment') ||
        lowerContent.contains('assignment') ||
        lowerTitle.contains('homework') ||
        lowerContent.contains('submission')) {
      return NotificationCategory.assignments;
    }

    return NotificationCategory.updates;
  }

  String get timeAgo {
    if (createdAt == null) return 'Recent';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    }
  }

  /// Evaluates whether this notification belongs to the [activeChild] context.
  ///
  /// Governance rules:
  /// 1. Child-specific notifications (matching [studentId], [studentName], or
  ///    authoritative `regarding <Child>:` backend message reply text) are strictly
  ///    scoped to the matching child.
  /// 2. Notifications referencing a different child (e.g. Ram Pearson, Sarah Connor)
  ///    are excluded from the [activeChild]'s feed.
  /// 3. Parent-wide notifications with no child-exclusive attribution (e.g.
  ///    "Welcome to TrueLern Parent Portal" or global platform announcements)
  ///    remain visible for the parent account across child views.
  bool belongsToChild({
    required ChildEntity activeChild,
    List<ChildEntity> allChildren = const [],
  }) {
    // 1. Explicit stable studentId matching
    if (studentId != null && studentId!.trim().isNotEmpty) {
      final targetId = studentId!.trim().toLowerCase();
      final activeId = activeChild.studentId.trim().toLowerCase();
      final activeCode = (activeChild.studentCode ?? '').trim().toLowerCase();
      if (targetId == activeId ||
          (activeCode.isNotEmpty && targetId == activeCode)) {
        return true;
      }
      return false;
    }

    // 2. Extracted studentName matching (e.g. from backend message replies)
    if (studentName != null && studentName!.trim().isNotEmpty) {
      final namePattern = studentName!.trim().toLowerCase();
      final activeFull = activeChild.displayName.trim().toLowerCase();
      final activeFirst = activeChild.firstName.trim().toLowerCase();
      final activeLast = (activeChild.lastName ?? '').trim().toLowerCase();

      final matchesActive =
          (activeFull.isNotEmpty &&
              (namePattern == activeFull ||
                  namePattern.contains(activeFull) ||
                  activeFull.contains(namePattern))) ||
          (activeFirst.isNotEmpty &&
              (namePattern == activeFirst ||
                  namePattern.contains(activeFirst) ||
                  activeFirst.contains(namePattern))) ||
          (activeLast.isNotEmpty &&
              activeLast.length > 2 &&
              (namePattern == activeLast || namePattern.contains(activeLast)));

      if (matchesActive) {
        return true;
      }

      // Explicit studentName present that does NOT match the active child:
      // must belong exclusively to another child.
      return false;
    }

    // 3. Authoritative backend pattern: "regarding <StudentName>:"
    final regardingMatch = RegExp(
      r'regarding\s+([^:"]+):',
      caseSensitive: false,
    ).firstMatch(content);
    if (regardingMatch != null) {
      final targetName = (regardingMatch.group(1) ?? '').trim().toLowerCase();
      final activeFull = activeChild.displayName.trim().toLowerCase();
      final activeFirst = activeChild.firstName.trim().toLowerCase();
      final activeLast = (activeChild.lastName ?? '').trim().toLowerCase();

      final matchesActive =
          (activeFull.isNotEmpty &&
              (targetName == activeFull ||
                  targetName.contains(activeFull) ||
                  activeFull.contains(targetName))) ||
          (activeFirst.isNotEmpty &&
              (targetName == activeFirst ||
                  targetName.contains(activeFirst) ||
                  activeFirst.contains(targetName))) ||
          (activeLast.isNotEmpty &&
              activeLast.length > 2 &&
              (targetName == activeLast || targetName.contains(activeLast)));

      return matchesActive;
    }

    // 4. Cross-child check: ensure content/title does not mention another known child
    final lowerContent = content.toLowerCase();
    final lowerTitle = title.toLowerCase();

    for (final other in allChildren) {
      if (other.studentId == activeChild.studentId) continue;
      final otherFull = other.displayName.trim().toLowerCase();
      final otherFirst = other.firstName.trim().toLowerCase();
      final otherCode = (other.studentCode ?? '').trim().toLowerCase();

      final mentionsOther =
          (otherFull.isNotEmpty &&
              (lowerContent.contains(otherFull) ||
                  lowerTitle.contains(otherFull))) ||
          (otherFirst.length > 2 &&
              (lowerContent.contains(otherFirst) ||
                  lowerTitle.contains(otherFirst))) ||
          (otherCode.isNotEmpty &&
              (lowerContent.contains(otherCode) ||
                  lowerTitle.contains(otherCode)));

      if (mentionsOther) {
        return false;
      }
    }

    // 5. Parent-wide / general platform notification without specific child attribution
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentNotificationItemEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          type == other.type &&
          createdAt == other.createdAt &&
          actionUrl == other.actionUrl &&
          studentId == other.studentId &&
          studentName == other.studentName &&
          isRead == other.isRead;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      content.hashCode ^
      type.hashCode ^
      (createdAt?.hashCode ?? 0) ^
      (actionUrl?.hashCode ?? 0) ^
      (studentId?.hashCode ?? 0) ^
      (studentName?.hashCode ?? 0) ^
      isRead.hashCode;
}
