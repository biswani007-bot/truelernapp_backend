/// Request DTO for POST /api/parent/children.
///
/// Governance:
/// Endpoint: POST /api/parent/children
/// Required fields validated by backend:
/// - firstName: String
/// - lastName: String
/// Optional fields supported by backend:
/// - studentCode: String (Links existing student record if provided)
/// - relationshipType: String ('father', 'mother', 'guardian', 'other')
/// - gender: String ('male', 'female', 'other')
/// - dob: String (ISO date or YYYY-MM-DD)
class AddChildRequestDto {
  const AddChildRequestDto({
    required this.firstName,
    required this.lastName,
    this.studentCode,
    this.relationshipType,
    this.gender,
    this.dateOfBirth,
  });

  final String firstName;
  final String lastName;
  final String? studentCode;
  final String? relationshipType;
  final String? gender;
  final String? dateOfBirth;

  Map<String, dynamic> toJson() => {
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    if (studentCode != null && studentCode!.trim().isNotEmpty)
      'studentCode': studentCode!.trim(),
    if (relationshipType != null && relationshipType!.trim().isNotEmpty)
      'relationshipType': relationshipType!.trim().toLowerCase(),
    if (gender != null && gender!.trim().isNotEmpty)
      'gender': gender!.trim().toLowerCase(),
    if (dateOfBirth != null && dateOfBirth!.trim().isNotEmpty)
      'dob': dateOfBirth!.trim(),
  };
}
