import '../../domain/entities/class_summary_entity.dart';

/// Sealed state hierarchy for Class Summary Screen.
sealed class ClassSummaryState {
  const ClassSummaryState();
}

/// Initial state before fetching.
final class ClassSummaryInitial extends ClassSummaryState {
  const ClassSummaryInitial();
}

/// Loading summary data.
final class ClassSummaryLoading extends ClassSummaryState {
  const ClassSummaryLoading();
}

/// Successfully loaded summary data.
final class ClassSummaryLoaded extends ClassSummaryState {
  final ClassSummaryEntity summary;

  const ClassSummaryLoaded({required this.summary});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassSummaryLoaded &&
          runtimeType == other.runtimeType &&
          summary == other.summary;

  @override
  int get hashCode => summary.hashCode;
}

/// Error occurred while fetching summary.
final class ClassSummaryError extends ClassSummaryState {
  final String message;

  const ClassSummaryError({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassSummaryError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
