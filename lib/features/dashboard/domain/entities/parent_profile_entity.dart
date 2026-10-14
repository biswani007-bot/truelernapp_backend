/// Domain entity representing the authenticated Parent's personal profile information.
class ParentProfileEntity {
  const ParentProfileEntity({
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

  String get fullName {
    final parts = [
      firstName,
      middleName,
      lastName,
    ].where((s) => s.trim().isNotEmpty);
    return parts.isEmpty ? 'Parent' : parts.join(' ');
  }

  String get fullAddress {
    final parts = [
      address,
      city,
      state,
      postalCode,
      country,
    ].where((s) => s.trim().isNotEmpty);
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  ParentProfileEntity copyWith({
    String? id,
    String? parentId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    String? alternatePhone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? status,
    String? occupation,
    String? organization,
    String? designation,
  }) {
    return ParentProfileEntity(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      status: status ?? this.status,
      occupation: occupation ?? this.occupation,
      organization: organization ?? this.organization,
      designation: designation ?? this.designation,
    );
  }
}
