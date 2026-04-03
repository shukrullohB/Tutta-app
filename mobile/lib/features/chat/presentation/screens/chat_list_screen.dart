import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../application/chat_provider.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/models/message.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({
    super.key,
    this.embedded = false,
    this.initialListingId,
    this.initialHostId,
  });

  final bool embedded;
  final String? initialListingId;
  final String? initialHostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialListingId != null && initialListingId!.isNotEmpty) {
      return _DirectThreadResolver(
        embedded: embedded,
        listingId: initialListingId!,
        hostId: initialHostId,
      );
    }

    return _ChatThreadsView(embedded: embedded);
  }
}

class _ChatThreadsView extends ConsumerWidget {
  const _ChatThreadsView({required this.embedded});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);

    final content = RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(chatThreadsProvider);
        await ref.read(chatThreadsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, embedded ? 16 : 20, 16, 28),
        children: [
          _ThreadsHeader(
            title: _tr(
              context,
              en: 'Messages',
              ru: 'Сообщения',
              uz: 'Xabarlar',
            ),
            subtitle: _tr(
              context,
              en: 'All conversations with hosts in one place.',
              ru: 'Все переписки с хозяевами в одном месте.',
              uz: 'Hostlar bilan barcha chatlar bir joyda.',
            ),
          ),
          const SizedBox(height: 18),
          threadsAsync.when(
            data: (threads) {
              if (threads.isEmpty) {
                return _EmptyChatsCard(embedded: embedded);
              }

              return Column(
                children: [
                  for (var index = 0; index < threads.length; index++) ...[
                    _ConversationCard(
                      thread: threads[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ChatThreadScreen(thread: threads[index]),
                        ),
                      ),
                    ),
                    if (index != threads.length - 1) const SizedBox(height: 14),
                  ],
                ],
              );
            },
            loading: () => Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: _surface(),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _ErrorCard(
              title: _tr(
                context,
                en: 'Unable to load chats',
                ru: 'Не удалось загрузить чаты',
                uz: 'Chatlarni yuklab boʼlmadi',
              ),
              subtitle: error.toString(),
              actionLabel: _tr(
                context,
                en: 'Try again',
                ru: 'Повторить',
                uz: 'Qayta urinish',
              ),
              onTap: () => ref.invalidate(chatThreadsProvider),
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return ColoredBox(color: AppColors.background, child: content);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }
            context.go(RouteNames.home);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _tr(context, en: 'Chats', ru: 'Чаты', uz: 'Chatlar'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
      ),
      body: content,
    );
  }
}

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.thread});

  final ChatThread thread;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        ref.watch(authControllerProvider).valueOrNull?.user?.id ?? '';
    final messagesAsync = ref.watch(chatMessagesProvider(widget.thread.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 68,
        leading: IconButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }
            context.go(RouteNames.home);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: SizedBox(
          height: 44,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _openCounterpartProfile,
              child: Row(
                children: [
                  _ChatAvatar(
                    seed: widget.thread.counterpartName,
                    size: 38,
                    textSize: 15,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.thread.counterpartName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _tr(
                            context,
                            en: 'Tap to open profile',
                            ru: 'Нажмите, чтобы открыть профиль',
                            uz: 'Profilni ochish uchun bosing',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: _tr(
              context,
              en: 'Open profile',
              ru: 'Открыть профиль',
              uz: 'Profilni ochish',
            ),
            onPressed: _openCounterpartProfile,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.background, AppColors.backgroundWarm],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (messages) => _MessagesPane(
                    messages: messages,
                    currentUserId: currentUserId,
                    thread: widget.thread,
                    onThreadInfoTap: _openListingDetails,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: _ErrorCard(
                      title: _tr(
                        context,
                        en: 'Unable to load messages',
                        ru: 'Не удалось загрузить сообщения',
                        uz: 'Xabarlarni yuklab boʼlmadi',
                      ),
                      subtitle: error.toString(),
                      actionLabel: _tr(
                        context,
                        en: 'Try again',
                        ru: 'Повторить',
                        uz: 'Qayta urinish',
                      ),
                      onTap: () => ref.invalidate(
                        chatMessagesProvider(widget.thread.id),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _MessageComposer(
        controller: _messageController,
        isSending: _isSending,
        onSend: _sendMessage,
      ),
    );
  }

  String get _counterpartUserId {
    final currentUserId =
        ref.read(authControllerProvider).valueOrNull?.user?.id ?? '';
    if (currentUserId == widget.thread.hostUserId) {
      return widget.thread.guestUserId;
    }
    return widget.thread.hostUserId;
  }

  void _openCounterpartProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfileScreen(
          userId: _counterpartUserId,
          displayName: widget.thread.counterpartName,
        ),
      ),
    );
  }

  void _openListingDetails() {
    context.push(RouteNames.listingDetailsById(widget.thread.listingId));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(chatActionsProvider)
          .sendMessage(threadId: widget.thread.id, content: text);
      _messageController.clear();
      ref.invalidate(chatMessagesProvider(widget.thread.id));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

class _DirectThreadResolver extends ConsumerStatefulWidget {
  const _DirectThreadResolver({
    required this.embedded,
    required this.listingId,
    required this.hostId,
  });

  final bool embedded;
  final String listingId;
  final String? hostId;

  @override
  ConsumerState<_DirectThreadResolver> createState() =>
      _DirectThreadResolverState();
}

class _DirectThreadResolverState extends ConsumerState<_DirectThreadResolver> {
  late final Future<ChatThread> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolveThread();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChatThread>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(
                _tr(
                  context,
                  en: 'Opening chat',
                  ru: 'Открываем чат',
                  uz: 'Chat ochilmoqda',
                ),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(_tr(context, en: 'Chat', ru: 'Чат', uz: 'Chat')),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: _ErrorCard(
                title: _tr(
                  context,
                  en: 'Unable to open chat',
                  ru: 'Не удалось открыть чат',
                  uz: 'Chatni ochib boʼlmadi',
                ),
                subtitle:
                    snapshot.error?.toString() ??
                    _tr(
                      context,
                      en: 'Please try again.',
                      ru: 'Пожалуйста, попробуйте снова.',
                      uz: 'Iltimos, yana urinib koʼring.',
                    ),
                actionLabel: _tr(
                  context,
                  en: 'Go back',
                  ru: 'Назад',
                  uz: 'Ortga',
                ),
                onTap: () => context.pop(),
              ),
            ),
          );
        }

        return ChatThreadScreen(thread: snapshot.data!);
      },
    );
  }

  Future<ChatThread> _resolveThread() async {
    final hostId = widget.hostId;
    if (hostId == null || hostId.isEmpty) {
      throw StateError('Host id is required to open chat.');
    }
    return ref
        .read(chatActionsProvider)
        .createOrGetThread(listingId: widget.listingId, hostUserId: hostId);
  }
}

