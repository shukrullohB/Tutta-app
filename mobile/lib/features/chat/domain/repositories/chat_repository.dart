import '../models/chat_thread.dart';
import '../models/message.dart';

abstract interface class ChatRepository {
  Future<List<ChatThread>> getThreads();

  Future<List<Message>> getMessages(String threadId);

  Future<Message> sendMessage({
    required String threadId,
    required String content,
  });
}

