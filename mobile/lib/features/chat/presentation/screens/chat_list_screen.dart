import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/chat_provider.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/models/message.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key, this.initialListingId, this.initialHostId});

  final String? initialListingId;
  final String? initialHostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChatListView(
      initialListingId: initialListingId,
      initialHostId: initialHostId,
    );
  }
}

class _ChatListView extends ConsumerStatefulWidget {
  const _ChatListView({
    required this.initialListingId,
    required this.initialHostId,
  });

  final String? initialListingId;
  final String? initialHostId;

  @override
  ConsumerState<_ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends ConsumerState<_ChatListView> {
  bool _openingInitial = false;
  bool _initialHandled = false;

  Future<bool> _confirmDeleteChat() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text(
          'This conversation will be removed from your chat list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(chatThreadsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Chats'),
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AppErrorView(
          message: 'Could not load chats.',
          onRetry: () => ref.invalidate(chatThreadsProvider),
        ),
        data: (threads) {
          _maybeOpenInitialThread(threads);

          if (threads.isEmpty) {
            return const EmptyStateView(
              title: 'No conversations yet',
              subtitle: 'Start chat from listing details to contact hosts.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: threads.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final thread = threads[index];
              return Dismissible(
                key: ValueKey('thread-${thread.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFD64545),
                  ),
                ),
                confirmDismiss: (_) async {
                  final shouldDelete = await _confirmDeleteChat();
                  if (!shouldDelete) {
                    return false;
                  }
                  await ref.read(chatActionsProvider).deleteThread(thread.id);
                  return false;
                },
                child: ListTile(
                  tileColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(thread.counterpartName),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A5EFF),
                      ),
                    ),
                  ),
                  title: Text(
                    thread.counterpartName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          thread.listingTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF425166),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          thread.lastMessage?.isNotEmpty == true
                              ? thread.lastMessage!
                              : 'Tap to start conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          thread.listingLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7A8397),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  trailing: thread.unreadCount > 0
                      ? CircleAvatar(
                          radius: 11,
                          backgroundColor: const Color(0xFF1A5EFF),
                          child: Text(
                            '${thread.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF74809B),
                        ),
                  onTap: () => _openThread(context, ref, thread),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _maybeOpenInitialThread(List<ChatThread> threads) {
    if (_initialHandled || _openingInitial) {
      return;
    }
    final listingId = widget.initialListingId;
    final hostId = widget.initialHostId;
    if (listingId == null || listingId.isEmpty) {
      _initialHandled = true;
      return;
    }

    _openingInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final existing = threads
            .where((thread) => thread.listingId == listingId)
            .toList(growable: false);
        if (existing.isNotEmpty) {
          _openThread(context, ref, existing.first);
          return;
        }

        if (hostId != null && hostId.isNotEmpty) {
          final created = await ref
              .read(chatActionsProvider)
              .createOrGetThread(listingId: listingId, hostUserId: hostId);
          if (!mounted) {
            return;
          }
          _openThread(context, ref, created);
        }
      } catch (_) {
        // Keep chat list usable even if pre-open fails.
      } finally {
        _initialHandled = true;
        _openingInitial = false;
      }
    });
  }

  void _openThread(BuildContext context, WidgetRef ref, ChatThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _ThreadView(thread: thread)),
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

  Future<bool> _confirmDeleteChat() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text('This will remove the whole conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<bool> _confirmDeleteMessage() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text(
          'This message will be removed from the conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.thread.id));
    final currentUserId =
        ref.watch(authControllerProvider).valueOrNull?.user?.id ??
        'user_demo_1';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.thread.counterpartName),
              Text(
                widget.thread.listingTitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _showThreadInfo(context),
              icon: const Icon(Icons.info_outline),
            ),
            IconButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final shouldDelete = await _confirmDeleteChat();
                if (!shouldDelete) {
                  return;
                }
                await ref
                    .read(chatActionsProvider)
                    .deleteThread(widget.thread.id);
                if (mounted) {
                  navigator.pop();
                }
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E7F2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.thread.counterpartName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2430),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.thread.listingTitle,
                    style: const TextStyle(
                      color: Color(0xFF425166),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.thread.listingLocation,
                    style: const TextStyle(
                      color: Color(0xFF7A8397),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => AppErrorView(
                  message: 'Could not load messages.',
                  onRetry: () =>
                      ref.invalidate(chatMessagesProvider(widget.thread.id)),
                ),
                data: (messages) => _buildMessages(messages, currentUserId),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(List<Message> messages, String currentUserId) {
    if (messages.isEmpty) {
      return const EmptyStateView(
        title: 'No messages',
        subtitle: 'Send first message to start conversation.',
      );
    }

    return ListView.separated(
      reverse: true,
      itemCount: messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        final mine = message.senderUserId == currentUserId;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: GestureDetector(
              onLongPress: () async {
                final shouldDelete = await _confirmDeleteMessage();
                if (!shouldDelete) {
                  return;
                }
                await ref
                    .read(chatActionsProvider)
                    .deleteMessage(
                      threadId: widget.thread.id,
                      messageId: message.id,
                    );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: mine
                      ? const Color(0xFF1A5EFF)
                      : const Color(0xFFF2F5FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.body,
                      style: TextStyle(
                        color: mine ? Colors.white : const Color(0xFF1F2430),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeLabel(message.sentAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: mine
                            ? const Color(0xB3FFFFFF)
                            : const Color(0xFF7A8397),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _timeLabel(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _sending = true);
    try {
      await ref
          .read(chatActionsProvider)
          .sendMessage(threadId: widget.thread.id, content: text);
      _controller.clear();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _showThreadInfo(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.thread.counterpartName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2430),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.thread.counterpartRole,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.thread.listingTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2430),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.thread.listingLocation,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      '${RouteNames.listingDetails}/${widget.thread.listingId}',
                    );
                  },
                  icon: const Icon(Icons.home_work_outlined),
                  label: const Text('Open apartment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return 'U';
  }
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
