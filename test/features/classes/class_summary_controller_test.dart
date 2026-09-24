import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/data/repositories/class_summary_repository_impl.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/class_summary_entity.dart';
import 'package:truelearn/features/classes/domain/repositories/class_summary_repository.dart';
import 'package:truelearn/features/classes/presentation/controllers/class_summary_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/class_summary_state.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';

class MockClassSummaryRepository implements ClassSummaryRepository {
  ClassSummaryEntity? result;
  bool shouldThrow = false;
  String? capturedChildStudentId;
  String? capturedClassId;

  @override
  Future<ClassSummaryEntity> getClassSummary({
    required String childStudentId,
    required String classId,
    ClassEntity? session,
  }) async {
    capturedChildStudentId = childStudentId;
    capturedClassId = classId;
    if (shouldThrow) {
      throw Exception('Network connection timed out');
    }
    return result ??
        ClassSummaryEntity(
          classId: classId,
          classTitle: session?.title ?? 'Test Session',
          durationMinutes: 45,
          teacherName: 'Marcus Mercer',
        );
  }
}

class FakeChildrenController extends ChildrenController {
  @override
  ChildrenState build() {
    return const ChildrenLoaded(
      children: [
        ChildEntity(
          studentId: 'child_1',
          firstName: 'Sarah',
          lastName: 'Connor',
        ),
      ],
      activeChildId: 'child_1',
    );
  }
}

void main() {
  group('ClassSummaryController', () {
    late ProviderContainer container;
    late MockClassSummaryRepository mockRepo;

    setUp(() {
      mockRepo = MockClassSummaryRepository();
      container = ProviderContainer(
        overrides: [
          classSummaryRepositoryProvider.overrideWithValue(mockRepo),
          childrenControllerProvider.overrideWith(FakeChildrenController.new),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is ClassSummaryInitial', () {
      final state = container.read(classSummaryControllerProvider);
      expect(state, isA<ClassSummaryInitial>());
    });

    test('loadSummary transitions through loading to loaded and resolves active child ID', () async {
      final controller = container.read(classSummaryControllerProvider.notifier);

      final future = controller.loadSummary(classId: 'class-123');
      expect(container.read(classSummaryControllerProvider), isA<ClassSummaryLoading>());

      await future;

      final state = container.read(classSummaryControllerProvider);
      expect(state, isA<ClassSummaryLoaded>());
      final loaded = state as ClassSummaryLoaded;
      expect(loaded.summary.classId, 'class-123');
      expect(loaded.summary.teacherName, 'Marcus Mercer');
      expect(mockRepo.capturedChildStudentId, equals('child_1'));
    });

    test('loadSummary respects explicitly passed childStudentId', () async {
      final controller = container.read(classSummaryControllerProvider.notifier);

      await controller.loadSummary(
        classId: 'class-custom',
        childStudentId: 'explicit_child_99',
      );

      final state = container.read(classSummaryControllerProvider);
      expect(state, isA<ClassSummaryLoaded>());
      expect(mockRepo.capturedChildStudentId, equals('explicit_child_99'));
    });

    test('loadSummary transitions to error on exception', () async {
      mockRepo.shouldThrow = true;
      final controller = container.read(classSummaryControllerProvider.notifier);

      await controller.loadSummary(classId: 'class-err');

      final state = container.read(classSummaryControllerProvider);
      expect(state, isA<ClassSummaryError>());
      final err = state as ClassSummaryError;
      expect(err.message, contains('Network connection timed out'));
    });
  });
}
