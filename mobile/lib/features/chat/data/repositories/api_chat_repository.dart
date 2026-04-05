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
      success: (data) => ApiResponseParser.extractList(
        data,
      ).map(_mapThread).toList(growable: false),
      failure: _throwFailure,
    );
  }

  @override
  Future<ChatThread> createOrGetThread({
    required String listingId,
    required String guestUserId,
    required String hostUserId,
  }) async {
    final listingPk = _parseRequiredPk(
      listingId,
      fieldName: 'listingId',
      uiLabel: 'listing',
    );
    final guestPk = _parseRequiredPk(
      guestUserId,
      fieldName: 'guestUserId',
      uiLabel: 'guest user',
    );
    final hostPk = _parseRequiredPk(
      hostUserId,
      fieldName: 'hostUserId',
      uiLabel: 'host user',
    );

    final result = await _apiClient.post(
      ApiEndpoints.chatThreads,
      data: <String, dynamic>{
        'listing': listingPk,
        'guest_id': guestPk,
        'host_id': hostPk,
      },
    );

    return result.when(
      success: (data) => _mapThread(ApiResponseParser.extractMap(data)),
      failure: _throwFailure,
    );
  }

  @override
  Future<List<Message>> getMessages(String threadId) async {
    final threadPk = _parseRequiredPk(
      threadId,
      fieldName: 'threadId',
      uiLabel: 'thread',
    );
    final result = await _apiClient.get(
      ApiEndpoints.chatThreadMessages(threadPk.toString()),
    );

    return result.when(
      success: (data) => ApiResponseParser.extractList(
        data,
      ).map(_mapMessage).toList(growable: false),
      failure: _throwFailure,
    );
  }

  @override
  Future<Message> sendMessage({
    required String threadId,
    required String content,
  }) async {
    final threadPk = _parseRequiredPk(
      threadId,
      fieldName: 'threadId',
      uiLabel: 'thread',
    );
    final result = await _apiClient.post(
      ApiEndpoints.chatThreadMessages(threadPk.toString()),
      data: <String, dynamic>{'content': content},
    );

    return result.when(
      success: (data) => _mapMessage(ApiResponseParser.extractMap(data)),
      failure: _throwFailure,
    );
  }

  @override
  Future<Message> updateMessage({
    required String threadId,
    required String messageId,
    required String content,
  }) async {
    final threadPk = _parseRequiredPk(
      threadId,
      fieldName: 'threadId',
      uiLabel: 'thread',
    );
    final messagePk = _parseRequiredPk(
      messageId,
      fieldName: 'messageId',
      uiLabel: 'message',
    );
    final result = await _apiClient.patch(
      ApiEndpoints.chatThreadMessageById(
        threadPk.toString(),
        messagePk.toString(),
      ),
      data: <String, dynamic>{'content': content},
    );

    return result.when(
      success: (data) => _mapMessage(ApiResponseParser.extractMap(data)),
      failure: _throwFailure,
    );
  }

  @override
  Future<void> deleteThread(String threadId) async {
    final threadPk = _parseRequiredPk(
      threadId,
      fieldName: 'threadId',
      uiLabel: 'thread',
    );
    final result = await _apiClient.delete(
      ApiEndpoints.chatThreadById(threadPk.toString()),
    );
    result.when(
      success: (_) => const <String, dynamic>{},
      failure: _throwFailure,
    );
  }

  @override
  Future<void> deleteMessage({
    required String threadId,
    required String messageId,
  }) async {
    final threadPk = _parseRequiredPk(
      threadId,
      fieldName: 'threadId',
      uiLabel: 'thread',
    );
    final messagePk = _parseRequiredPk(
      messageId,
      fieldName: 'messageId',
      uiLabel: 'message',
    );
    final result = await _apiClient.delete(
      ApiEndpoints.chatThreadMessageById(
        threadPk.toString(),
        messagePk.toString(),
      ),
    );
    result.when(
      success: (_) => const <String, dynamic>{},
      failure: _throwFailure,
    );
  }

  ChatThread _mapThread(Map<String, dynamic> payload) {
    final last = payload['last_message'];
    final lastContent = last is Map<String, dynamic>
        ? last['content']?.toString()
        : null;

    return ChatThread(
      id: payload['id'].toString(),
      listingId: payload['listing']?.toString() ?? '',
      guestUserId: payload['guest_id']?.toString() ?? '',
      hostUserId: payload['host_id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(payload['created_at']?.toString() ?? '') ??
          DateTime.now(),
      lastMessage: lastContent,
      unreadCount: payload['unread_count'] is int
          ? payload['unread_count'] as int
          : int.tryParse(payload['unread_count']?.toString() ?? '') ?? 0,
      counterpartName: payload['counterpart_name']?.toString() ?? 'Host',
      counterpartRole: payload['counterpart_role']?.toString() ?? 'Host',
      listingTitle: payload['listing_title']?.toString() ?? 'Apartment',
      listingLocation: payload['listing_location']?.toString() ?? 'Uzbekistan',
    );
  }

  Message _mapMessage(Map<String, dynamic> payload) {
    return Message(
      id: payload['id'].toString(),
      conversationId: payload['thread']?.toString() ?? '',
      senderUserId: payload['sender_id']?.toString() ?? '',
      body: payload['content']?.toString() ?? '',
      sentAt:
          DateTime.tryParse(payload['created_at']?.toString() ?? '') ??
          DateTime.now(),
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

  int _parseRequiredPk(
    String raw, {
    required String fieldName,
    required String uiLabel,
  }) {
    final trimmed = raw.trim();
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      throw AppException(
        'Invalid $uiLabel id for chat. Please refresh listing data and try again.',
        code: 'invalid_$fieldName',
      );
    }
    return parsed;
  }
}
