/// Domain entity representing a counselling session or appointment request.
class CounselingRequestEntity {
  const CounselingRequestEntity({
    required this.requestId,
    this.counsellorId,
    this.counsellorName,
    this.status,
    this.proposedStart,
    this.proposedEnd,
    this.reason,
    this.notes,
  });

  final String requestId;
  final String? counsellorId;
  final String? counsellorName;
  final String? status;
  final DateTime? proposedStart;
  final DateTime? proposedEnd;
  final String? reason;
  final String? notes;

  String get statusLabel => (status ?? 'pending').toUpperCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounselingRequestEntity &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId &&
          counsellorId == other.counsellorId &&
          counsellorName == other.counsellorName &&
          status == other.status &&
          proposedStart == other.proposedStart &&
          proposedEnd == other.proposedEnd &&
          reason == other.reason &&
          notes == other.notes;

  @override
  int get hashCode =>
      requestId.hashCode ^
      counsellorId.hashCode ^
      counsellorName.hashCode ^
      status.hashCode ^
      proposedStart.hashCode ^
      proposedEnd.hashCode ^
      reason.hashCode ^
      notes.hashCode;
}
