import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/runtime_flags.dart';
import '../../../core/network/api_client.dart';
import '../../auth/application/auth_controller.dart';
import '../data/repositories/api_chat_repository.dart';
import '../data/repositories/fake_chat_repository.dart';
import '../domain/models/chat_thread.dart';
import '../domain/models/message.dart';
import '../domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  // Chat thread creation requires numeric PKs from real backend entities.
  // When listings are in fake mode, keep chat in fake mode to avoid contract mismatch.
  if (!RuntimeFlags.useFakeChat && !RuntimeFlags.useFakeListings) {
    return ApiChatRepository(ref.watch(apiClientProvider));
  }
  return FakeChatRepository();
});

final chatThreadsProvider = FutureProvider<List<ChatThread>>((ref) async {
  return ref.watch(chatRepositoryProvider).getThreads();
});

final chatMessagesProvider = FutureProvider.family<List<Message>, String>((
  ref,
  threadId,
) async {
  return ref.watch(chatRepositoryProvider).getMessages(threadId);
});

class ChatActions {
  const ChatActions(this._ref);

  final Ref _ref;

  Future<ChatThread> createOrGetThread({
    required String listingId,
    required String hostUserId,
  }) async {
    final currentUserId = _ref
        .read(authControllerProvider)
        .valueOrNull
        ?.user
        ?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      throw StateError('Authenticated user is required to open chat.');
    }

    final thread = await _ref
        .read(chatRepositoryProvider)
        .createOrGetThread(
          listingId: listingId,
          guestUserId: currentUserId,
          hostUserId: hostUserId,
        );

    _ref.invalidate(chatThreadsProvider);
    _ref.invalidate(chatMessagesProvider(thread.id));
    return thread;
  }

  Future<void> sendMessage({
    required String threadId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      return;
    }

    await _ref
        .read(chatRepositoryProvider)
        .sendMessage(threadId: threadId, content: text);
    _ref.invalidate(chatMessagesProvider(threadId));
    _ref.invalidate(chatThreadsProvider);
  }

  Future<void> deleteThread(String threadId) async {
    await _ref.read(chatRepositoryProvider).deleteThread(threadId);
    _ref.invalidate(chatMessagesProvider(threadId));
    _ref.invalidate(chatThreadsProvider);
  }

  Future<void> updateMessage({
    required String threadId,
    required String messageId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      return;
    }

    await _ref
        .read(chatRepositoryProvider)
        .updateMessage(threadId: threadId, messageId: messageId, content: text);
    _ref.invalidate(chatMessagesProvider(threadId));
    _ref.invalidate(chatThreadsProvider);
  }

  Future<void> deleteMessage({
    required String threadId,
    required String messageId,
  }) async {
    await _ref
        .read(chatRepositoryProvider)
        .deleteMessage(threadId: threadId, messageId: messageId);
    _ref.invalidate(chatMessagesProvider(threadId));
    _ref.invalidate(chatThreadsProvider);
  }
}

final chatActionsProvider = Provider<ChatActions>((ref) => ChatActions(ref));
