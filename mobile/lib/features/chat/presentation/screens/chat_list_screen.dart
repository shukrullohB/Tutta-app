import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../application/chat_provider.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/models/message.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AppErrorView(
          message: 'Could not load chats.',
          onRetry: () => ref.invalidate(chatThreadsProvider),
        ),
        data: (threads) {
          if (threads.isEmpty) {
            return const EmptyStateView(
              title: 'No conversations yet',
              subtitle: 'Start chat from listing details to contact hosts.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final thread = threads[index];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text('Listing #${thread.listingId}'),
                subtitle: Text(
                  thread.lastMessage?.isNotEmpty == true
                      ? thread.lastMessage!
                      : 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: thread.unreadCount > 0
                    ? CircleAvatar(
                        radius: 12,
                        child: Text('${thread.unreadCount}'),
                      )
                    : null,
                onTap: () => _openThread(context, ref, thread),
              );
            },
          );
        },
      ),
    );
  }

  void _openThread(BuildContext context, WidgetRef ref, ChatThread thread) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ThreadView(thread: thread),
    );
  }
}

class _ThreadView extends ConsumerStatefulWidget {
  const _ThreadView({required this.thread});

  final ChatThread thread;

  @override
  ConsumerState<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends ConsumerState<_ThreadView> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.thread.id));

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Text(
              'Chat: Listing #${widget.thread.listingId}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => AppErrorView(
                  message: 'Could not load messages.',
                  onRetry: () => ref.invalidate(chatMessagesProvider(widget.thread.id)),
                ),
                data: _buildMessages,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(List<Message> messages) {
    if (messages.isEmpty) {
      return const EmptyStateView(
        title: 'No messages',
        subtitle: 'Send first message to start conversation.',
      );
    }

    return ListView.separated(
      reverse: true,
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(message.body),
        );
      },
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(chatActionsProvider).sendMessage(
            threadId: widget.thread.id,
            content: text,
          );
      _controller.clear();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}
