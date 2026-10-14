import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../data/repositories/class_summary_repository_impl.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/repositories/class_summary_repository.dart';
import 'class_summary_state.dart';

/// Controller managing data for [ClassSummaryScreen] (Figma Node 76:2253).
class ClassSummaryController extends Notifier<ClassSummaryState> {
  ClassSummaryRepository get _repository =>
      ref.read(classSummaryRepositoryProvider);

  @override
  ClassSummaryState build() => const ClassSummaryInitial();

  Future<void> loadSummary({
    required String classId,
    String? childStudentId,
    ClassEntity? session,
  }) async {
    state = const ClassSummaryLoading();
    try {
      String resolvedChildId = childStudentId ?? '';
      if (resolvedChildId.isEmpty) {
        final childrenState = ref.read(childrenControllerProvider);
        if (childrenState is ChildrenLoaded &&
            childrenState.activeChildId != null) {
          resolvedChildId = childrenState.activeChildId!;
        }
      }
      if (resolvedChildId.isEmpty) {
        final storage = ref.read(secureStorageProvider);
        resolvedChildId = await storage.getActiveChildId() ?? '';
      }
      if (resolvedChildId.isEmpty) {
        try {
          final dashboardRepo = ref.read(dashboardRepositoryProvider);
          final children = await dashboardRepo.getLinkedChildren();
          if (children.isNotEmpty) {
            resolvedChildId = children.first.studentId;
          }
        } catch (_) {}
      }

      final summary = await _repository.getClassSummary(
        childStudentId: resolvedChildId,
        classId: classId,
        session: session,
      );
      state = ClassSummaryLoaded(summary: summary);
    } catch (e) {
      state = ClassSummaryError(message: _errorMessageFrom(e));
    }
  }

  String _errorMessageFrom(Object error) {
    final s = error.toString();
    final match = RegExp(r'message: (.+?)(,|$)').firstMatch(s);
    if (match != null) return match.group(1)!;
    if (s.startsWith('Exception: ')) return s.substring('Exception: '.length);
    return 'Unable to load class summary. Please try again.';
  }
}

/// Global provider for [ClassSummaryController].
final classSummaryControllerProvider =
    NotifierProvider<ClassSummaryController, ClassSummaryState>(
      ClassSummaryController.new,
    );
