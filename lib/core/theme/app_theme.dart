import 'package:flutter/material.dart';

/// 헬셋로그 목업에서 사용하는 색상 토큰이다.
abstract final class AppColors {
  /// 앱의 가장 어두운 배경색이다.
  static const background = Color(0xFF0D0D0D);

  /// 카드보다 어두운 표면색이다.
  static const mutedSurface = Color(0xFF1A1A1A);

  /// 카드 표면색이다.
  static const surface = Color(0xFF242424);

  /// 주요 행동을 강조하는 브랜드 색상이다.
  static const brand = Color(0xFFFF3D3D);

  /// 강조 영역의 보조 색상이다.
  static const brandLight = Color(0xFFFF6B6B);

  /// 보조 텍스트 색상이다.
  static const mutedText = Color(0xFFA0A0A0);

  /// 어두운 표면의 경계선 색상이다.
  static const border = Color(0xFF333333);
}

/// 헬셋로그의 다크 테마를 생성한다.
ThemeData buildAppTheme() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.dark,
    surface: AppColors.surface,
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.mutedSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.brand, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.mutedSurface,
      indicatorColor: Color(0x33FF3D3D),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
    ),
  );
}
