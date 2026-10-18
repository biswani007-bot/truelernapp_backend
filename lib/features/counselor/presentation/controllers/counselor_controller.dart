import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/counselor_repository_impl.dart';
import '../../domain/entities/counseling_request_entity.dart';
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

  /// Resets state on logout or account switching.
  void reset() {
    state = const CounselorInitial();
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

  /// Submits a new counselling request and refreshes the requests list upon success.
  Future<CounselingRequestEntity> submitRequest({
    required String counsellorId,
    required String studentId,
    required DateTime proposedStart,
    required DateTime proposedEnd,
    required String reason,
  }) async {
    try {
      final newRequest = await _repository.submitRequest(
        counsellorId: counsellorId,
        studentId: studentId,
        proposedStart: proposedStart,
        proposedEnd: proposedEnd,
        reason: reason,
      );

      // Refresh requests list so the new request appears immediately
      await loadCounselor(childStudentId: studentId, isRefresh: true);
      return newRequest;
    } catch (e) {
      rethrow;
    }
  }
}

/// Global Riverpod provider for [CounselorController].
final counselorControllerProvider =
    NotifierProvider<CounselorController, CounselorState>(
      CounselorController.new,
    );