class _ThreadsHeader extends StatelessWidget {
  const _ThreadsHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ChatAvatar(seed: thread.counterpartName, size: 56, textSize: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            thread.counterpartName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatThreadTime(thread.createdAt),
                          style: const TextStyle(
                            color: AppColors.iconMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thread.listingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessage?.trim().isNotEmpty == true
                                ? thread.lastMessage!
                                : _tr(
                                    context,
                                    en: 'Open the conversation to continue chatting.',
                                    ru: 'Откройте переписку, чтобы продолжить общение.',
                                    uz: 'Davom etish uchun chatni oching.',
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (thread.unreadCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${thread.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: AppColors.iconMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            thread.listingLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.iconMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesPane extends StatelessWidget {
  const _MessagesPane({
    required this.messages,
    required this.currentUserId,
    required this.thread,
    required this.onThreadInfoTap,
  });

  final List<Message> messages;
  final String currentUserId;
  final ChatThread thread;
  final VoidCallback onThreadInfoTap;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _ThreadInfoCard(
            thread: thread,
            onTap: onThreadInfoTap,
            text: _tr(
              context,
              en: 'No messages yet. Start the conversation below.',
              ru: 'Сообщений пока нет. Начните разговор ниже.',
              uz: 'Hali xabarlar yoʼq. Suhbatni pastdan boshlang.',
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ThreadInfoCard(thread: thread, onTap: onThreadInfoTap),
          );
        }

        final message = messages[index - 1];
        final isMine = message.senderUserId == currentUserId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isMine ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(22).copyWith(
                    bottomRight: isMine ? const Radius.circular(8) : null,
                    bottomLeft: isMine ? null : const Radius.circular(8),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F0F172A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.body,
                        style: TextStyle(
                          color: isMine ? Colors.white : AppColors.text,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.sentAt),
                            style: TextStyle(
                              color: isMine
                                  ? Colors.white
                                  : AppColors.iconMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 6),
                            Icon(
                              message.isRead
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFFE6DDCF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: _tr(
                    context,
                    en: 'Type a message',
                    ru: 'Напишите сообщение',
                    uz: 'Xabar yozing',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 54,
            height: 54,
            child: FilledButton(
              onPressed: isSending ? null : onSend,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatsCard extends StatelessWidget {
  const _EmptyChatsCard({required this.embedded});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _tr(
              context,
              en: 'No conversations yet',
              ru: 'Переписок пока нет',
              uz: 'Hali chatlar yoʼq',
            ),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tr(
              context,
              en: 'Open a stay, tap message, and the conversation will appear here.',
              ru: 'Откройте жильё, нажмите «Написать», и переписка появится здесь.',
              uz: 'Turar joyni ochib, “Yozish” tugmasini bosing va chat shu yerda paydo boʼladi.',
            ),
            style: const TextStyle(color: AppColors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push(RouteNames.search),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.search_rounded),
            label: Text(
              _tr(
                context,
                en: 'Browse stays',
                ru: 'Открыть жильё',
                uz: 'Turar joylarni koʼrish',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _ThreadInfoCard extends StatelessWidget {
  const _ThreadInfoCard({required this.thread, required this.onTap, this.text});

  final ChatThread thread;
  final VoidCallback onTap;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.listingTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          thread.listingLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: AppColors.iconMuted,
                  ),
                ],
              ),
              if (text != null) ...[
                const SizedBox(height: 12),
                Text(
                  text!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.seed, this.size = 62, this.textSize = 22});

  final String seed;
  final double size;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySoft, AppColors.secondarySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(seed),
        style: TextStyle(
          color: AppColors.primaryDeep,
          fontSize: textSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

BoxDecoration _surface() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(
        color: Color(0x120F172A),
        blurRadius: 16,
        offset: Offset(0, 10),
      ),
    ],
  );
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'TT';
  }
  return parts.map((part) => part[0].toUpperCase()).join();
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatThreadTime(DateTime value) {
  final now = DateTime.now();
  final sameDay =
      value.year == now.year &&
      value.month == now.month &&
      value.day == now.day;
  if (sameDay) {
    return _formatTime(value);
  }
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}';
}

String _tr(
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
