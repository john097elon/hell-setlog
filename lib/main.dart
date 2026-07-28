import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/router/app_router.dart';
import 'package:heal_setlog/core/supabase/supabase_init.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/features/settings/application/theme_controller.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

/// 헬셋로그 애플리케이션을 시작한다.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initSupabase();
  } catch (_) {}
  runApp(const ProviderScope(child: HealSetLogApp()));
}

/// 애플리케이션 루트다.
class HealSetLogApp extends ConsumerStatefulWidget {
  /// 애플리케이션 루트를 생성한다.
  const HealSetLogApp({super.key});

  @override
  ConsumerState<HealSetLogApp> createState() => _HealSetLogAppState();
}

class _HealSetLogAppState extends ConsumerState<HealSetLogApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: themeFor(ref.watch(themeControllerProvider)),
      routerConfig: _router,
    );
  }
}
