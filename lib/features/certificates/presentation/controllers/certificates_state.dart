import '../../domain/entities/certificate_entity.dart';

/// Sealed state hierarchy for the Certificates screen.
sealed class CertificatesState {
  const CertificatesState();
}

/// Initial state before any data request.
final class CertificatesInitial extends CertificatesState {
  const CertificatesInitial();
}

/// Loading state showing shimmers during initial fetch.
final class CertificatesLoading extends CertificatesState {
  const CertificatesLoading();
}

/// Successfully loaded certificates state.
final class CertificatesLoaded extends CertificatesState {
  const CertificatesLoaded({
    required this.certificates,
    required this.activeChildId,
  });

  final List<CertificateEntity> certificates;
  final String? activeChildId;
}

/// Error state when network/server request fails.
final class CertificatesError extends CertificatesState {
  const CertificatesError(this.message, {this.activeChildId});

  final String message;
  final String? activeChildId;
}
