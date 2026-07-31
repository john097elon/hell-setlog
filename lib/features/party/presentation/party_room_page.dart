import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/party.dart';
import '../../../domain/entities/party_member.dart';
import '../../../domain/entities/post.dart';
import '../application/party_providers.dart';
import 'widgets/party_chat_panel.dart';
import '../../../core/formatting/app_format.dart';
import 'widgets/party_character_gallery.dart';
import 'widgets/party_mission_card.dart';

/// 파티 한 곳의 구성원과 활동을 보여준다.
class PartyRoomPage extends ConsumerWidget {
  /// 파티 방 화면을 생성한다.
  const PartyRoomPage({required this.partyId, super.key});

  /// 표시할 파티 식별자다.
  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final party = ref
        .watch(myPartiesProvider)
        .valueOrNull
        ?.where((item) => item.id == partyId)
        .firstOrNull;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        title: Text(party?.name ?? '파티'),
        actions: <Widget>[
          IconButton(
            tooltip: '채팅 열기',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => FractionallySizedBox(
                heightFactor: 0.85,
                child: PartyChatPanel(initialPartyId: partyId),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          if (party != null) _Header(party: party),
          const SizedBox(height: 20),
          // 파티의 이번 주 공동 목표를 멤버보다 먼저 보여준다.
          PartyMissionCard(partyId: partyId, allowGoalEditing: true),
          const SizedBox(height: 24),
          const _SectionTitle(title: '파티원 캐릭터'),
          const SizedBox(height: 8),
          PartyCharacterGallery(partyId: partyId),
          const SizedBox(height: 24),
          const _SectionTitle(title: '멤버'),
          const SizedBox(height: 8),
          _Members(partyId: partyId),
          const SizedBox(height: 24),
          const _SectionTitle(title: '파티 피드'),
          const SizedBox(height: 8),
          _Feed(partyId: partyId),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _confirmLeave(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('파티 나가기'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('파티를 나갈까요?'),
        content: const Text('나가면 파티 피드와 채팅을 볼 수 없습니다.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref.read(partyRepositoryProvider).leaveParty(partyId);
    if (!context.mounted) return;
    result.when(
      ok: (_) {
        ref.invalidate(myPartiesProvider);
        context.pop();
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.party});

  final Party party;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final code = party.joinCode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            party.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: t.text,
            ),
          ),
          if ((party.description ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              party.description!,
              style: TextStyle(fontSize: 13.5, color: t.mutedText),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              if (party.region != null) _Chip(label: party.region!),
              if (party.focus != null) _Chip(label: party.focus!),
              _Chip(label: '${party.memberCount}/${party.maxMembers}명'),
            ],
          ),
          if ((code ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text(
                  '참여 코드 $code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.text,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _copyCode(context, code!),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('복사'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('참여 코드를 복사했습니다.')));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: context.tokens.text,
    ),
  );
}

class _Members extends ConsumerWidget {
  const _Members({required this.partyId});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return ref
        .watch(partyMembersProvider(partyId))
        .when(
          loading: () => const SizedBox(height: 72, child: AppLoading()),
          error: (_, _) =>
              Text('멤버를 불러오지 못했습니다.', style: TextStyle(color: t.mutedText)),
          data: (members) => members.isEmpty
              ? Text('멤버가 없습니다.', style: TextStyle(color: t.mutedText))
              : Column(
                  children: <Widget>[
                    for (final member in members) _MemberTile(member: member),
                  ],
                ),
        );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final PartyMember member;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final avatar = member.avatarUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: t.bg,
              shape: BoxShape.circle,
              border: Border.all(color: t.border),
            ),
            child: (avatar ?? '').isEmpty
                ? _Monogram(name: member.nickname)
                : Image.network(
                    avatar!,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _Monogram(name: member.nickname),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.nickname,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
          ),
          if (member.role == 'owner') const _Chip(label: '파티장'),
        ],
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Text(
    initialOf(name),
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: context.tokens.text,
    ),
  );
}

class _Feed extends ConsumerWidget {
  const _Feed({required this.partyId});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return ref
        .watch(partyFeedProvider(partyId))
        .when(
          loading: () => const SizedBox(height: 96, child: AppLoading()),
          error: (_, _) =>
              Text('피드를 불러오지 못했습니다.', style: TextStyle(color: t.mutedText)),
          data: (posts) => posts.isEmpty
              ? Text('아직 파티원의 기록이 없습니다.', style: TextStyle(color: t.mutedText))
              : Column(
                  children: <Widget>[
                    for (final post in posts) _PostTile(post: post),
                  ],
                ),
        );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.border),
            ),
            child: post.mediaUrl.isEmpty
                ? Icon(Icons.image_outlined, color: t.faintText, size: 22)
                : Image.network(
                    post.mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.image_outlined, color: t.faintText),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  post.authorName ?? '파티원',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  post.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: t.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: t.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: t.mutedText,
        ),
      ),
    );
  }
}
