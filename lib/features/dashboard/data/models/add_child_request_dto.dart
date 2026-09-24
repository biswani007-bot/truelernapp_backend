/// Request DTO for POST /api/parent/children.
///
/// Governance:
/// Endpoint: POST /api/parent/children
/// Required fields validated by backend:
/// - firstName: String
/// - lastName: String
/// Optional fields:
/// - gender: String (e.g. 'male', 'female', 'other')
/// - dateOfBirth: String (ISO date or YYYY-MM-DD)
/// - grade: String (e.g. 'Grade 4')
/// - relationshipType: String (e.g. 'father', 'mother', 'guardian')
class AddChildRequestDto {
  const AddChildRequestDto({
    required this.firstName,
    required this.lastName,
    this.gender,
    this.dateOfBirth,
    this.grade,
    this.relationshipType,
  });

  final String firstName;
  final String lastName;
  final String? gender;
  final String? dateOfBirth;
  final String? grade;
  final String? relationshipType;

  Map<String, dynamic> toJson() => {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        if (gender != null && gender!.trim().isNotEmpty) 'gender': gender!.trim(),
        if (dateOfBirth != null && dateOfBirth!.trim().isNotEmpty)
          'dateOfBirth': dateOfBirth!.trim(),
        if (grade != null && grade!.trim().isNotEmpty) 'grade': grade!.trim(),
        if (relationshipType != null && relationshipType!.trim().isNotEmpty)
          'relationshipType': relationshipType!.trim(),
      };
}
