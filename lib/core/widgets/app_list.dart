import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// iOS 설정 앱처럼 묶인 목록 한 덩어리.
///
/// 카드 하나에 행을 쌓고 행 사이만 얇은 선으로 나눈다. 화면마다 다른 카드를
/// 만들지 않도록 목록형 UI는 전부 이걸 쓴다.
class AppSection extends StatelessWidget {
  const AppSection({
    required this.children,
    this.title,
    this.footer,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.xl),
    super.key,
  });

  final List<Widget> children;
  final String? title;
  final String? footer;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(title!, style: AppText.sectionLabel(context)),
            ),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: t.border),
            ),
            child: Column(
              children: <Widget>[
                for (
                  var index = 0;
                  index < children.length;
                  index++
                ) ...<Widget>[
                  if (index > 0) const AppHairline(indent: 16),
                  children[index],
                ],
              ],
            ),
          ),
          if (footer != null) ...<Widget>[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                footer!,
                style: TextStyle(fontSize: 12, height: 1.4, color: t.faintText),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 목록 행. 최소 높이 48로 손가락이 닿는 크기를 보장한다.
class AppRow extends StatelessWidget {
  const AppRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.value,
    this.onTap,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// 오른쪽 끝 위젯. 없고 [onTap]이 있으면 셰브런을 넣는다.
  final Widget? trailing;

  /// 오른쪽에 붙는 보조 값 텍스트.
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final titleColor = destructive ? t.like : t.text;
    final row = Padding(
      padding: EdgeInsets.fromLTRB(16, 11, trailing == null ? 12 : 16, 11),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            SizedBox(width: 26, child: Center(child: leading)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: t.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...<Widget>[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14.5,
                  color: t.mutedText,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ),
          ],
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 10),
            trailing!,
          ] else if (onTap != null) ...<Widget>[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: t.faintText),
          ],
        ],
      ),
    );
    final constrained = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: row,
    );
    if (onTap == null) return constrained;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: constrained),
    );
  }
}

/// 행 사이를 나누는 얇은 선. 지나치게 진하면 목록이 시끄러워진다.
class AppHairline extends StatelessWidget {
  const AppHairline({this.indent = 0, super.key});

  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indent),
    child: Divider(
      height: 0.5,
      thickness: 0.5,
      color: context.tokens.border.withValues(alpha: 0.8),
    ),
  );
}

/// 화면 안 소제목. 섹션 카드 밖에서 쓴다.
abstract final class AppText {
  static TextStyle sectionLabel(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: context.tokens.mutedText,
  );

  /// 화면 제목. 큰 제목 스크롤 헤더에 쓴다.
  static TextStyle screenTitle(BuildContext context) => TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.1,
    color: context.tokens.text,
  );

  /// 자랑하고 싶은 숫자. 볼륨·레벨·XP처럼 눈에 먼저 들어와야 하는 값.
  static TextStyle metric(BuildContext context, {double size = 22}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: context.tokens.text,
        fontFeatures: kTabularFigures,
      );

  /// 지표 아래 붙는 라벨.
  static TextStyle metricLabel(BuildContext context) => TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: context.tokens.faintText,
  );
}
