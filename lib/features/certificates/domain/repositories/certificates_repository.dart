import '../entities/certificate_entity.dart';

/// Repository interface for certificate operations.
abstract interface class CertificatesRepository {
  /// Retrieves issued certificates for the specified child student.
  Future<List<CertificateEntity>> getCertificates({required String childStudentId});
}
