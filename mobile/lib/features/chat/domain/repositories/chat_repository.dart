import '../models/chat_thread.dart';
import '../models/message.dart';

abstract interface class ChatRepository {
  Future<List<ChatThread>> getThreads();

  Future<ChatThread> createOrGetThread({
    required String listingId,
    required String guestUserId,
    required String hostUserId,
  });

  Future<List<Message>> getMessages(String threadId);

  Future<Message> sendMessage({
    required String threadId,
    required String content,
  });

  Future<Message> updateMessage({
    required String threadId,
    required String messageId,
    required String content,
  });

  Future<void> deleteThread(String threadId);

  Future<void> deleteMessage({
    required String threadId,
    required String messageId,
  });
}
