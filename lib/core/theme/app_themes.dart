import 'package:flutter/material.dart';

import 'app_theme.dart' show AppRadius;
import 'app_tokens.dart';

/// 선택 가능한 앱 테마. 색뿐 아니라 밝기·그림자·타이포 무게·모서리까지 다른 디자인.
enum AppThemeId {
  appleWhite('Apple 화이트'),
  nikeBlack('Nike 블랙');

  const AppThemeId(this.label);
  final String label;
}

/// id로 ThemeData를 만든다.
ThemeData themeFor(AppThemeId id) => switch (id) {
  AppThemeId.appleWhite => _appleWhite(),
  AppThemeId.nikeBlack => _nikeBlack(),
};

// ── 공통 타이포 빌더(무게 바이어스로 성격 부여) ──
TextTheme _textTheme({
  required Color ink,
  required Color sub,
  required Color faint,
  required FontWeight displayWeight,
  required FontWeight titleWeight,
  double tracking = -0.2,
}) => TextTheme(
  displaySmall: TextStyle(
    fontSize: 30,
    fontWeight: displayWeight,
    letterSpacing: tracking - 0.3,
    height: 1.08,
    color: ink,
  ),
  headlineMedium: TextStyle(
    fontSize: 24,
    fontWeight: displayWeight,
    letterSpacing: tracking - 0.2,
    color: ink,
  ),
  headlineSmall: TextStyle(
    fontSize: 20,
    fontWeight: titleWeight,
    letterSpacing: tracking,
    color: ink,
  ),
  titleLarge: TextStyle(
    fontSize: 18,
    fontWeight: titleWeight,
    letterSpacing: tracking,
    color: ink,
  ),
  titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink),
  bodyLarge: TextStyle(fontSize: 15, height: 1.4, color: ink),
  bodyMedium: TextStyle(fontSize: 13.5, height: 1.4, color: sub),
  labelLarge: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: ink,
  ),
  labelSmall: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: faint,
  ),
);

// 공통 ThemeData 조립. 디자인 성격은 파라미터로 주입한다.
ThemeData _assemble({
  required Brightness brightness,
  required AppTokens t,
  required ColorScheme scheme,
  required TextTheme textTheme,
  required double cardRadius,
  required double buttonRadius,
  required double cardElevation,
  required Color? shadowColor,
}) => ThemeData(
  brightness: brightness,
  colorScheme: scheme,
  scaffoldBackgroundColor: t.bg,
  useMaterial3: true,
  textTheme: textTheme,
  extensions: <ThemeExtension<dynamic>>[t],
  shadowColor: shadowColor ?? Colors.transparent,
  appBarTheme: AppBarTheme(
    backgroundColor: t.bg,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: textTheme.titleLarge,
  ),
  cardTheme: CardThemeData(
    color: t.card,
    elevation: cardElevation,
    shadowColor: shadowColor,
    margin: EdgeInsets.zero,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
      side: BorderSide(color: t.border),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: t.surface,
    hintStyle: TextStyle(color: t.faintText),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
      borderSide: BorderSide(color: t.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
      borderSide: BorderSide(color: t.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
      borderSide: BorderSide(color: t.brand, width: 2),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: t.brand,
      foregroundColor: t.onBrand,
      disabledBackgroundColor: t.border,
      minimumSize: const Size.fromHeight(48),
      textStyle: textTheme.labelLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: t.text,
      side: BorderSide(color: t.border),
      textStyle: textTheme.labelLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: t.brand,
      textStyle: textTheme.labelLarge,
    ),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? t.brand.withValues(alpha: 0.16)
            : Colors.transparent,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? t.brand : t.mutedText,
      ),
      side: WidgetStatePropertyAll(BorderSide(color: t.border)),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: t.surface,
    contentTextStyle: TextStyle(color: t.text),
    actionTextColor: t.brand,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: t.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: t.surface,
    surfaceTintColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: t.surface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: t.brand.withValues(alpha: 0.18),
    elevation: 0,
    labelTextStyle: WidgetStatePropertyAll(
      textTheme.labelSmall?.copyWith(letterSpacing: 0.3),
    ),
  ),
);

// ── Apple 화이트: 라이트·소프트·여백·부드러운 그림자·경량 타이포·큰 모서리 ──
ThemeData _appleWhite() {
  const t = AppTokens(
    bg: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE3E3E8),
    borderStrong: Color(0xFFC9C9CF),
    text: Color(0xFF1D1D1F),
    mutedText: Color(0xFF6E6E73),
    faintText: Color(0xFFA1A1A6),
    brand: Color(0xFF0071E3),
    brandLight: Color(0xFF3D9BFF),
    brandDim: Color(0xFF0060C0),
    onBrand: Color(0xFFFFFFFF),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9500),
  );
  final scheme =
      ColorScheme.fromSeed(
        seedColor: t.brand,
        brightness: Brightness.light,
      ).copyWith(
        surface: t.card,
        onSurface: t.text,
        primary: t.brand,
        onPrimary: t.onBrand,
        outline: t.border,
      );
  return _assemble(
    brightness: Brightness.light,
    t: t,
    scheme: scheme,
    textTheme: _textTheme(
      ink: t.text,
      sub: t.mutedText,
      faint: t.faintText,
      displayWeight: FontWeight.w700,
      titleWeight: FontWeight.w600,
      tracking: -0.3,
    ),
    cardRadius: 18,
    buttonRadius: 14,
    cardElevation: 1,
    shadowColor: const Color(0x14000000),
  );
}

// ── Nike 블랙: 트루블랙·샤프·플랫·헤비 타이포·볼트 액센트·작은 모서리 ──
ThemeData _nikeBlack() {
  const t = AppTokens(
    bg: Color(0xFF000000),
    surface: Color(0xFF0D0D0D),
    card: Color(0xFF121212),
    border: Color(0xFF262626),
    borderStrong: Color(0xFF3A3A3A),
    text: Color(0xFFFFFFFF),
    mutedText: Color(0xFFA1A1A1),
    faintText: Color(0xFF666666),
    brand: Color(0xFFD7FF1E),
    brandLight: Color(0xFFE4FF66),
    brandDim: Color(0xFFB4D900),
    onBrand: Color(0xFF000000),
    success: Color(0xFF00E676),
    warning: Color(0xFFFFAB00),
  );
  final scheme =
      ColorScheme.fromSeed(
        seedColor: t.brand,
        brightness: Brightness.dark,
      ).copyWith(
        surface: t.card,
        onSurface: t.text,
        primary: t.brand,
        onPrimary: t.onBrand,
        outline: t.border,
      );
  return _assemble(
    brightness: Brightness.dark,
    t: t,
    scheme: scheme,
    textTheme: _textTheme(
      ink: t.text,
      sub: t.mutedText,
      faint: t.faintText,
      displayWeight: FontWeight.w900,
      titleWeight: FontWeight.w800,
      tracking: -0.4,
    ),
    cardRadius: 8,
    buttonRadius: 6,
    cardElevation: 0,
    shadowColor: null,
  );
}
