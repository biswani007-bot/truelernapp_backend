/// Represents a single message item in the Parent-Teacher conversation.
class MessageItemEntity {
  const MessageItemEntity({
    required this.id,
    required this.senderRole,
    required this.subject,
    required this.message,
    required this.isRead,
    required this.status,
    this.createdAt,
    this.senderName,
  });

  final String id;
  final String senderRole; // 'parent', 'teacher', 'system'
  final String subject;
  final String message;
  final bool isRead;
  final String status;
  final DateTime? createdAt;
  final String? senderName;

  bool get isParent => senderRole.toLowerCase() == 'parent';
  bool get isTeacher => senderRole.toLowerCase() == 'teacher';
  bool get isSystem => senderRole.toLowerCase() == 'system';

  MessageItemEntity copyWith({
    String? id,
    String? senderRole,
    String? subject,
    String? message,
    bool? isRead,
    String? status,
    DateTime? createdAt,
    String? senderName,
  }) {
    return MessageItemEntity(
      id: id ?? this.id,
      senderRole: senderRole ?? this.senderRole,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageItemEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          senderRole == other.senderRole &&
          subject == other.subject &&
          message == other.message &&
          isRead == other.isRead &&
          status == other.status &&
          createdAt == other.createdAt &&
          senderName == other.senderName;

  @override
  int get hashCode =>
      id.hashCode ^
      senderRole.hashCode ^
      subject.hashCode ^
      message.hashCode ^
      isRead.hashCode ^
      status.hashCode ^
      (createdAt?.hashCode ?? 0) ^
      (senderName?.hashCode ?? 0);
}

/// Information about a teacher associated with the student.
class TeacherContactEntity {
  const TeacherContactEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.designation,
    this.department,
    this.batchId,
    this.batchName,
    this.role,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? designation;
  final String? department;
  final String? batchId;
  final String? batchName;
  final String? role;

  String get fullName => '$firstName $lastName'.trim();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherContactEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          designation == other.designation &&
          department == other.department &&
          batchId == other.batchId &&
          batchName == other.batchName &&
          role == other.role;

  @override
  int get hashCode =>
      id.hashCode ^
      firstName.hashCode ^
      lastName.hashCode ^
      (designation?.hashCode ?? 0) ^
      (department?.hashCode ?? 0) ^
      (batchId?.hashCode ?? 0) ^
      (batchName?.hashCode ?? 0) ^
      (role?.hashCode ?? 0);
}

/// The complete Messages dataset for a student.
class MessagesDataEntity {
  const MessagesDataEntity({
    required this.studentId,
    required this.studentName,
    this.activeTeacher,
    this.teachers = const [],
    this.messages = const [],
  });

  final String studentId;
  final String studentName;
  final TeacherContactEntity? activeTeacher;
  final List<TeacherContactEntity> teachers;
  final List<MessageItemEntity> messages;

  int get unreadCount => messages.where((m) => !m.isRead).length;

  MessagesDataEntity copyWith({
    String? studentId,
    String? studentName,
    TeacherContactEntity? activeTeacher,
    List<TeacherContactEntity>? teachers,
    List<MessageItemEntity>? messages,
  }) {
    return MessagesDataEntity(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      activeTeacher: activeTeacher ?? this.activeTeacher,
      teachers: teachers ?? this.teachers,
      messages: messages ?? this.messages,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagesDataEntity &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          studentName == other.studentName &&
          activeTeacher == other.activeTeacher &&
          teachers == other.teachers &&
          messages == other.messages;

  @override
  int get hashCode =>
      studentId.hashCode ^
      studentName.hashCode ^
      (activeTeacher?.hashCode ?? 0) ^
      teachers.hashCode ^
      messages.hashCode;
}
