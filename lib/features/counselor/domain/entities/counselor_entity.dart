/// Domain entity representing an academic or admissions counselor.
class CounselorEntity {
  const CounselorEntity({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.designation,
    this.specialization,
    this.status,
    this.bio,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? designation;
  final String? specialization;
  final String? status;
  final String? bio;

  String get displayDesignation {
    if (designation != null && designation!.trim().isNotEmpty) {
      return designation!.trim();
    }
    return 'Academic Counselor';
  }

  bool get hasContactInfo =>
      (email != null && email!.trim().isNotEmpty) ||
      (phone != null && phone!.trim().isNotEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounselorEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          avatar == other.avatar &&
          designation == other.designation &&
          specialization == other.specialization &&
          status == other.status &&
          bio == other.bio;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      avatar.hashCode ^
      designation.hashCode ^
      specialization.hashCode ^
      status.hashCode ^
      bio.hashCode;
}
