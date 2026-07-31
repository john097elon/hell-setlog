import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/app_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/party_mission.dart';
import '../../application/party_providers.dart';

/// 파티의 이번 주 공동 목표. 혼자가 아니라는 걸 보여주는 자리다.
class PartyMissionCard extends ConsumerWidget {
  const PartyMissionCard({
    required this.partyId,
    this.showContributions = true,
    super.key,
  });

  final String partyId;
  final bool showContributions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return ref
        .watch(partyMissionProvider(partyId))
        .when(
          loading: () => const AppMissionSkeleton(),
          error: (_, _) => const SizedBox.shrink(),
          data: (mission) => Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: mission.isComplete
                    ? t.brand.withValues(alpha: 0.5)
                    : t.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      mission.isComplete
                          ? Icons.emoji_events_rounded
                          : Icons.flag_rounded,
                      size: 18,
                      color: mission.isComplete ? t.brand : t.mutedText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '이번 주 파티 미션',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                    ),
                    Text(
                      '${mission.doneSessions} / ${mission.goalSessions}회',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                        fontFeatures: kTabularFigures,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: mission.progress,
                    minHeight: 10,
                    color: t.brand,
                    backgroundColor: t.surface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mission.isComplete
                      ? '이번 주 목표를 함께 채웠어요'
                      : '${mission.remaining}회 남았어요. 파티원과 같이 채워봐요',
                  style: TextStyle(fontSize: 12.5, color: t.faintText),
                ),
                if (showContributions && mission.contributions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  for (final person in mission.contributions.take(5))
                    _ContributionRow(person: person),
                ],
              ],
            ),
          ),
        );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.person});

  final PartyContribution person;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final url = person.avatarUrl ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 14,
            backgroundColor: t.bg,
            backgroundImage: url.isEmpty ? null : NetworkImage(url),
            child: url.isEmpty
                ? Text(
                    initialOf(person.nickname),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              person.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: t.text),
            ),
          ),
          Text(
            person.sessions == 0
                ? '아직 없음'
                : '${person.sessions}회 · ${formatCompactNumber(person.xp)} XP',
            style: TextStyle(
              fontSize: 12,
              color: person.sessions == 0 ? t.faintText : t.mutedText,
              fontFeatures: kTabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

/// 미션 카드 자리표시자.
class AppMissionSkeleton extends StatelessWidget {
  const AppMissionSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 96,
    decoration: BoxDecoration(
      color: context.tokens.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.tokens.border),
    ),
  );
}
