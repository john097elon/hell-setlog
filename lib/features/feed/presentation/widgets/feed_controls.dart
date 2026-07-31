import 'package:flutter/material.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';

import '../models/feed_post.dart';

/// 상단 세그먼트 스위처. [내 파티 | 공개]를 전환한다.
class FeedSwitcher extends StatelessWidget {
  const FeedSwitcher({required this.scope, required this.onChanged, super.key});

  final FeedScope scope;
  final ValueChanged<FeedScope> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    child: SizedBox(
      width: double.infinity,
      child: SegmentedButton<FeedScope>(
        segments: const <ButtonSegment<FeedScope>>[
          ButtonSegment<FeedScope>(value: FeedScope.party, label: Text('내 파티')),
          ButtonSegment<FeedScope>(value: FeedScope.public, label: Text('공개')),
        ],
        selected: <FeedScope>{scope},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
          visualDensity: VisualDensity.standard,
        ),
      ),
    ),
  ).withBg(context.tokens.bg);
}

/// 내 파티 요약 스트립.
class PartyStrip extends StatelessWidget {
  const PartyStrip({required this.party, super.key});

  final PartySummary party;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: t.border),
            ),
            child: Icon(Icons.bolt, color: t.brand, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  party.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${party.doneCount}/${party.totalCount}명 운동 완료 · 오늘 +${formatInt(party.todayXp)} XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: t.mutedText,
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${party.missionPercent}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: t.text,
                  fontFeatures: kTabularFigures,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '미션',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: t.faintText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 공개 피드 필터 행. 지역·종목 칩.
class PublicFilters extends StatelessWidget {
  const PublicFilters({
    required this.filters,
    required this.onPartySelected,
    super.key,
  });

  final FeedFilters filters;
  final ValueChanged<String?> onPartySelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: <Widget>[
          _Chip(
            label: filters.region,
            selected: true,
            leading: Icons.place_outlined,
            trailing: Icons.keyboard_arrow_down_rounded,
          ),
          const SizedBox(width: AppSpacing.sm),
          const _Chip(
            label: '종목',
            selected: false,
            trailing: Icons.keyboard_arrow_down_rounded,
          ),
          const SizedBox(width: AppSpacing.sm),
          for (final part in kBodyParts) ...<Widget>[
            Semantics(
              button: true,
              selected: filters.bodyPart == part,
              child: InkWell(
                onTap: () =>
                    onPartySelected(filters.bodyPart == part ? null : part),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: _Chip(label: part, selected: filters.bodyPart == part),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    ).withBgFallback(t.bg);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    this.leading,
    this.trailing,
  });

  final String label;
  final bool selected;
  final IconData? leading;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // 블랙 섞은 애플: 선택 칩은 검정.
        color: selected ? t.text : t.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected ? t.text : t.border.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            Icon(leading, size: 14, color: selected ? t.card : t.mutedText),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? t.card : t.text,
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            Icon(trailing, size: 15, color: selected ? t.card : t.mutedText),
          ],
        ],
      ),
    );
  }
}

extension _BgHelpers on Widget {
  /// sticky 헤더 배경(스크롤 시 카드가 비쳐 보이지 않도록).
  Widget withBg(Color color) => ColoredBox(color: color, child: this);
  Widget withBgFallback(Color color) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: ColoredBox(color: color, child: this),
  );
}
