import '../../domain/entities/counseling_request_entity.dart';

/// DTO for parsing counseling request JSON from `GET /api/counselling/my-requests`.
class CounselingRequestDto {
  const CounselingRequestDto({
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

  factory CounselingRequestDto.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? json['requestId'] ?? '')
        .toString();

    // Counsellor info if nested or scalar
    String? cId;
    String? cName;
    String? cRole;
    String? cSpecialization;
    final counsellorRaw =
        json['counsellor'] ?? json['counselor'] ?? json['counsellorId'];
    if (counsellorRaw is Map<String, dynamic>) {
      cId = (counsellorRaw['_id'] ?? counsellorRaw['id'])?.toString();
      cName =
          counsellorRaw['name']?.toString() ??
          '${counsellorRaw['firstName'] ?? ''} ${counsellorRaw['lastName'] ?? ''}'
              .trim();
      cRole = (counsellorRaw['designation'] ??
              counsellorRaw['role'] ??
              counsellorRaw['title'])
          ?.toString();
      cSpecialization = (counsellorRaw['specialization'] ??
              counsellorRaw['department'])
          ?.toString();
    } else if (counsellorRaw != null) {
      cId = counsellorRaw.toString();
    }

    // Child/Student info if present
    String? chId;
    String? chName;
    final childRaw = json['child'] ??
        json['student'] ??
        json['childId'] ??
        json['studentId'];
    if (childRaw is Map<String, dynamic>) {
      chId = (childRaw['_id'] ?? childRaw['id'] ?? childRaw['studentId'])
          ?.toString();
      chName = childRaw['name']?.toString() ??
          '${childRaw['firstName'] ?? ''} ${childRaw['lastName'] ?? ''}'.trim();
    } else if (childRaw != null) {
      chId = childRaw.toString();
    }
    if (chName == null || chName.isEmpty) {
      chName = (json['childName'] ?? json['studentName'])?.toString();
    }

    final conversationId = (json['conversationId'] ??
            json['chatId'] ??
            json['conversation'] ??
            json['threadId'])
        ?.toString();

    DateTime? pStart;
    if (json['proposedStart'] != null) {
      pStart = DateTime.tryParse(json['proposedStart'].toString());
    } else if (json['date'] != null || json['sessionDate'] != null) {
      pStart = DateTime.tryParse(
        (json['date'] ?? json['sessionDate']).toString(),
      );
    }

    DateTime? pEnd;
    if (json['proposedEnd'] != null) {
      pEnd = DateTime.tryParse(json['proposedEnd'].toString());
    }

    DateTime? cAt;
    if (json['createdAt'] != null) {
      cAt = DateTime.tryParse(json['createdAt'].toString());
    }

    return CounselingRequestDto(
      requestId: id,
      counsellorId: cId,
      counsellorName: cName,
      counsellorRole: cRole,
      counsellorSpecialization: cSpecialization,
      childId: chId,
      childName: chName,
      conversationId: conversationId,
      status: json['status']?.toString(),
      proposedStart: pStart,
      proposedEnd: pEnd,
      createdAt: cAt,
      reason: (json['reason'] ?? json['topic'] ?? json['subject'])?.toString(),
      notes: (json['notes'] ??
              json['note'] ??
              json['parentNote'] ??
              json['message'])
          ?.toString(),
    );
  }

  CounselingRequestEntity toEntity() {
    return CounselingRequestEntity(
      requestId: requestId,
      counsellorId: counsellorId,
      counsellorName: counsellorName,
      counsellorRole: counsellorRole,
      counsellorSpecialization: counsellorSpecialization,
      childId: childId,
      childName: childName,
      conversationId: conversationId,
      status: status,
      proposedStart: proposedStart,
      proposedEnd: proposedEnd,
      createdAt: createdAt,
      reason: reason,
      notes: notes,
    );
  }
}
