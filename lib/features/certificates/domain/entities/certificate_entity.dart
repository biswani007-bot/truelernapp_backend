/// Domain entity representing an issued student certificate.
class CertificateEntity {
  const CertificateEntity({
    required this.certificateId,
    required this.certificateNumber,
    this.issueDate,
    required this.status,
    this.downloadUrl,
    this.title,
    this.programName,
    this.childStudentId,
  });

  /// Unique certificate identifier from the backend.
  final String certificateId;

  /// Human-readable certificate code/number (e.g. `CRT-000001`).
  final String certificateNumber;

  /// Official issuance date timestamp.
  final DateTime? issueDate;

  /// Status of the certificate (e.g. `issued`, `approved`, `pending`).
  final String status;

  /// Direct URL to download/view the certificate file/PDF if available.
  final String? downloadUrl;

  /// Optional course or certificate title if provided.
  final String? title;

  /// Program or batch name associated with the certificate.
  final String? programName;

  /// Target child / student ID this certificate belongs to.
  final String? childStudentId;

  /// Formatted display title.
  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }
    if (programName != null && programName!.trim().isNotEmpty) {
      return '$programName Certificate';
    }
    return 'Course Completion Certificate';
  }

  /// Uppercase status text for badges (e.g. `ISSUED`).
  String get statusLabel => status.trim().toUpperCase();

  /// Whether a valid downloadable URL is available.
  bool get hasDownloadUrl =>
      downloadUrl != null &&
      downloadUrl!.trim().isNotEmpty &&
      downloadUrl != 'null';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificateEntity &&
          runtimeType == other.runtimeType &&
          certificateId == other.certificateId &&
          certificateNumber == other.certificateNumber &&
          issueDate == other.issueDate &&
          status == other.status &&
          downloadUrl == other.downloadUrl &&
          title == other.title &&
          programName == other.programName &&
          childStudentId == other.childStudentId;

  @override
  int get hashCode =>
      certificateId.hashCode ^
      certificateNumber.hashCode ^
      issueDate.hashCode ^
      status.hashCode ^
      downloadUrl.hashCode ^
      title.hashCode ^
      programName.hashCode ^
      childStudentId.hashCode;
}
