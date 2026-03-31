import '../../domain/models/chat_thread.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/chat_repository.dart';

class FakeChatRepository implements ChatRepository {
  final List<ChatThread> _threads = <ChatThread>[
    ChatThread(
      id: '1',
      listingId: 'l1',
      guestUserId: 'user_demo_1',
      hostUserId: 'h1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      lastMessage: null,
      unreadCount: 0,
      counterpartName: 'Aziza Karimova',
      counterpartRole: 'Host',
      listingTitle: 'Cozy apartment near Tashkent Metro',
      listingLocation: 'Tashkent, Yunusabad',
    ),
    ChatThread(
      id: '2',
      listingId: 'l4',
      guestUserId: 'user_demo_1',
      hostUserId: 'h4',
      createdAt: DateTime.now().subtract(const Duration(hours: 19)),
      lastMessage: null,
      unreadCount: 1,
      counterpartName: 'Dilshod Rakhimov',
      counterpartRole: 'Host',
      listingTitle: 'Modern loft in City Center',
      listingLocation: 'Tashkent, Mirobod',
    ),
    ChatThread(
      id: '3',
      listingId: 'l5',
      guestUserId: 'user_demo_1',
      hostUserId: 'h5',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      lastMessage: null,
      unreadCount: 0,
      counterpartName: 'Madina Yuldasheva',
      counterpartRole: 'Host',
      listingTitle: 'Family apartment near Magic City',
      listingLocation: 'Tashkent, Chilonzor',
    ),
  ];

  final Map<String, List<Message>> _messagesByThread = <String, List<Message>>{
    '1': <Message>[
      Message(
        id: 'm1',
        conversationId: '1',
        senderUserId: 'h1',
        body: 'Assalomu alaykum, check-in vaqti 14:00.',
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Message(
        id: 'm2',
        conversationId: '1',
        senderUserId: 'user_demo_1',
        body: 'Rahmat, tushundim.',
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ],
    '2': <Message>[
      Message(
        id: 'm3',
        conversationId: '2',
        senderUserId: 'user_demo_1',
        body: 'Hi, is late check-in possible around 23:00?',
        sentAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      Message(
        id: 'm4',
        conversationId: '2',
        senderUserId: 'h4',
        body: 'Yes, self check-in is available.',
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
    '3': <Message>[
      Message(
        id: 'm5',
        conversationId: '3',
        senderUserId: 'h5',
        body: 'Apartment is ready for family with kids.',
        sentAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  };

  @override
  Future<List<ChatThread>> getThreads() async {
    return _threads
        .map(
          (thread) => ChatThread(
            id: thread.id,
            listingId: thread.listingId,
            guestUserId: thread.guestUserId,
            hostUserId: thread.hostUserId,
            createdAt: thread.createdAt,
            lastMessage: _messagesByThread[thread.id]?.last.body,
            unreadCount: thread.unreadCount,
            counterpartName: thread.counterpartName,
            counterpartRole: thread.counterpartRole,
            listingTitle: thread.listingTitle,
            listingLocation: thread.listingLocation,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ChatThread> createOrGetThread({
    required String listingId,
    required String guestUserId,
    required String hostUserId,
  }) async {
    final existing = (await getThreads())
        .where((thread) {
          return thread.listingId == listingId &&
              thread.guestUserId == guestUserId &&
              thread.hostUserId == hostUserId;
        })
        .toList(growable: false);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final threadId = DateTime.now().millisecondsSinceEpoch.toString();
    _messagesByThread.putIfAbsent(threadId, () => <Message>[]);
    final created = ChatThread(
      id: threadId,
      listingId: listingId,
      guestUserId: guestUserId,
      hostUserId: hostUserId,
      createdAt: DateTime.now(),
      lastMessage: null,
      unreadCount: 0,
      counterpartName: _hostNameFor(hostUserId),
      counterpartRole: 'Host',
      listingTitle: _listingTitleFor(listingId),
      listingLocation: _listingLocationFor(listingId),
    );
    _threads.add(created);
    return created;
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
      senderUserId: 'user_demo_1',
      body: content,
      sentAt: DateTime.now(),
      isRead: false,
    );
    list.add(message);
    return message;
  }

  @override
  Future<void> deleteThread(String threadId) async {
    _threads.removeWhere((thread) => thread.id == threadId);
    _messagesByThread.remove(threadId);
  }

  @override
  Future<void> deleteMessage({
    required String threadId,
    required String messageId,
  }) async {
    final list = _messagesByThread[threadId];
    if (list == null) {
      return;
    }
    list.removeWhere((message) => message.id == messageId);
  }

  String _hostNameFor(String hostUserId) {
    switch (hostUserId) {
      case 'h1':
        return 'Aziza Karimova';
      case 'h4':
        return 'Dilshod Rakhimov';
      case 'h5':
        return 'Madina Yuldasheva';
      default:
        return 'Host';
    }
  }

  String _listingTitleFor(String listingId) {
    switch (listingId) {
      case 'l1':
        return 'Cozy apartment near Tashkent Metro';
      case 'l4':
        return 'Modern loft in City Center';
      case 'l5':
        return 'Family apartment near Magic City';
      default:
        return 'Apartment';
    }
  }

  String _listingLocationFor(String listingId) {
    switch (listingId) {
      case 'l1':
        return 'Tashkent, Yunusabad';
      case 'l4':
        return 'Tashkent, Mirobod';
      case 'l5':
        return 'Tashkent, Chilonzor';
      default:
        return 'Uzbekistan';
    }
  }
}
