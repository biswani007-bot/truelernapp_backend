/// Domain entity representing a linked child (ward) under a Parent account.
///
/// Source: GET /api/parent/children
/// Governance: docs/project-source-of-truth/03-API-SOURCE-OF-TRUTH.md — Folder 04, Item 1
class ChildEntity {
  const ChildEntity({
    required this.studentId,
    required this.firstName,
    this.lastName,
    this.avatar,
    this.grade,
    this.studentCode,
    this.gender,
    this.relationshipType,
    this.status,
    this.dateOfBirth,
    this.isCustodial,
    this.isEmergencyContact,
    this.canAccessPortal,
    this.explicitAge,
  });

  /// The student's unique identifier — required for all child-context API calls.
  final String studentId;
  final String firstName;
  final String? lastName;
  final String? avatar;
  final String? grade;
  final String? studentCode;
  final String? gender;
  final String? relationshipType;
  final String? status;
  final String? dateOfBirth;
  final bool? isCustodial;
  final bool? isEmergencyContact;
  final bool? canAccessPortal;
  final int? explicitAge;

  /// Derived display name: firstName + lastName (trimmed).
  String get displayName {
    final parts = [
      firstName,
      if (lastName != null && lastName!.isNotEmpty) lastName!,
    ];
    return parts.join(' ');
  }

  /// Derived age calculated from dateOfBirth or explicit API age if available.
  int? get age {
    if (dateOfBirth != null && dateOfBirth!.trim().isNotEmpty) {
      try {
        final dob = DateTime.parse(dateOfBirth!.trim());
        final now = DateTime.now();
        var calculatedAge = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          calculatedAge--;
        }
        if (calculatedAge > 0) return calculatedAge;
      } catch (_) {
        // Fall back to explicitAge if date parsing fails
      }
    }
    if (explicitAge != null && explicitAge! > 0) {
      return explicitAge;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildEntity && studentId == other.studentId;

  @override
  int get hashCode => studentId.hashCode;
}
