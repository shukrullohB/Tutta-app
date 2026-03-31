class ChatThread {
  const ChatThread({
    required this.id,
    required this.listingId,
    required this.guestUserId,
    required this.hostUserId,
    required this.createdAt,
    required this.lastMessage,
    required this.unreadCount,
  });

  final String id;
  final String listingId;
  final String guestUserId;
  final String hostUserId;
  final DateTime createdAt;
  final String? lastMessage;
  final int unreadCount;
}
