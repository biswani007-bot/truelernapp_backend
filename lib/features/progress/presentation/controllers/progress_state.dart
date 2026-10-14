import '../../domain/entities/progress_entity.dart';

sealed class ProgressState {
  const ProgressState();
}

class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

class ProgressLoading extends ProgressState {
  const ProgressLoading({this.previousProgress});

  final ProgressEntity? previousProgress;
}

class ProgressLoaded extends ProgressState {
  const ProgressLoaded({
    required this.progress,
    required this.activeChildId,
  });

  final ProgressEntity progress;
  final String activeChildId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressLoaded &&
          runtimeType == other.runtimeType &&
          progress == other.progress &&
          activeChildId == other.activeChildId;

  @override
  int get hashCode => progress.hashCode ^ activeChildId.hashCode;
}

class ProgressEmpty extends ProgressState {
  const ProgressEmpty({
    required this.activeChildId,
    this.message = 'Progress data is not yet available for this student.',
  });

  final String activeChildId;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressEmpty &&
          runtimeType == other.runtimeType &&
          activeChildId == other.activeChildId &&
          message == other.message;

  @override
  int get hashCode => activeChildId.hashCode ^ message.hashCode;
}

class ProgressError extends ProgressState {
  const ProgressError({
    required this.message,
    this.activeChildId,
  });

  final String message;
  final String? activeChildId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          activeChildId == other.activeChildId;

  @override
  int get hashCode => message.hashCode ^ (activeChildId?.hashCode ?? 0);
}
