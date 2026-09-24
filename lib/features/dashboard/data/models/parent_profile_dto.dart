import '../../domain/entities/parent_profile_entity.dart';

/// Data Transfer Object representing the Parent Profile payload returned by `/api/parent/profile`.
class ParentProfileDto {
  const ParentProfileDto({
    required this.id,
    required this.parentId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.alternatePhone,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.status,
    required this.occupation,
    required this.organization,
    required this.designation,
  });

  factory ParentProfileDto.fromJson(Map<String, dynamic> json) {
    // Backend returns { success: true, data: { profile: { ... }, security: { ... }, linkedWards: [ ... ] } }
    // Or if passed the profile object directly:
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : json;

    return ParentProfileDto(
      id: profile['id'] as String? ?? profile['_id'] as String? ?? '',
      parentId: profile['parentId'] as String? ?? '',
      firstName: profile['firstName'] as String? ?? '',
      middleName: profile['middleName'] as String? ?? '',
      lastName: profile['lastName'] as String? ?? '',
      email: profile['email'] as String? ?? '',
      phone: profile['phone'] as String? ?? '',
      alternatePhone: profile['alternatePhone'] as String? ?? '',
      address: profile['address'] as String? ?? '',
      city: profile['city'] as String? ?? '',
      state: profile['state'] as String? ?? '',
      country: profile['country'] as String? ?? '',
      postalCode: profile['postalCode'] as String? ?? '',
      status: profile['status'] as String? ?? 'active',
      occupation: profile['occupation'] as String? ?? '',
      organization: profile['organization'] as String? ?? '',
      designation: profile['designation'] as String? ?? '',
    );
  }

  final String id;
  final String parentId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String alternatePhone;
  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String status;
  final String occupation;
  final String organization;
  final String designation;

  ParentProfileEntity toEntity() {
    return ParentProfileEntity(
      id: id,
      parentId: parentId,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      phone: phone,
      alternatePhone: alternatePhone,
      address: address,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      status: status,
      occupation: occupation,
      organization: organization,
      designation: designation,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }
}
