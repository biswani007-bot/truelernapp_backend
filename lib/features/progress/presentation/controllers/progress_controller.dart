import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../domain/entities/progress_entity.dart';
import '../../domain/repositories/progress_repository.dart';
import 'progress_state.dart';

/// Provider for [ProgressController].
final progressControllerProvider =
    NotifierProvider<ProgressController, ProgressState>(ProgressController.new);

/// Controller managing academic progress state and child switching.
class ProgressController extends Notifier<ProgressState> {
  @override
  ProgressState build() => const ProgressInitial();

  ProgressRepository get _repository => ref.read(progressRepositoryProvider);

  int _requestToken = 0;
  String? _currentlyLoadingChildId;
  String? _currentStudentName;
  String? _currentActiveTrack;

  /// Loads academic progress for a specific student.
  Future<void> loadProgress({
    required String? childStudentId,
    String? studentName,
    String? activeTrack,
    bool isRefresh = false,
  }) async {
    if (childStudentId == null || childStudentId.isEmpty) {
      state = const ProgressEmpty(
        activeChildId: '',
        message: 'No student selected.',
      );
      return;
    }

    final token = ++_requestToken;
    _currentlyLoadingChildId = childStudentId;
    if (studentName != null) _currentStudentName = studentName;
    if (activeTrack != null) _currentActiveTrack = activeTrack;

    final current = state;
    ProgressEntity? prevProgress;
    if (current is ProgressLoaded && current.activeChildId == childStudentId) {
      prevProgress = current.progress;
    }

    // If not a silent refresh, display loading state
    if (!isRefresh || prevProgress == null) {
      state = ProgressLoading(previousProgress: prevProgress);
    }

    try {
      final entity = await _repository.getChildProgress(
        childStudentId: childStudentId,
        studentName: _currentStudentName,
        activeTrack: _currentActiveTrack,
      );

      // Race condition check: ensure response matches latest request
      if (token != _requestToken || _currentlyLoadingChildId != childStudentId) {
        return;
      }

      state = ProgressLoaded(
        progress: entity,
        activeChildId: childStudentId,
      );
    } catch (e) {
      if (token != _requestToken || _currentlyLoadingChildId != childStudentId) {
        return;
      }
      // If refresh failed but we had loaded progress, keep existing loaded state
      if (isRefresh && current is ProgressLoaded && current.activeChildId == childStudentId) {
        return;
      }
      state = ProgressError(
        message: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
        activeChildId: childStudentId,
      );
    }
  }

  /// Triggers a pull-to-refresh for the currently loaded or active child.
  Future<void> refresh() async {
    final childId = _currentlyLoadingChildId;
    if (childId != null && childId.isNotEmpty) {
      await loadProgress(
        childStudentId: childId,
        studentName: _currentStudentName,
        activeTrack: _currentActiveTrack,
        isRefresh: true,
      );
    }
  }

  /// Retries fetching after an error.
  Future<void> retry() async {
    final childId = _currentlyLoadingChildId;
    if (childId != null && childId.isNotEmpty) {
      await loadProgress(
        childStudentId: childId,
        studentName: _currentStudentName,
        activeTrack: _currentActiveTrack,
        isRefresh: false,
      );
    }
  }
}
