import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/counselor_repository_impl.dart';
import '../../domain/repositories/counselor_repository.dart';
import 'counselor_state.dart';

/// Riverpod controller managing Counselor data, child switching, and pull-to-refresh.
class CounselorController extends Notifier<CounselorState> {
  late final CounselorRepository _repository;

  @override
  CounselorState build() {
    _repository = ref.watch(counselorRepositoryProvider);
    return const CounselorInitial();
  }

  /// Loads counselor and counselling requests for the active child/user context.
  Future<void> loadCounselor({
    required String? childStudentId,
    bool isRefresh = false,
  }) async {
    if (!isRefresh) {
      state = const CounselorLoading();
    }

    try {
      final results = await Future.wait([
        _repository.getCounselors(),
        _repository.getMyRequests(),
      ]);

      final counselors = results[0] as List<dynamic>;
      final requests = results[1] as List<dynamic>;

      state = CounselorLoaded(
        counselors: counselors.cast(),
        myRequests: requests.cast(),
        activeChildId: childStudentId,
      );
    } catch (e) {
      if (!isRefresh || state is! CounselorLoaded) {
        state = CounselorError(
          'Unable to load counselor information. Please check your connection and try again.',
          activeChildId: childStudentId,
        );
      }
    }
  }

  /// Retries loading data.
  Future<void> retry({required String? childStudentId}) async {
    await loadCounselor(childStudentId: childStudentId, isRefresh: false);
  }
}

/// Global Riverpod provider for [CounselorController].
final counselorControllerProvider =
    NotifierProvider<CounselorController, CounselorState>(
  CounselorController.new,
);
