import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/runtime_flags.dart';
import '../../../core/network/api_client.dart';
import '../data/repositories/api_chat_repository.dart';
import '../data/repositories/fake_chat_repository.dart';
import '../domain/models/chat_thread.dart';
import '../domain/models/message.dart';
import '../domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (!RuntimeFlags.useFakeChat) {
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

  Future<void> sendMessage({
    required String threadId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      return;
    }

    await _ref.read(chatRepositoryProvider).sendMessage(
          threadId: threadId,
          content: text,
        );
    _ref.invalidate(chatMessagesProvider(threadId));
    _ref.invalidate(chatThreadsProvider);
  }
}

final chatActionsProvider = Provider<ChatActions>((ref) => ChatActions(ref));
