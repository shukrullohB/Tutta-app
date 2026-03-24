import '../../domain/models/chat_thread.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/chat_repository.dart';

class FakeChatRepository implements ChatRepository {
  final Map<String, List<Message>> _messagesByThread = <String, List<Message>>{
    '1': <Message>[
      Message(
        id: 'm1',
        conversationId: '1',
        senderUserId: '2',
        body: 'Assalomu alaykum, check-in vaqti 14:00.',
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Message(
        id: 'm2',
        conversationId: '1',
        senderUserId: '1',
        body: 'Rahmat, tushundim.',
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ],
  };

  @override
  Future<List<ChatThread>> getThreads() async {
    return <ChatThread>[
      ChatThread(
        id: '1',
        listingId: '10',
        guestUserId: '1',
        hostUserId: '2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        lastMessage: _messagesByThread['1']?.last.body,
        unreadCount: 0,
      ),
    ];
  }

  @override
  Future<List<Message>> getMessages(String threadId) async {
    return List<Message>.from(_messagesByThread[threadId] ?? const <Message>[]);
  }

  @override
  Future<Message> sendMessage({
    required String threadId,
    required String content,
  }) async {
    final list = _messagesByThread.putIfAbsent(threadId, () => <Message>[]);
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: threadId,
      senderUserId: '1',
      body: content,
      sentAt: DateTime.now(),
      isRead: false,
    );
    list.add(message);
    return message;
  }
}

