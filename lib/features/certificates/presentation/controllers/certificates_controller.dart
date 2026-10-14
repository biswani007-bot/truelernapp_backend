import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/certificates_repository_impl.dart';
import '../../domain/repositories/certificates_repository.dart';
import 'certificates_state.dart';

/// Riverpod controller managing certificate fetch, child switching, and pull-to-refresh.
class CertificatesController extends Notifier<CertificatesState> {
  late final CertificatesRepository _repository;

  @override
  CertificatesState build() {
    _repository = ref.watch(certificatesRepositoryProvider);
    return const CertificatesInitial();
  }

  /// Loads certificates for the specified [childStudentId].
  ///
  /// When [isRefresh] is true, existing loaded data is preserved in place
  /// while the network request is executing so that pull-to-refresh does not
  /// flash a full loading skeleton.
  Future<void> loadCertificates({
    required String? childStudentId,
    bool isRefresh = false,
  }) async {
    if (childStudentId == null || childStudentId.isEmpty) {
      state = const CertificatesLoaded(certificates: [], activeChildId: null);
      return;
    }

    if (!isRefresh) {
      state = const CertificatesLoading();
    }

    try {
      final certs = await _repository.getCertificates(childStudentId: childStudentId);
      state = CertificatesLoaded(
        certificates: certs,
        activeChildId: childStudentId,
      );
    } catch (e) {
      // If refresh failed but we already had loaded data, keep existing data intact
      if (!isRefresh || state is! CertificatesLoaded) {
        state = CertificatesError(
          'Unable to load certificates. Please check your connection and try again.',
          activeChildId: childStudentId,
        );
      }
    }
  }

  /// Retries fetching certificates for the given student.
  Future<void> retry({required String? childStudentId}) async {
    await loadCertificates(childStudentId: childStudentId, isRefresh: false);
  }
}

/// Global Riverpod provider for [CertificatesController].
final certificatesControllerProvider =
    NotifierProvider<CertificatesController, CertificatesState>(
  CertificatesController.new,
);
