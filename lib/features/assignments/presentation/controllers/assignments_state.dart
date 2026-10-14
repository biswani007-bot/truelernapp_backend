import '../../domain/entities/assignment_entity.dart';

sealed class AssignmentsState {
  const AssignmentsState();
}

class AssignmentsInitial extends AssignmentsState {
  const AssignmentsInitial();
}

class AssignmentsLoading extends AssignmentsState {
  final String? childStudentId;
  const AssignmentsLoading({this.childStudentId});
}

class AssignmentsLoaded extends AssignmentsState {
  final List<AssignmentEntity> allAssignments;
  final String selectedFilter; // "All", "Pending", "Overdue", "Completed"
  final String? childStudentId;

  const AssignmentsLoaded({
    required this.allAssignments,
    this.selectedFilter = 'All',
    this.childStudentId,
  });

  List<AssignmentEntity> get filteredAssignments {
    if (selectedFilter == 'All') return allAssignments;
    if (selectedFilter == 'Pending') {
      return allAssignments
          .where((a) => a.status == AssignmentStatus.pending)
          .toList();
    }
    if (selectedFilter == 'Overdue') {
      return allAssignments
          .where((a) => a.status == AssignmentStatus.overdue)
          .toList();
    }
    if (selectedFilter == 'Completed') {
      return allAssignments
          .where((a) => a.status == AssignmentStatus.completed)
          .toList();
    }
    return allAssignments;
  }

  AssignmentsLoaded copyWith({
    List<AssignmentEntity>? allAssignments,
    String? selectedFilter,
    String? childStudentId,
  }) {
    return AssignmentsLoaded(
      allAssignments: allAssignments ?? this.allAssignments,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      childStudentId: childStudentId ?? this.childStudentId,
    );
  }
}

class AssignmentsError extends AssignmentsState {
  final String message;
  final String? childStudentId;

  const AssignmentsError(this.message, {this.childStudentId});
}
