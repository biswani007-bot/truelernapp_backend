import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/data/models/class_summary_dto.dart';

void main() {
  group('ClassSummaryDto', () {
    test('parses full backend response with live-classes, attendance, and assignment', () {
      final classJson = {
        'id': '6a8704c1630b0bf96212bbb9',
        'classCode': 'LVC-0002',
        'classTitle': 'Intro to Advanced Next.js',
        'startDate': '2026-10-15T08:30:00.000Z',
        'endDate': '2026-10-15T10:00:00.000Z',
        'duration': 90,
        'status': 'scheduled',
        'effectiveStatus': 'attended',
        'attendance': {
          'status': 'present',
          'mode': 'teacher-marked',
          'durationAttended': 7437,
          'checkInTime': '2026-09-12T04:50:28.154Z',
        },
        'courseName': 'Junior Foundation',
        'instructor': 'Elizabeth Vance',
      };

      final nextClassJson = {
        'id': '6aa948f9ce253df8ba6cca53',
        'classCode': 'LVC-0004',
        'classTitle': 'Junior Foundation first class',
        'startDate': '2026-10-20T10:00:00.000Z',
      };

      final assignmentJson = {
        'id': '6a87011ffae35df7c876b0d9',
        'title': 'Module 1 Practicum: Simple Request Router',
        'dueDate': '2026-10-25T18:00:00.000Z',
        'status': 'published',
      };

      final dto = ClassSummaryDto.fromBackend(
        targetClassId: '6a8704c1630b0bf96212bbb9',
        classJson: classJson,
        attendanceRecordJson: null,
        nextClassJson: nextClassJson,
        assignmentJson: assignmentJson,
      );

      final entity = dto.toEntity();

      expect(entity.classId, equals('6a8704c1630b0bf96212bbb9'));
      expect(entity.classTitle, equals('Intro to Advanced Next.js'));
      expect(entity.teacherName, equals('Elizabeth Vance'));
      expect(entity.scheduledDurationMinutes, equals(90));
      // 7437 seconds / 60 = 124 minutes
      expect(entity.attendedDurationMinutes, equals(124));
      expect(entity.attendanceStatus, equals('present'));
      expect(entity.isAttended, isTrue);
      expect(entity.skillsPracticed, isEmpty); // Backend provides no skills
      expect(entity.nextClassId, equals('6aa948f9ce253df8ba6cca53'));
      expect(entity.nextClassTitle, equals('Junior Foundation first class'));
      expect(entity.nextClassTimeFormatted, isNotNull);
      expect(entity.assignmentId, equals('6a87011ffae35df7c876b0d9'));
      expect(
        entity.assignmentTitle,
        equals('Module 1 Practicum: Simple Request Router'),
      );
      expect(entity.assignmentDueDate, contains('Due'));
    });

    test(
      'handles fallback when attendance is in separate attendance record',
      () {
        final classJson = {
          'id': '6ab27c8aaabd606a21c0e4a6',
          'classTitle': 'testing',
          'duration': 150,
          'instructor': 'Elizabeth Vance',
        };

        final attendanceRecord = {
          'id': '6ab27f49aabd606a21c0e6c7',
          'status': 'late',
          'durationAttended': 24,
          'classTitle': 'testing',
        };

        final dto = ClassSummaryDto.fromBackend(
          targetClassId: '6ab27c8aaabd606a21c0e4a6',
          classJson: classJson,
          attendanceRecordJson: attendanceRecord,
          nextClassJson: null,
          assignmentJson: null,
        );

        final entity = dto.toEntity();

        expect(entity.classId, equals('6ab27c8aaabd606a21c0e4a6'));
        expect(entity.classTitle, equals('testing'));
        expect(entity.teacherName, equals('Elizabeth Vance'));
        expect(entity.scheduledDurationMinutes, equals(150));
        expect(entity.attendedDurationMinutes, equals(24));
        expect(entity.attendanceStatus, equals('late'));
        expect(entity.isAttended, isTrue);
        expect(entity.nextClassTitle, isNull);
        expect(entity.assignmentId, isNull);
      },
    );

    test('handles completely null and missing fields defensively', () {
      final dto = ClassSummaryDto.fromBackend(
        targetClassId: 'fallback-id',
        classJson: null,
        attendanceRecordJson: null,
        nextClassJson: null,
        assignmentJson: null,
      );

      final entity = dto.toEntity();

      expect(entity.classId, equals('fallback-id'));
      expect(entity.classTitle, equals('Live Class'));
      expect(entity.teacherName, isNull);
      expect(entity.scheduledDurationMinutes, isNull);
      expect(entity.attendedDurationMinutes, isNull);
      expect(entity.skillsPracticed, isEmpty);
      expect(entity.nextClassId, isNull);
      expect(entity.assignmentId, isNull);
    });

    test('correctly parses skills when backend provides them', () {
      final classJson = {
        'id': 'class-with-skills',
        'classTitle': 'Math Magic',
        'skills': [
          {'title': 'Logic', 'icon': 'assets/icons/logic.svg'},
          {'title': 'Problem Solving'},
        ],
      };

      final dto = ClassSummaryDto.fromBackend(
        targetClassId: 'class-with-skills',
        classJson: classJson,
        attendanceRecordJson: null,
        nextClassJson: null,
        assignmentJson: null,
      );

      expect(dto.skillsPracticed.length, equals(2));
      expect(dto.skillsPracticed[0].title, equals('Logic'));
      expect(dto.skillsPracticed[1].title, equals('Problem Solving'));
    });
  });
}
