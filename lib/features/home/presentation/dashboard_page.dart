import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/character_identity.dart';
import '../../../domain/entities/party.dart';
import '../../../domain/usecases/calculate_character_growth.dart';
import '../../character/application/character_identity_controller.dart';
import '../../character/application/character_providers.dart';
import '../../character/presentation/monster_page.dart';
import '../../character/presentation/widgets/growth_view.dart';
import '../../notifications/application/notification_providers.dart';
import '../../party/application/party_providers.dart';
import '../../party/presentation/widgets/party_mission_card.dart';
import '../../stats/application/stats_providers.dart';

/// 홈. 내 캐릭터와 파티 현황을 먼저 보여주고 운동으로 이어준다.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final unread = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        title: const Text('헬셋로그'),
        actions: <Widget>[
          IconButton(
            tooltip: '피드',
            onPressed: () => context.push('/feed'),
            icon: const Icon(Icons.dynamic_feed_outlined),
          ),
          IconButton(
            tooltip: '알림',
            onPressed: () => context.push('/notifications'),
            icon: Badge.count(
              count: unread,
              isLabelVisible: unread > 0,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(characterVolumesProvider)
            ..invalidate(characterWeeklyVolumesProvider)
            ..invalidate(myPartiesProvider)
            ..invalidate(weeklyVolumeProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            const _CharacterCard(),
            const SizedBox(height: AppSpacing.lg),
            const _WeekSummary(),
            const SizedBox(height: AppSpacing.xxl),
            _SectionHeader(
              title: '내 파티',
              actionLabel: '전체',
              onAction: () => context.go('/party'),
            ),
            const SizedBox(height: AppSpacing.md),
            const _PartySection(),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => context.go('/workout'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('운동 시작하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 내 캐릭터 요약. 아직 없으면 만들기로 안내한다.
class _CharacterCard extends ConsumerWidget {
  const _CharacterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final identity = ref.watch(characterIdentityProvider).valueOrNull;
    if (identity == null) {
      return _Panel(
        child: Column(
          children: <Widget>[
            Icon(Icons.pets_rounded, size: 40, color: t.brand),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '함께 운동할 캐릭터를 만들어요',
              style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => openCharacterSetup(context),
              child: const Text('캐릭터 만들기'),
            ),
          ],
        ),
      );
    }
    final growth = ref.watch(characterGrowthProvider).valueOrNull;
    return _Panel(
      onTap: () => context.go('/workout/monster'),
      child: Row(
        children: <Widget>[
          Image.asset(
            stageAsset(identity.species, growth?.evolutionStage ?? 0),
            width: 84,
            height: 84,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) =>
                Icon(Icons.pets_rounded, size: 60, color: t.brand),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _CharacterSummary(identity: identity, growth: growth),
          ),
        ],
      ),
    );
  }
}

class _CharacterSummary extends StatelessWidget {
  const _CharacterSummary({required this.identity, required this.growth});

  final CharacterIdentity identity;
  final CharacterGrowth? growth;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final value = growth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          identity.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: t.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value == null
              ? traitCopy(identity.trait).name
              : 'Lv. ${value.totalLevel} · ${kStageNames[value.evolutionStage]}',
          style: TextStyle(
            fontSize: 12.5,
            color: t.mutedText,
            fontFeatures: kTabularFigures,
          ),
        ),
        if (value != null) ...<Widget>[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: value.evolutionProgress,
              minHeight: 8,
              color: t.brand,
              backgroundColor: t.surface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${evolutionHint(value)} · 이번 주 +${formatCompactNumber(value.weeklyXp)} XP',
            style: TextStyle(
              fontSize: 11.5,
              color: t.faintText,
              fontFeatures: kTabularFigures,
            ),
          ),
        ],
      ],
    );
  }
}

/// 이번 주 내 운동 요약.
class _WeekSummary extends ConsumerWidget {
  const _WeekSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final volumes = ref
        .watch(weeklyVolumeProvider())
        .valueOrNull
        ?.when(ok: (value) => value, err: (_) => null);
    final total =
        volumes?.values.fold<double>(0, (sum, value) => sum + value) ?? 0;
    final days = volumes?.values.where((value) => value > 0).length ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: <Widget>[
          _metric(t, '이번 주 볼륨', '${formatCompactNumber(total)} kg'),
          Container(
            width: 0.5,
            height: 30,
            color: t.borderStrong.withValues(alpha: 0.4),
          ),
          _metric(t, '운동일', '$days일'),
        ],
      ),
    );
  }

  Widget _metric(AppTokens t, String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: t.faintText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: t.text,
            fontFeatures: kTabularFigures,
          ),
        ),
      ],
    ),
  );
}

/// 내 파티와 이번 주 미션.
class _PartySection extends ConsumerWidget {
  const _PartySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(myPartiesProvider)
      .when(
        loading: () => const AppMissionSkeleton(),
        error: (_, _) => const _PartyEmpty(message: '파티를 불러오지 못했습니다'),
        data: (parties) => parties.isEmpty
            ? const _PartyEmpty(message: '파티에 참여하면 함께 목표를 채워요')
            : Column(
                children: <Widget>[
                  for (final party in parties.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PartyBlock(party: party),
                    ),
                ],
              ),
      );
}

class _PartyBlock extends StatelessWidget {
  const _PartyBlock({required this.party});

  final Party party;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () => context.push('/party/room/${party.id}'),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    party.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                    ),
                  ),
                ),
                Text(
                  '${party.memberCount}/${party.maxMembers}명',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: t.mutedText,
                    fontFeatures: kTabularFigures,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: t.faintText, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        PartyMissionCard(partyId: party.id, showContributions: false),
      ],
    );
  }
}

class _PartyEmpty extends StatelessWidget {
  const _PartyEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return _Panel(
      onTap: () => context.go('/party'),
      child: Column(
        children: <Widget>[
          Icon(Icons.groups_outlined, size: 34, color: t.mutedText),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 13.5, color: t.mutedText)),
          const SizedBox(height: 10),
          Text(
            '파티 찾아보기',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: t.brand,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: context.tokens.text,
        ),
      ),
      const Spacer(),
      TextButton(onPressed: onAction, child: Text(actionLabel)),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.border),
          ),
          child: child,
        ),
      ),
    );
  }
}
