import 'package:flutter/material.dart';

/// 헬셋로그 색상 토큰(primitive + semantic).
///
/// 중립색은 순수 회색 대신 브랜드(레드) 쪽으로 아주 살짝 치우쳐 "선택된" 느낌을 준다.
abstract final class AppColors {
  // ── Primitive: 중립(따뜻한 저채도) ──
  static const _n0 = Color(0xFF0E0D0F); // 가장 어두운 배경
  static const _n1 = Color(0xFF171519); // 살짝 올라온 표면
  static const _n2 = Color(0xFF201D23); // 카드
  static const _n3 = Color(0xFF2C2830); // 경계/구분선
  static const _n4 = Color(0xFF3A353F); // 강한 경계

  // ── Primitive: 브랜드 레드 램프 ──
  static const _red = Color(0xFFFF3D3D);
  static const _redBright = Color(0xFFFF6B6B);
  static const _redDim = Color(0xFFD62F2F);

  // ── Primitive: 시맨틱 상태색(액센트와 분리) ──
  static const _green = Color(0xFF46C46A); // 성공/PR/증가
  static const _amber = Color(0xFFF5B23C); // 경고/주의

  // ── Semantic (화면에서 이 이름들을 쓴다) ──
  /// 앱 최하단 배경.
  static const background = _n0;

  /// 카드보다 어두운 표면(입력/보조).
  static const mutedSurface = _n1;

  /// 카드 표면.
  static const surface = _n2;

  /// 경계선.
  static const border = _n3;

  /// 강조 경계선.
  static const borderStrong = _n4;

  /// 주요 브랜드 색.
  static const brand = _red;

  /// 밝은 브랜드(호버/보조 강조).
  static const brandLight = _redBright;

  /// 눌린/진한 브랜드.
  static const brandDim = _redDim;

  /// 본문 주 텍스트.
  static const text = Color(0xFFF4F1F6);

  /// 보조 텍스트.
  static const mutedText = Color(0xFFA8A0B2);

  /// 흐린 텍스트/라벨.
  static const faintText = Color(0xFF6F6878);

  /// 성공/PR/증가.
  static const success = _green;

  /// 경고/주의.
  static const warning = _amber;
}

/// 간격 스케일(4의 배수). 매직넘버 대신 사용.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// 반경 스케일.
abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
}

/// 숫자 정렬용 tabular figures 스타일(세트/무게/통계 등에 사용).
const List<FontFeature> kTabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

/// 헬셋로그 타이포그래피 스케일.
///
/// 웹폰트 없이 시스템 폰트 + 굵기·자간·크기로 위계를 만든다.
TextTheme _buildTextTheme() {
  const c = AppColors.text;
  return const TextTheme(
    displaySmall: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.1,
      color: c,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: c,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: c,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: c,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: c,
    ),
    bodyLarge: TextStyle(fontSize: 15, height: 1.4, color: c),
    bodyMedium: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.mutedText),
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: c,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: AppColors.faintText,
    ),
  );
}

/// 헬셋로그의 다크 테마를 생성한다.
ThemeData buildAppTheme() {
  final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.dark,
      ).copyWith(
        surface: AppColors.surface,
        onSurface: AppColors.text,
        primary: AppColors.brand,
        onPrimary: Colors.white,
        outline: AppColors.border,
        secondary: AppColors.brandLight,
      );

  final TextTheme textTheme = _buildTextTheme();

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.mutedSurface,
      hintStyle: TextStyle(color: AppColors.faintText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: AppColors.brand, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        minimumSize: const Size.fromHeight(48),
        textStyle: textTheme.labelLarge,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
        textStyle: textTheme.labelLarge,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandLight,
        textStyle: textTheme.labelLarge,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brand.withValues(alpha: 0.16)
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandLight
              : AppColors.mutedText,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.border),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: TextStyle(color: AppColors.text),
      actionTextColor: AppColors.brandLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.mutedSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.brand.withValues(alpha: 0.20),
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall?.copyWith(letterSpacing: 0.3),
      ),
    ),
  );
}
