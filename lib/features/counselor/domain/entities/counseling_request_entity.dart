/// Domain entity representing a counselling session or appointment request.
class CounselingRequestEntity {
  const CounselingRequestEntity({
    required this.requestId,
    this.counsellorId,
    this.counsellorName,
    this.counsellorRole,
    this.counsellorSpecialization,
    this.childId,
    this.childName,
    this.conversationId,
    this.status,
    this.proposedStart,
    this.proposedEnd,
    this.createdAt,
    this.reason,
    this.notes,
  });

  final String requestId;
  final String? counsellorId;
  final String? counsellorName;
  final String? counsellorRole;
  final String? counsellorSpecialization;
  final String? childId;
  final String? childName;
  final String? conversationId;
  final String? status;
  final DateTime? proposedStart;
  final DateTime? proposedEnd;
  final DateTime? createdAt;
  final String? reason;
  final String? notes;

  String get statusLabel => (status ?? 'pending').toUpperCase();

  bool get isAccepted {
    final s = status?.toLowerCase() ?? '';
    return s == 'accepted' || s == 'confirmed' || s == 'scheduled';
  }

  bool get isPending {
    final s = status?.toLowerCase() ?? '';
    return s == 'pending';
  }

  bool get isRejected {
    final s = status?.toLowerCase() ?? '';
    return s == 'rejected' || s == 'declined';
  }

  bool get canChat => isAccepted;

  String get displayNote {
    if (notes != null && notes!.trim().isNotEmpty) {
      return notes!.trim();
    }
    if (reason != null && reason!.trim().isNotEmpty) {
      return reason!.trim();
    }
    return 'Academic guidance session';
  }

  String get displayDate {
    final date = proposedStart ?? createdAt;
    if (date == null) return 'Date TBD';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounselingRequestEntity &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId &&
          counsellorId == other.counsellorId &&
          counsellorName == other.counsellorName &&
          counsellorRole == other.counsellorRole &&
          counsellorSpecialization == other.counsellorSpecialization &&
          childId == other.childId &&
          childName == other.childName &&
          conversationId == other.conversationId &&
          status == other.status &&
          proposedStart == other.proposedStart &&
          proposedEnd == other.proposedEnd &&
          createdAt == other.createdAt &&
          reason == other.reason &&
          notes == other.notes;

  @override
  int get hashCode =>
      requestId.hashCode ^
      counsellorId.hashCode ^
      counsellorName.hashCode ^
      counsellorRole.hashCode ^
      counsellorSpecialization.hashCode ^
      childId.hashCode ^
      childName.hashCode ^
      conversationId.hashCode ^
      status.hashCode ^
      proposedStart.hashCode ^
      proposedEnd.hashCode ^
      createdAt.hashCode ^
      reason.hashCode ^
      notes.hashCode;
}
