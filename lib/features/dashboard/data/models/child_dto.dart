import '../../domain/entities/child_entity.dart';

/// Data Transfer Object for a child/ward returned by GET /api/parent/children.
///
/// Governance: docs/project-source-of-truth/03-API-SOURCE-OF-TRUTH.md — Folder 04, Item 1
/// Response envelope: { "success": true, "data": [ ChildDto, ... ] }
class ChildDto {
  const ChildDto({
    required this.studentId,
    this.firstName,
    this.lastName,
    this.avatar,
    this.grade,
    this.studentCode,
    this.gender,
    this.relationshipType,
    this.status,
    this.dateOfBirth,
  });

  final String studentId;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? grade;
  final String? studentCode;
  final String? gender;
  final String? relationshipType;
  final String? status;
  final String? dateOfBirth;

  /// Parses a single child object from the API response.
  ///
  /// The API may return `studentId` under either key `studentId` or `_id`.
  /// firstName / lastName may also come as a combined `name` field.
  factory ChildDto.fromJson(Map<String, dynamic> json) {
    // Resolve student ID from possible key variants
    final id = (json['studentId'] ?? json['_id'] ?? json['id'] ?? '').toString();

    // Resolve first / last name — API may use `firstName`/`lastName` or combined `name`
    String? first = json['firstName'] as String?;
    String? last = json['lastName'] as String?;
    if ((first == null || first.isEmpty) && json['name'] is String) {
      final parts = (json['name'] as String).trim().split(' ');
      first = parts.isNotEmpty ? parts.first : null;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    }

    return ChildDto(
      studentId: id,
      firstName: first,
      lastName: last,
      avatar: json['avatar'] as String?,
      grade: json['grade'] as String?,
      studentCode: (json['studentCode'] ?? json['code']) as String?,
      gender: json['gender'] as String?,
      relationshipType: json['relationshipType'] as String?,
      status: json['status'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
    );
  }

  /// Converts DTO to domain entity.
  ChildEntity toEntity() => ChildEntity(
        studentId: studentId,
        firstName: firstName ?? '',
        lastName: lastName,
        avatar: avatar,
        grade: grade,
        studentCode: studentCode,
        gender: gender,
        relationshipType: relationshipType,
        status: status,
        dateOfBirth: dateOfBirth,
      );
}
