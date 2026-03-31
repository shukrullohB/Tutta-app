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
  Widget build(BuildContext context, WidgetRef ref) => _ChatListView(
    initialListingId: initialListingId,
    initialHostId: initialHostId,
  );
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
      builder: (d) => AlertDialog(
        title: Text(
          _t(
            d,
            en: 'Delete chat?',
            ru: 'Удалить чат?',
            uz: 'Chat o‘chirilsinmi?',
          ),
        ),
        content: Text(
          _t(
            d,
            en: 'This conversation will be removed from your chat list.',
            ru: 'Этот диалог исчезнет из списка чатов.',
            uz: 'Bu suhbat chat ro‘yxatidan olib tashlanadi.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(MaterialLocalizations.of(d).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(d).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            child: Text(_t(d, en: 'Delete', ru: 'Удалить', uz: 'O‘chirish')),
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
        title: Text(_t(context, en: 'Chats', ru: 'Чаты', uz: 'Chatlar')),
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AppErrorView(
          message: _t(
            context,
            en: 'Could not load chats.',
            ru: 'Не удалось загрузить чаты.',
            uz: 'Chatlarni yuklab bo‘lmadi.',
          ),
          onRetry: () => ref.invalidate(chatThreadsProvider),
        ),
        data: (threads) {
          _maybeOpenInitialThread(threads);
          if (threads.isEmpty) {
            return EmptyStateView(
              title: _t(
                context,
                en: 'No conversations yet',
                ru: 'Пока нет чатов',
                uz: 'Hozircha chat yo‘q',
              ),
              subtitle: _t(
                context,
                en: 'Open any apartment and message the person directly.',
                ru: 'Откройте апартаменты и напишите человеку напрямую.',
                uz: 'Istalgan e’lonni ochib, odamga to‘g‘ridan-to‘g‘ri yozing.',
              ),
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
                  final ok = await _confirmDeleteChat();
                  if (!ok) return false;
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
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEAF1FF),
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
                              : _t(
                                  context,
                                  en: 'Tap to start conversation',
                                  ru: 'Нажмите, чтобы начать диалог',
                                  uz: 'Suhbatni boshlash uchun bosing',
                                ),
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
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _ThreadView(thread: thread),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _maybeOpenInitialThread(List<ChatThread> threads) {
    if (_initialHandled || _openingInitial) return;
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
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _ThreadView(thread: existing.first),
            ),
          );
          return;
        }
        if (hostId != null && hostId.isNotEmpty) {
          final created = await ref
              .read(chatActionsProvider)
              .createOrGetThread(listingId: listingId, hostUserId: hostId);
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _ThreadView(thread: created),
            ),
          );
        }
      } catch (_) {
      } finally {
        _initialHandled = true;
        _openingInitial = false;
      }
    });
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
  final Set<String> _editedMessageIds = <String>{};

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
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEAF1FF),
                child: Text(
                  _initials(widget.thread.counterpartName),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A5EFF),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.thread.counterpartName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.thread.listingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _showThreadInfo(context),
              icon: const Icon(Icons.info_outline),
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
              child: Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 10),
                  FilledButton.tonalIcon(
                    onPressed: () => _showThreadInfo(context),
                    icon: const Icon(Icons.contact_phone_outlined),
                    label: Text(
                      _t(context, en: 'Contact', ru: 'Контакт', uz: 'Kontakt'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => AppErrorView(
                  message: _t(
                    context,
                    en: 'Could not load messages.',
                    ru: 'Не удалось загрузить сообщения.',
                    uz: 'Xabarlarni yuklab bo‘lmadi.',
                  ),
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
                      decoration: InputDecoration(
                        hintText: _t(
                          context,
                          en: 'Type a message',
                          ru: 'Введите сообщение',
                          uz: 'Xabar yozing',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: Text(
                      _t(context, en: 'Send', ru: 'Отправить', uz: 'Yuborish'),
                    ),
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
      return EmptyStateView(
        title: _t(
          context,
          en: 'No messages',
          ru: 'Пока нет сообщений',
          uz: 'Hozircha xabar yo‘q',
        ),
        subtitle: _t(
          context,
          en: 'Send the first message to start conversation.',
          ru: 'Отправьте первое сообщение, чтобы начать диалог.',
          uz: 'Suhbatni boshlash uchun birinchi xabarni yuboring.',
        ),
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
              onLongPress: mine ? () => _editMessage(message) : null,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeLabel(message.sentAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: mine
                                ? const Color(0xB3FFFFFF)
                                : const Color(0xFF7A8397),
                          ),
                        ),
                        if (_editedMessageIds.contains(message.id)) ...[
                          const SizedBox(width: 8),
                          Text(
                            _t(
                              context,
                              en: 'edited',
                              ru: 'изменено',
                              uz: 'tahrirlangan',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: mine
                                  ? const Color(0xB3FFFFFF)
                                  : const Color(0xFF7A8397),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
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

  Future<void> _editMessage(Message message) async {
    final c = TextEditingController(text: message.body);
    final updated = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(
          _t(
            d,
            en: 'Edit message',
            ru: 'Изменить сообщение',
            uz: 'Xabarni tahrirlash',
          ),
        ),
        content: TextField(
          controller: c,
          minLines: 2,
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _t(
              d,
              en: 'Update your message',
              ru: 'Измените сообщение',
              uz: 'Xabarni yangilang',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(),
            child: Text(MaterialLocalizations.of(d).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(d).pop(c.text.trim()),
            child: Text(_t(d, en: 'Save', ru: 'Сохранить', uz: 'Saqlash')),
          ),
        ],
      ),
    );
    c.dispose();
    if (updated == null || updated.isEmpty || updated == message.body) return;
    await ref
        .read(chatActionsProvider)
        .updateMessage(
          threadId: widget.thread.id,
          messageId: message.id,
          content: updated,
        );
    if (mounted) setState(() => _editedMessageIds.add(message.id));
  }

  String _timeLabel(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(chatActionsProvider)
          .sendMessage(threadId: widget.thread.id, content: text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showThreadInfo(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
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
                  Navigator.of(sheet).pop();
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  _t(
                    sheet,
                    en: 'Open conversation',
                    ru: 'Открыть диалог',
                    uz: 'Suhbatni ochish',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(sheet).pop();
                  context.push(
                    '${RouteNames.listingDetails}/${widget.thread.listingId}',
                  );
                },
                icon: const Icon(Icons.home_work_outlined),
                label: Text(
                  _t(
                    sheet,
                    en: 'Open apartment',
                    ru: 'Открыть апартаменты',
                    uz: 'Apartamentni ochish',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

String _t(
  BuildContext context, {
  required String en,
  required String ru,
  required String uz,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      return ru;
    case 'uz':
      return uz;
    default:
      return en;
  }
}
