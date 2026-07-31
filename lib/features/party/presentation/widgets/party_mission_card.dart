import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/app_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_list.dart';
import '../../../../domain/entities/party_mission.dart';
import '../../../auth/application/auth_service.dart';
import '../../application/party_providers.dart';

const int _minimumWeeklyGoal = 1;
const int _maximumWeeklyGoal = 100;

/// 파티의 이번 주 공동 목표. 혼자가 아니라는 걸 보여주는 자리다.
class PartyMissionCard extends ConsumerWidget {
  const PartyMissionCard({
    required this.partyId,
    this.showContributions = true,
    this.allowGoalEditing = false,
    super.key,
  });

  final String partyId;
  final bool showContributions;
  final bool allowGoalEditing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final canEditGoal = allowGoalEditing && _isOwner(ref);
    return ref
        .watch(partyMissionProvider(partyId))
        .when(
          loading: () => const AppMissionSkeleton(),
          error: (_, _) => const AppSection(
            children: <Widget>[
              AppRow(
                title: '미션을 불러오지 못했습니다',
                leading: Icon(Icons.error_outline),
              ),
            ],
          ),
          data: (mission) => Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
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
                    const SizedBox(width: AppSpacing.xs),
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
                    if (canEditGoal)
                      IconButton(
                        tooltip: '목표 수정',
                        onPressed: () =>
                            _editGoal(context, ref, mission.goalSessions),
                        icon: const Icon(Icons.edit_outlined, size: 18),
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
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: mission.progress,
                    minHeight: 10,
                    color: t.brand,
                    backgroundColor: t.surface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
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

  bool _isOwner(WidgetRef ref) {
    final userId = ref.watch(
      authServiceProvider.select((service) => service.currentUserId),
    );
    if (userId == null) return false;
    return ref
            .watch(partyMembersProvider(partyId))
            .valueOrNull
            ?.any(
              (member) => member.userId == userId && member.role == 'owner',
            ) ??
        false;
  }

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    int currentGoal,
  ) async {
    final choice = await _showGoalDialog(context, currentGoal);
    if (choice == null || !context.mounted) return;
    final result = await ref
        .read(partyGoalControllerProvider)
        .updateWeeklyGoal(partyId, choice.goalSessions);
    if (!context.mounted) return;
    result.when(
      ok: (_) {},
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  Future<_WeeklyGoalChoice?> _showGoalDialog(
    BuildContext context,
    int currentGoal,
  ) async {
    final controller = TextEditingController(text: '$currentGoal');
    final formKey = GlobalKey<FormState>();
    final choice = await showDialog<_WeeklyGoalChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('주간 목표 설정'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: const InputDecoration(
                  labelText: '목표 횟수',
                  suffixText: '회',
                ),
                validator: (value) {
                  final goal = int.tryParse(value ?? '');
                  if (goal == null ||
                      goal < _minimumWeeklyGoal ||
                      goal > _maximumWeeklyGoal) {
                    return '1회에서 100회 사이로 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, const _WeeklyGoalChoice(null)),
                child: const Text('자동(인원당 주 3회)'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(
                dialogContext,
                _WeeklyGoalChoice(int.parse(controller.text)),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    return choice;
  }
}

class _WeeklyGoalChoice {
  const _WeeklyGoalChoice(this.goalSessions);

  final int? goalSessions;
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.person});

  final PartyContribution person;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final url = person.avatarUrl ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
          const SizedBox(width: AppSpacing.sm),
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: context.tokens.border),
    ),
  );
}
