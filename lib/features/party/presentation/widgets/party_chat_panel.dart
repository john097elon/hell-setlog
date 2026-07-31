import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/supabase/supabase_init.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../domain/entities/party.dart';
import '../../../../domain/entities/party_message.dart';
import '../../application/party_providers.dart';

/// Displays and sends messages for one of the current user's parties.
class PartyChatPanel extends ConsumerStatefulWidget {
  const PartyChatPanel({this.initialPartyId, super.key});

  final String? initialPartyId;

  @override
  ConsumerState<PartyChatPanel> createState() => _PartyChatPanelState();
}

class _PartyChatPanelState extends ConsumerState<PartyChatPanel> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedPartyId;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String partyId) async {
    final body = _controller.text.trim();
    if (body.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    final result = await ref
        .read(partyChatControllerProvider)
        .sendMessage(partyId, body);
    if (!mounted) return;
    result.when(
      ok: (_) {
        _controller.clear();
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final parties = ref.watch(myPartiesProvider);
    return parties.when(
      loading: () => const AppLoading(),
      error: (_, _) => const _ChatError(),
      data: (parties) {
        if (parties.isEmpty) return const _NoPartyChat();
        final partyId = _activePartyId(parties);
        return Column(
          children: <Widget>[
            _PartySelector(
              parties: parties,
              selectedPartyId: partyId,
              onChanged: (id) => setState(() => _selectedPartyId = id),
            ),
            Expanded(
              child: _Messages(key: ValueKey(partyId), partyId: partyId),
            ),
            _MessageInput(
              controller: _controller,
              isSending: _isSending,
              onSend: () => _send(partyId),
            ),
          ],
        );
      },
    );
  }

  String _activePartyId(List<Party> parties) {
    final ids = parties.map((party) => party.id).toSet();
    if (ids.contains(_selectedPartyId)) return _selectedPartyId!;
    if (ids.contains(widget.initialPartyId)) return widget.initialPartyId!;
    return parties.first.id;
  }
}

class _PartySelector extends StatelessWidget {
  const _PartySelector({
    required this.parties,
    required this.selectedPartyId,
    required this.onChanged,
  });

  final List<Party> parties;
  final String selectedPartyId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.sm,
    ),
    child: DropdownButtonFormField<String>(
      key: ValueKey(selectedPartyId),
      initialValue: selectedPartyId,
      decoration: InputDecoration(labelText: context.l10n.party),
      items: parties
          .map(
            (party) => DropdownMenuItem<String>(
              value: party.id,
              child: Text(party.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );
}

class _Messages extends ConsumerStatefulWidget {
  const _Messages({required this.partyId, super.key});

  final String partyId;

  @override
  ConsumerState<_Messages> createState() => _MessagesState();
}

class _MessagesState extends ConsumerState<_Messages> {
  final ScrollController _scrollController = ScrollController();
  String? _latestMessageId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(partyMessagesProvider(widget.partyId));
    final userId = ref.watch(supabaseClientProvider)?.auth.currentUser?.id;
    return messages.when(
      loading: () => const AppLoading(),
      error: (_, _) => const _ChatError(),
      data: (messages) {
        if (messages.isEmpty) return const _EmptyMessages();
        final ordered = List<PartyMessage>.of(messages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _followLatest(ordered.last.id);
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.xl),
          itemCount: ordered.length,
          itemBuilder: (context, index) => _MessageBubble(
            message: ordered[index],
            isMine: ordered[index].userId == userId,
          ),
        );
      },
    );
  }

  void _followLatest(String latestMessageId) {
    if (_latestMessageId == latestMessageId) return;
    final shouldFollow =
        !_scrollController.hasClients ||
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent;
    _latestMessageId = latestMessageId;
    if (!shouldFollow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final PartyMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isMine ? tokens.brandDim : tokens.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isMine ? null : Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message.authorName ?? '파티원',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isMine ? tokens.onBrand : tokens.mutedText,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(message.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _relativeTime(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isMine ? tokens.onBrand : tokens.faintText,
                fontFeatures: kTabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return '방금';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    if (difference.inDays < 7) return '${difference.inDays}일 전';
    return '${time.month}/${time.day}';
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                labelText: context.l10n.partyChat,
                hintText: context.l10n.partyChatHint,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: context.l10n.partySend,
            button: true,
            child: IconButton.filled(
              tooltip: context.l10n.partySend,
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: AppSpacing.lg,
                      height: AppSpacing.lg,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}

class _NoPartyChat extends StatelessWidget {
  const _NoPartyChat();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Text('파티에 참여하면 채팅할 수 있습니다', textAlign: TextAlign.center),
    ),
  );
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('아직 메시지가 없습니다'));
}

class _ChatError extends StatelessWidget {
  const _ChatError();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('채팅을 불러오지 못했습니다'));
}
