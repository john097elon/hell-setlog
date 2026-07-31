import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../domain/entities/character_identity.dart';
import '../../../domain/entities/party.dart';
import '../../../domain/usecases/calculate_character_growth.dart';
import '../../character/application/character_identity_controller.dart';
import '../../character/application/character_providers.dart';
import '../../character/presentation/monster_page.dart';
import '../../character/presentation/widgets/growth_view.dart';
import '../../../domain/entities/post.dart';
import '../../feed/application/post_providers.dart';
import '../../feed/presentation/post_detail_page.dart';
import '../../notifications/application/notification_providers.dart';
import '../../party/application/party_providers.dart';
import '../../party/presentation/widgets/party_mission_card.dart';
import '../../stats/application/stats_providers.dart';
import '../../settings/application/settings_controller.dart';

/// 홈. 내 캐릭터와 파티 현황을 먼저 보여주고 운동으로 이어준다.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
    return AppScreen(
      title: '헬셋로그',
      actions: <Widget>[
        IconButton(
          tooltip: '피드 전체 보기',
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
      onRefresh: () async {
        ref
          ..invalidate(characterVolumesProvider)
          ..invalidate(characterWeeklyVolumesProvider)
          ..invalidate(myPartiesProvider)
          ..invalidate(weeklyVolumeProvider);
      },
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: AppPagePadding(
            top: AppSpacing.sm,
            child: Column(
              children: <Widget>[
                const _CharacterCard(),
                _SectionHeader(
                  title: '내 파티',
                  actionLabel: '전체',
                  onAction: () => context.go('/party'),
                ),
                const SizedBox(height: AppSpacing.sm),
                const _PartySection(),
                const SizedBox(height: AppSpacing.xl),
                const _WeekSummary(),
                const SizedBox(height: AppSpacing.xl),
                _SectionHeader(
                  title: '피드',
                  actionLabel: '전체',
                  onAction: () => context.push('/feed'),
                ),
                const SizedBox(height: AppSpacing.md),
                const _FeedPreview(),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => context.go('/workout'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('운동 시작하기'),
                ),
              ],
            ),
          ),
        ),
      ],
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
      return AppSection(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
          ),
        ],
      );
    }
    final growth = ref.watch(characterGrowthProvider).valueOrNull;
    return AppSection(
      children: <Widget>[
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => context.go('/workout/monster'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _CharacterSummary(
                      identity: identity,
                      growth: growth,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: t.faintText),
                ],
              ),
            ),
          ),
        ),
      ],
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
        const SizedBox(height: AppSpacing.xs),
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
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: value.evolutionProgress,
              minHeight: 8,
              color: t.brand,
              backgroundColor: t.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
    final weightUnit = ref.watch(
      settingsControllerProvider.select((state) => state.weightUnit),
    );
    final volumes = ref
        .watch(weeklyVolumeProvider())
        .valueOrNull
        ?.when(ok: (value) => value, err: (_) => null);
    final total =
        volumes?.values.fold<double>(0, (sum, value) => sum + value) ?? 0;
    final days = volumes?.values.where((value) => value > 0).length ?? 0;
    return AppMetricRow(
      metrics: <AppMetric>[
        AppMetric(
          label: '이번 주 볼륨',
          value: formatCompactWeight(total, unit: weightUnit),
        ),
        AppMetric(label: '운동일', value: '$days일'),
      ],
    );
  }
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
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.sm),
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
    return AppSection(
      children: <Widget>[
        AppRow(
          title: message,
          subtitle: '파티 찾아보기',
          leading: Icon(Icons.groups_outlined, color: t.mutedText),
          onTap: () => context.go('/party'),
        ),
      ],
    );
  }
}

/// 홈에서 보는 피드 맛보기. 파티 피드를 먼저 보여주고 없으면 공개 피드를 쓴다.
class _FeedPreview extends ConsumerWidget {
  const _FeedPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final party = ref.watch(myPartiesProvider).valueOrNull?.firstOrNull;
    final feed = party == null
        ? ref.watch(publicFeedProvider(null))
        : ref.watch(partyFeedProvider(party.id));
    return feed.when(
      loading: () => const AppMissionSkeleton(),
      error: (_, _) => const _FeedEmpty(message: '피드를 불러오지 못했습니다'),
      data: (posts) => posts.isEmpty
          ? const _FeedEmpty(message: '아직 올라온 기록이 없어요')
          : AppSection(
              margin: EdgeInsets.zero,
              children: <Widget>[
                for (final post in posts.take(3))
                  AppRow(
                    title: post.authorName ?? '회원',
                    subtitle: post.caption.isEmpty
                        ? (post.bodyPart ?? '운동 기록')
                        : post.caption,
                    leading: _FeedThumb(post: post),
                    value: post.volumeKg == null
                        ? null
                        : '${formatCompactNumber(post.volumeKg!)} kg',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PostDetailPage(post: post),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FeedThumb extends StatelessWidget {
  const _FeedThumb({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isVideo = post.mediaKind == PostMediaKind.video;
    final url = post.mediaUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: 26,
        height: 26,
        child: url.isEmpty || isVideo
            ? ColoredBox(
                color: t.surface,
                child: Icon(
                  isVideo ? Icons.videocam_rounded : Icons.article_outlined,
                  size: 15,
                  color: t.faintText,
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: t.surface,
                  child: Icon(
                    Icons.image_outlined,
                    size: 15,
                    color: t.faintText,
                  ),
                ),
              ),
      ),
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => AppSection(
    margin: EdgeInsets.zero,
    children: <Widget>[
      AppRow(
        title: message,
        subtitle: '기록을 공유하면 여기에 모여요',
        onTap: () => context.push('/feed'),
      ),
    ],
  );
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
      Text(title, style: AppText.sectionLabel(context)),
      const Spacer(),
      TextButton(onPressed: onAction, child: Text(actionLabel)),
    ],
  );
}
