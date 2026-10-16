import '../../domain/entities/message_entity.dart';

class MessageItemDto {
  const MessageItemDto({
    required this.id,
    required this.senderRole,
    required this.subject,
    required this.message,
    required this.isRead,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String senderRole;
  final String subject;
  final String message;
  final bool isRead;
  final String status;
  final DateTime? createdAt;

  factory MessageItemDto.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawCreated = json['createdAt'] ?? json['timestamp'] ?? json['date'];
    if (rawCreated is String) {
      parsedDate = DateTime.tryParse(rawCreated);
    }

    return MessageItemDto(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      senderRole: (json['senderRole'] ?? json['role'] ?? 'parent').toString(),
      subject: (json['subject'] ?? '').toString(),
      message: (json['message'] ?? json['content'] ?? json['text'] ?? '')
          .toString(),
      isRead: json['isRead'] == true || json['read'] == true,
      status: (json['status'] ?? 'sent').toString(),
      createdAt: parsedDate,
    );
  }

  MessageItemEntity toEntity({String? resolvedSenderName}) {
    return MessageItemEntity(
      id: id,
      senderRole: senderRole,
      subject: subject,
      message: message,
      isRead: isRead,
      status: status,
      createdAt: createdAt,
      senderName: resolvedSenderName,
    );
  }
}

class TeacherContactDto {
  const TeacherContactDto({
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

  factory TeacherContactDto.fromJson(Map<String, dynamic> json) {
    return TeacherContactDto(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      designation: json['designation']?.toString(),
      department: json['department']?.toString(),
      batchId: json['batchId']?.toString(),
      batchName: json['batchName']?.toString(),
      role: json['role']?.toString(),
    );
  }

  TeacherContactEntity toEntity() {
    return TeacherContactEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      designation: designation,
      department: department,
      batchId: batchId,
      batchName: batchName,
      role: role,
    );
  }
}

class MessagesDataDto {
  const MessagesDataDto({
    required this.studentId,
    required this.studentName,
    this.activeTeacher,
    this.teachers = const [],
    this.messages = const [],
  });

  final String studentId;
  final String studentName;
  final TeacherContactDto? activeTeacher;
  final List<TeacherContactDto> teachers;
  final List<MessageItemDto> messages;

  factory MessagesDataDto.fromJson(Map<String, dynamic> json) {
    final studentMap = json['student'] is Map<String, dynamic>
        ? json['student'] as Map<String, dynamic>
        : <String, dynamic>{};

    final studentId = (studentMap['_id'] ?? studentMap['id'] ?? '').toString();
    final sFirst = studentMap['firstName']?.toString() ?? '';
    final sLast = studentMap['lastName']?.toString() ?? '';
    final studentName = '$sFirst $sLast'.trim();

    TeacherContactDto? activeTeacher;
    if (json['activeTeacher'] is Map<String, dynamic>) {
      activeTeacher = TeacherContactDto.fromJson(
        json['activeTeacher'] as Map<String, dynamic>,
      );
    }

    final teachersList = <TeacherContactDto>[];
    if (json['teachers'] is List) {
      for (final t in json['teachers'] as List) {
        if (t is Map<String, dynamic>) {
          teachersList.add(TeacherContactDto.fromJson(t));
        }
      }
    }

    final messagesList = <MessageItemDto>[];
    if (json['messages'] is List) {
      for (final m in json['messages'] as List) {
        if (m is Map<String, dynamic>) {
          messagesList.add(MessageItemDto.fromJson(m));
        }
      }
    }

    return MessagesDataDto(
      studentId: studentId,
      studentName: studentName.isNotEmpty ? studentName : 'Student',
      activeTeacher: activeTeacher,
      teachers: teachersList,
      messages: messagesList,
    );
  }

  MessagesDataEntity toEntity() {
    final activeTeacherEntity = activeTeacher?.toEntity();
    final teachersEntities = teachers.map((t) => t.toEntity()).toList();

    final messageEntities = messages.map((m) {
      String? senderName;
      if (m.senderRole.toLowerCase() == 'teacher') {
        senderName =
            activeTeacherEntity?.fullName ??
            (teachersEntities.isNotEmpty
                ? teachersEntities.first.fullName
                : 'Instructor');
      } else if (m.senderRole.toLowerCase() == 'parent') {
        senderName = 'You';
      } else if (m.senderRole.toLowerCase() == 'system') {
        senderName = 'TrueLern Support';
      }
      return m.toEntity(resolvedSenderName: senderName);
    }).toList();

    return MessagesDataEntity(
      studentId: studentId,
      studentName: studentName,
      activeTeacher: activeTeacherEntity,
      teachers: teachersEntities,
      messages: messageEntities,
    );
  }
}
