import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_list.dart';
import '../../../core/widgets/app_screen.dart';
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
    final party = ref
        .watch(myPartiesProvider)
        .valueOrNull
        ?.where((item) => item.id == partyId)
        .firstOrNull;
    return AppScreen(
      title: party?.name ?? '파티',
      actions: <Widget>[
        IconButton(
          tooltip: '채팅 열기',
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => FractionallySizedBox(
              heightFactor: 0.85,
              child: PartyChatPanel(initialPartyId: partyId),
            ),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
        ),
      ],
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: AppPagePadding(
            top: AppSpacing.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (party != null) _Header(party: party),
                PartyMissionCard(partyId: partyId, allowGoalEditing: true),
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle(title: '파티원 캐릭터'),
                const SizedBox(height: AppSpacing.sm),
                PartyCharacterGallery(partyId: partyId),
                const SizedBox(height: AppSpacing.xl),
                _Members(partyId: partyId),
                _Feed(partyId: partyId),
                OutlinedButton.icon(
                  onPressed: () => _confirmLeave(context, ref),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('파티 나가기'),
                ),
              ],
            ),
          ),
        ),
      ],
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
    return AppSection(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                party.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: t.text,
                ),
              ),
              if ((party.description ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  party.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: t.mutedText),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  if (party.region != null) _Chip(label: party.region!),
                  if (party.focus != null) _Chip(label: party.focus!),
                  _Chip(label: '${party.memberCount}/${party.maxMembers}명'),
                ],
              ),
            ],
          ),
        ),
        if ((code ?? '').isNotEmpty)
          AppRow(
            title: '참여 코드',
            value: code,
            trailing: IconButton(
              tooltip: '참여 코드 복사',
              onPressed: () => _copyCode(context, code!),
              icon: const Icon(Icons.copy_rounded),
            ),
          ),
      ],
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
  Widget build(BuildContext context) =>
      Text(title, style: AppText.sectionLabel(context));
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
          loading: () => const AppSection(
            title: '멤버',
            children: <Widget>[SizedBox(height: 72, child: AppLoading())],
          ),
          error: (_, _) => AppSection(
            title: '멤버',
            children: <Widget>[
              AppRow(
                title: '멤버를 불러오지 못했습니다',
                leading: Icon(Icons.error_outline, color: t.mutedText),
              ),
            ],
          ),
          data: (members) => AppSection(
            title: '멤버',
            children: members.isEmpty
                ? const <Widget>[AppRow(title: '멤버가 없습니다')]
                : <Widget>[
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
    return AppRow(
      title: member.nickname,
      value: member.role == 'owner' ? '파티장' : null,
      leading: Container(
        width: 26,
        height: 26,
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
                width: 26,
                height: 26,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _Monogram(name: member.nickname),
              ),
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
      fontSize: 12,
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
          loading: () => const AppSection(
            title: '파티 피드',
            children: <Widget>[SizedBox(height: 96, child: AppLoading())],
          ),
          error: (_, _) => AppSection(
            title: '파티 피드',
            children: <Widget>[
              AppRow(
                title: '피드를 불러오지 못했습니다',
                leading: Icon(Icons.error_outline, color: t.mutedText),
              ),
            ],
          ),
          data: (posts) => AppSection(
            title: '파티 피드',
            children: posts.isEmpty
                ? const <Widget>[AppRow(title: '아직 파티원의 기록이 없습니다')]
                : <Widget>[for (final post in posts) _PostTile(post: post)],
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
    return AppRow(
      title: post.authorName ?? '파티원',
      subtitle: post.caption,
      leading: Container(
        width: 26,
        height: 26,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: t.border),
        ),
        child: post.mediaUrl.isEmpty
            ? Icon(Icons.image_outlined, color: t.faintText, size: 18)
            : Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.image_outlined, color: t.faintText, size: 18),
              ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
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
