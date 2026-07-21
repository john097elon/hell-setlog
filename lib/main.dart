import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/router/app_router.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

/// 헬셋로그 애플리케이션을 시작한다.
void main() {
  runApp(const ProviderScope(child: HealSetLogApp()));
}

/// 레거시 UI 목업을 표시하는 애플리케이션 루트다.
class HealSetLogApp extends StatefulWidget {
  /// 애플리케이션 루트를 생성한다.
  const HealSetLogApp({super.key});

  @override
  State<HealSetLogApp> createState() => _HealSetLogAppState();
}

class _HealSetLogAppState extends State<HealSetLogApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
