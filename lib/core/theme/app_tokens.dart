import 'package:flutter/material.dart';

/// 테마별로 바뀌는 색 토큰. `Theme.of(context).extension<AppTokens>()`로 읽는다.
///
/// 화면/위젯은 정적 `AppColors` 대신 `context.tokens.*`를 써서 테마 전환에 반응한다.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.mutedText,
    required this.faintText,
    required this.brand,
    required this.brandLight,
    required this.brandDim,
    required this.onBrand,
    required this.success,
    required this.warning,
  });

  final Color bg;
  final Color surface;
  final Color card;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color mutedText;
  final Color faintText;
  final Color brand;
  final Color brandLight;
  final Color brandDim;
  final Color onBrand;
  final Color success;
  final Color warning;

  @override
  AppTokens copyWith({
    Color? bg,
    Color? surface,
    Color? card,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? mutedText,
    Color? faintText,
    Color? brand,
    Color? brandLight,
    Color? brandDim,
    Color? onBrand,
    Color? success,
    Color? warning,
  }) => AppTokens(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    card: card ?? this.card,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    text: text ?? this.text,
    mutedText: mutedText ?? this.mutedText,
    faintText: faintText ?? this.faintText,
    brand: brand ?? this.brand,
    brandLight: brandLight ?? this.brandLight,
    brandDim: brandDim ?? this.brandDim,
    onBrand: onBrand ?? this.onBrand,
    success: success ?? this.success,
    warning: warning ?? this.warning,
  );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      faintText: Color.lerp(faintText, other.faintText, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandLight: Color.lerp(brandLight, other.brandLight, t)!,
      brandDim: Color.lerp(brandDim, other.brandDim, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

/// `context.tokens`로 현재 테마 토큰에 접근한다.
extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ??
      const AppTokens(
        bg: Color(0xFF0D0D0D),
        surface: Color(0xFF161616),
        card: Color(0xFF1E1E1E),
        border: Color(0xFF303030),
        borderStrong: Color(0xFF444444),
        text: Color(0xFFF5F5F5),
        mutedText: Color(0xFFA1A1A1),
        faintText: Color(0xFF707070),
        brand: Color(0xFFD7FF1E),
        brandLight: Color(0xFFE4FF66),
        brandDim: Color(0xFFB4D900),
        onBrand: Color(0xFF000000),
        success: Color(0xFF00E676),
        warning: Color(0xFFFFAB00),
      );
}
