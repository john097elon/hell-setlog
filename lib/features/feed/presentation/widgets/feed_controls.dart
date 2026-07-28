import 'package:flutter/material.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';

import '../models/feed_post.dart';

/// 상단 세그먼트 스위처. [내 파티 | 공개] 알약 토글.
class FeedSwitcher extends StatelessWidget {
  const FeedSwitcher({required this.scope, required this.onChanged, super.key});

  final FeedScope scope;
  final ValueChanged<FeedScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: <Widget>[
          _seg(context, '내 파티', FeedScope.party),
          const SizedBox(width: 8),
          _seg(context, '공개', FeedScope.public),
        ],
      ),
    ).withBg(t.bg);
  }

  Widget _seg(BuildContext context, String label, FeedScope value) {
    final t = context.tokens;
    final selected = scope == value;
    // 시스템 '동작 줄이기'가 켜져 있으면 전환 애니메이션을 끈다.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: Duration(milliseconds: reduceMotion ? 0 : 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // 블랙 섞은 애플: 선택된 탭은 검정 알약.
              color: selected ? t.text : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: selected ? t.card : t.mutedText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 내 파티 요약 스트립.
class PartyStrip extends StatelessWidget {
  const PartyStrip({required this.party, super.key});

  final PartySummary party;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(13, 12, 15, 12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // 애플 모노크롬: 그래파이트 톤 아이콘.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[t.brandLight, t.brandDim],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  party.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${party.doneCount}/${party.totalCount}명 운동 완료 · 오늘 +${formatInt(party.todayXp)} XP',
                  style: TextStyle(fontSize: 11.5, color: t.mutedText),
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
                ),
              ),
              const SizedBox(height: 1),
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
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        children: <Widget>[
          _Chip(
            label: filters.region,
            selected: true,
            leading: Icons.place_outlined,
            trailing: Icons.keyboard_arrow_down_rounded,
          ),
          const SizedBox(width: 8),
          const _Chip(
            label: '종목',
            selected: false,
            trailing: Icons.keyboard_arrow_down_rounded,
          ),
          const SizedBox(width: 8),
          for (final part in kBodyParts) ...<Widget>[
            Semantics(
              button: true,
              selected: filters.bodyPart == part,
              child: InkWell(
                onTap: () =>
                    onPartySelected(filters.bodyPart == part ? null : part),
                borderRadius: BorderRadius.circular(100),
                child: _Chip(label: part, selected: filters.bodyPart == part),
              ),
            ),
            const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // 블랙 섞은 애플: 선택 칩은 검정.
        color: selected ? t.text : t.card,
        borderRadius: BorderRadius.circular(100),
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
            const SizedBox(width: 3),
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
    padding: const EdgeInsets.only(bottom: 14),
    child: ColoredBox(color: color, child: this),
  );
}
