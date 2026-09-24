import 'package:flutter/foundation.dart';

/// Skill practiced during a class session.
@immutable
class SkillPracticed {
  final String title;
  final String svgPath;
  final int colorHex;
  final int bgColorHex;

  const SkillPracticed({
    required this.title,
    required this.svgPath,
    required this.colorHex,
    required this.bgColorHex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillPracticed &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          svgPath == other.svgPath;

  @override
  int get hashCode => title.hashCode ^ svgPath.hashCode;
}

/// Domain entity representing the post-class session summary (Figma Node 76:2253).
@immutable
class ClassSummaryEntity {
  final String classId;
  final String classTitle;
  final String? teacherName;
  final int? scheduledDurationMinutes;
  final int? attendedDurationMinutes;
  final String? attendanceStatus;
  final bool isAttended;
  final List<SkillPracticed> skillsPracticed;
  final String? nextClassId;
  final String? nextClassTitle;
  final String? nextClassTimeFormatted;
  final String? assignmentId;
  final String? assignmentTitle;
  final String? assignmentDueDate;

  const ClassSummaryEntity({
    required this.classId,
    required this.classTitle,
    this.teacherName,
    int? scheduledDurationMinutes,
    int? durationMinutes,
    this.attendedDurationMinutes,
    this.attendanceStatus,
    this.isAttended = true,
    this.skillsPracticed = const [],
    this.nextClassId,
    this.nextClassTitle,
    this.nextClassTimeFormatted,
    this.assignmentId,
    this.assignmentTitle,
    this.assignmentDueDate,
  }) : scheduledDurationMinutes = scheduledDurationMinutes ?? durationMinutes;

  /// Helper getter for total/scheduled duration in minutes
  int? get durationMinutes => scheduledDurationMinutes ?? attendedDurationMinutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassSummaryEntity &&
          runtimeType == other.runtimeType &&
          classId == other.classId &&
          classTitle == other.classTitle &&
          teacherName == other.teacherName &&
          scheduledDurationMinutes == other.scheduledDurationMinutes &&
          attendedDurationMinutes == other.attendedDurationMinutes &&
          isAttended == other.isAttended;

  @override
  int get hashCode =>
      classId.hashCode ^
      classTitle.hashCode ^
      teacherName.hashCode ^
      scheduledDurationMinutes.hashCode ^
      attendedDurationMinutes.hashCode ^
      isAttended.hashCode;
}
