import '../../domain/entities/certificate_entity.dart';

/// Data Transfer Object for parsing certificate JSON returned by
/// `GET /api/parent/children/:studentId/certificates`.
class CertificateDto {
  const CertificateDto({
    required this.certificateId,
    required this.certificateNumber,
    this.issueDate,
    required this.status,
    this.downloadUrl,
    this.title,
    this.programName,
  });

  final String certificateId;
  final String certificateNumber;
  final DateTime? issueDate;
  final String status;
  final String? downloadUrl;
  final String? title;
  final String? programName;

  factory CertificateDto.fromJson(Map<String, dynamic> json) {
    // 1. Resolve ID
    final id = json['certificateId'] ?? json['id'] ?? json['_id'] ?? '';

    // 2. Resolve Certificate Number
    final number =
        json['certificateNumber'] ??
        json['number'] ??
        json['code'] ??
        json['certificateCode'] ??
        '';

    // 3. Resolve Issue Date
    DateTime? parsedDate;
    final rawDate =
        json['issueDate'] ??
        json['issuedDate'] ??
        json['createdAt'] ??
        json['date'];
    if (rawDate != null) {
      if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate);
      } else if (rawDate is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
      }
    }

    // 4. Resolve Status
    final statusStr = json['status']?.toString() ?? 'issued';

    // 5. Resolve Download URL
    final rawUrl =
        json['downloadUrl'] ??
        json['fileUrl'] ??
        json['pdfUrl'] ??
        json['url'] ??
        json['certificateUrl'];
    final url =
        (rawUrl != null &&
            rawUrl != 'null' &&
            rawUrl.toString().trim().isNotEmpty)
        ? rawUrl.toString().trim()
        : null;

    // 6. Resolve Title / Program
    final titleStr =
        json['title'] ??
        json['name'] ??
        json['courseTitle'] ??
        json['courseName'];
    final programStr =
        json['programName'] ?? json['batchName'] ?? json['program'];

    return CertificateDto(
      certificateId: id.toString(),
      certificateNumber: number.toString(),
      issueDate: parsedDate,
      status: statusStr,
      downloadUrl: url,
      title: titleStr?.toString(),
      programName: programStr?.toString(),
    );
  }

  CertificateEntity toEntity({String? childStudentId}) {
    return CertificateEntity(
      certificateId: certificateId,
      certificateNumber: certificateNumber.isNotEmpty
          ? certificateNumber
          : (certificateId.isNotEmpty
                ? '#${certificateId.substring(0, 8.clamp(0, certificateId.length))}'
                : 'Certificate'),
      issueDate: issueDate,
      status: status,
      downloadUrl: downloadUrl,
      title: title,
      programName: programName,
      childStudentId: childStudentId,
    );
  }
}
