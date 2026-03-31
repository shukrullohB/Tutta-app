import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/chat_repository.dart';

class ApiChatRepository implements ChatRepository {
  const ApiChatRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<ChatThread>> getThreads() async {
    final result = await _apiClient.get(ApiEndpoints.chatThreads);

    return result.when(
      success: (data) =>
          ApiResponseParser.extractList(data).map(_mapThread).toList(growable: false),
      failure: _throwFailure,
    );
  }

  @override
  Future<List<Message>> getMessages(String threadId) async {
    final result = await _apiClient.get(ApiEndpoints.chatThreadMessages(threadId));

    return result.when(
      success: (data) =>
          ApiResponseParser.extractList(data).map(_mapMessage).toList(growable: false),
      failure: _throwFailure,
    );
  }

  @override
  Future<Message> sendMessage({
    required String threadId,
    required String content,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.chatThreadMessages(threadId),
      data: <String, dynamic>{'content': content},
    );

    return result.when(
      success: (data) => _mapMessage(ApiResponseParser.extractMap(data)),
      failure: _throwFailure,
    );
  }

  ChatThread _mapThread(Map<String, dynamic> payload) {
    final last = payload['last_message'];
    final lastContent = last is Map<String, dynamic> ? last['content']?.toString() : null;

    return ChatThread(
      id: payload['id'].toString(),
      listingId: payload['listing']?.toString() ?? '',
      guestUserId: payload['guest_id']?.toString() ?? '',
      hostUserId: payload['host_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(payload['created_at']?.toString() ?? '') ?? DateTime.now(),
      lastMessage: lastContent,
      unreadCount: payload['unread_count'] is int
          ? payload['unread_count'] as int
          : int.tryParse(payload['unread_count']?.toString() ?? '') ?? 0,
    );
  }

  Message _mapMessage(Map<String, dynamic> payload) {
    return Message(
      id: payload['id'].toString(),
      conversationId: payload['thread']?.toString() ?? '',
      senderUserId: payload['sender_id']?.toString() ?? '',
      body: payload['content']?.toString() ?? '',
      sentAt: DateTime.tryParse(payload['created_at']?.toString() ?? '') ?? DateTime.now(),
      isRead: payload['is_read'] == true,
    );
  }

  Never _throwFailure(Failure failure) {
    throw AppException(
      failure.message,
      code: failure.code,
      statusCode: failure.statusCode,
    );
  }
}

