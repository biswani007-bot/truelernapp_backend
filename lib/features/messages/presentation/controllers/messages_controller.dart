import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/messages_repository.dart';
import '../../data/repositories/messages_repository_impl.dart';
import 'messages_state.dart';

class MessagesController extends Notifier<MessagesState> {
  late final MessagesRepository _repository;

  @override
  MessagesState build() {
    _repository = ref.watch(messagesRepositoryProvider);
    return const MessagesInitial();
  }

  /// Resets state on logout or account switching.
  void reset() {
    state = const MessagesInitial();
  }

  Future<void> loadMessages({
    required String studentId,
    bool isRefresh = false,
  }) async {
    final current = state;
    if (!isRefresh &&
        current is MessagesLoading &&
        current.studentId == studentId) {
      return;
    }

    if (!isRefresh) {
      state = MessagesLoading(studentId: studentId);
    }

    try {
      final data = await _repository.getMessages(studentId: studentId);
      state = MessagesLoaded(data: data, studentId: studentId);
    } catch (e) {
      final errorMsg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      state = MessagesError(message: errorMsg, studentId: studentId);
    }
  }

  Future<bool> sendMessage({required String message, String? subject}) async {
    final current = state;
    if (current is! MessagesLoaded) return false;

    state = current.copyWith(isSending: true);

    try {
      final sentItem = await _repository.sendMessage(
        studentId: current.studentId,
        message: message,
        subject: subject,
      );

      final updatedMessages = List<MessageItemEntity>.from(
        current.data.messages,
      )..add(sentItem);
      final updatedData = current.data.copyWith(messages: updatedMessages);

      state = current.copyWith(data: updatedData, isSending: false);
      return true;
    } catch (e) {
      state = current.copyWith(isSending: false);
      rethrow;
    }
  }

  Future<void> markAsRead({required String messageId}) async {
    final current = state;
    if (current is! MessagesLoaded) return;

    try {
      await _repository.markAsRead(
        studentId: current.studentId,
        messageId: messageId,
      );

      final updatedMessages = current.data.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(isRead: true);
        }
        return m;
      }).toList();

      state = current.copyWith(
        data: current.data.copyWith(messages: updatedMessages),
      );
    } catch (_) {
      // Non-blocking mark-as-read failure
    }
  }

  Future<void> markAllAsRead() async {
    final current = state;
    if (current is! MessagesLoaded) return;

    final unread = current.data.messages.where((m) => !m.isRead).toList();
    if (unread.isEmpty) return;

    // Optimistically update
    final updatedMessages = current.data.messages
        .map((m) => m.copyWith(isRead: true))
        .toList();
    state = current.copyWith(
      data: current.data.copyWith(messages: updatedMessages),
    );

    // Call API for each unread
    for (final item in unread) {
      try {
        await _repository.markAsRead(
          studentId: current.studentId,
          messageId: item.id,
        );
      } catch (_) {}
    }
  }
}

final messagesControllerProvider =
    NotifierProvider<MessagesController, MessagesState>(MessagesController.new);
