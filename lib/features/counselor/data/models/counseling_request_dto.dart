import '../../domain/entities/counseling_request_entity.dart';

/// DTO for parsing counseling request JSON from `GET /api/counselling/my-requests`.
class CounselingRequestDto {
  const CounselingRequestDto({
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

  factory CounselingRequestDto.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? json['requestId'] ?? '').toString();

    // Counsellor info if nested or scalar
    String? cId;
    String? cName;
    final counsellorRaw = json['counsellor'] ?? json['counselor'] ?? json['counsellorId'];
    if (counsellorRaw is Map<String, dynamic>) {
      cId = (counsellorRaw['_id'] ?? counsellorRaw['id'])?.toString();
      cName = counsellorRaw['name']?.toString() ??
          '${counsellorRaw['firstName'] ?? ''} ${counsellorRaw['lastName'] ?? ''}'.trim();
    } else if (counsellorRaw != null) {
      cId = counsellorRaw.toString();
    }

    DateTime? pStart;
    if (json['proposedStart'] != null) {
      pStart = DateTime.tryParse(json['proposedStart'].toString());
    }

    DateTime? pEnd;
    if (json['proposedEnd'] != null) {
      pEnd = DateTime.tryParse(json['proposedEnd'].toString());
    }

    return CounselingRequestDto(
      requestId: id,
      counsellorId: cId,
      counsellorName: cName,
      status: json['status']?.toString(),
      proposedStart: pStart,
      proposedEnd: pEnd,
      reason: json['reason']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  CounselingRequestEntity toEntity() {
    return CounselingRequestEntity(
      requestId: requestId,
      counsellorId: counsellorId,
      counsellorName: counsellorName,
      status: status,
      proposedStart: proposedStart,
      proposedEnd: proposedEnd,
      reason: reason,
      notes: notes,
    );
  }
}
