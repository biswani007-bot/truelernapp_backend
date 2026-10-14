/// Domain entity representing track / program details for a child.
///
/// Source: GET /api/parent/children/{childStudentId}/program
class ProgramDetailsEntity {
  const ProgramDetailsEntity({
    this.programId,
    this.courseId,
    this.courseName,
    this.courseCode,
    this.description,
    this.level,
    this.duration,
    this.batchId,
    this.batchName,
    this.instructor,
    this.progress,
    this.skillsInFocus = const [],
    this.totalAssignments,
    this.completedAssignments,
    this.totalAssessments,
    this.completedAssessments,
  });

  final String? programId;
  final String? courseId;
  final String? courseName;
  final String? courseCode;
  final String? description;
  final String? level;
  final String? duration;
  final String? batchId;
  final String? batchName;
  final String? instructor;
  final double? progress;
  final List<String> skillsInFocus;
  final int? totalAssignments;
  final int? completedAssignments;
  final int? totalAssessments;
  final int? completedAssessments;

  factory ProgramDetailsEntity.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'];
    double? prog;
    if (rawProgress is num) prog = rawProgress.toDouble();
    if (rawProgress is String) prog = double.tryParse(rawProgress);

    final rawSkills = json['skillsInFocus'];
    final List<String> skills = [];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s != null) skills.add(s.toString());
      }
    }

    int? parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return ProgramDetailsEntity(
      programId: json['programId']?.toString() ?? json['_id']?.toString(),
      courseId: json['courseId']?.toString(),
      courseName: json['courseName']?.toString(),
      courseCode: json['courseCode']?.toString(),
      description: json['description']?.toString(),
      level: json['level']?.toString(),
      duration: json['duration']?.toString(),
      batchId: json['batchId']?.toString(),
      batchName: json['batchName']?.toString(),
      instructor: json['instructor']?.toString() ?? json['teacher']?.toString(),
      progress: prog,
      skillsInFocus: skills,
      totalAssignments: parseInt(json['totalAssignments']),
      completedAssignments: parseInt(json['completedAssignments']),
      totalAssessments: parseInt(json['totalAssessments']),
      completedAssessments: parseInt(json['completedAssessments']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramDetailsEntity &&
          runtimeType == other.runtimeType &&
          programId == other.programId &&
          courseName == other.courseName &&
          courseCode == other.courseCode &&
          progress == other.progress;

  @override
  int get hashCode =>
      programId.hashCode ^
      courseName.hashCode ^
      courseCode.hashCode ^
      progress.hashCode;
}
