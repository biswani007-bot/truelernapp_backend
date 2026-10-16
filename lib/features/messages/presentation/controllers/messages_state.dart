import '../../domain/entities/message_entity.dart';

sealed class MessagesState {
  const MessagesState();
}

class MessagesInitial extends MessagesState {
  const MessagesInitial();
}

class MessagesLoading extends MessagesState {
  const MessagesLoading({this.studentId});
  final String? studentId;
}

class MessagesLoaded extends MessagesState {
  const MessagesLoaded({
    required this.data,
    required this.studentId,
    this.isSending = false,
  });

  final MessagesDataEntity data;
  final String studentId;
  final bool isSending;

  MessagesLoaded copyWith({
    MessagesDataEntity? data,
    String? studentId,
    bool? isSending,
  }) {
    return MessagesLoaded(
      data: data ?? this.data,
      studentId: studentId ?? this.studentId,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagesLoaded &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          studentId == other.studentId &&
          isSending == other.isSending;

  @override
  int get hashCode => data.hashCode ^ studentId.hashCode ^ isSending.hashCode;
}

class MessagesError extends MessagesState {
  const MessagesError({required this.message, this.studentId});

  final String message;
  final String? studentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagesError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          studentId == other.studentId;

  @override
  int get hashCode => message.hashCode ^ (studentId?.hashCode ?? 0);
}
