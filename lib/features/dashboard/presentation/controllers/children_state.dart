import '../../../dashboard/domain/entities/child_entity.dart';

/// Sealed state hierarchy for the children list controller.
sealed class ChildrenState {
  const ChildrenState();
}

/// Initial — controller not yet triggered.
final class ChildrenInitial extends ChildrenState {
  const ChildrenInitial();
}

/// Fetching /api/parent/children.
final class ChildrenLoading extends ChildrenState {
  const ChildrenLoading();
}

/// Successfully loaded. May contain an empty list (zero linked children).
final class ChildrenLoaded extends ChildrenState {
  const ChildrenLoaded({required this.children, required this.activeChildId});

  final List<ChildEntity> children;

  /// The currently active child's studentId.
  /// Null if children list is empty.
  final String? activeChildId;

  /// Shortcut: the active ChildEntity, or null.
  ChildEntity? get activeChild => activeChildId == null
      ? null
      : children.where((c) => c.studentId == activeChildId).firstOrNull;

  bool get hasChildren => children.isNotEmpty;
}

/// Network or server failure while loading children.
final class ChildrenError extends ChildrenState {
  const ChildrenError({required this.message});

  final String message;
}
