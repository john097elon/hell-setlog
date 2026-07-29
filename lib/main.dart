import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/router/app_router.dart';
import 'package:heal_setlog/core/supabase/supabase_init.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/features/onboarding/presentation/onboarding_page.dart';
import 'package:heal_setlog/features/settings/application/theme_controller.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 헬셋로그 애플리케이션을 시작한다.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initSupabase();
  } catch (_) {}
  // 릴리스에서 위젯 오류가 흰 화면으로 굳지 않도록 최소 안내를 남긴다.
  ErrorWidget.builder = (FlutterErrorDetails details) => const Material(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('화면을 표시하지 못했습니다. 다시 시도해 주세요.'),
      ),
    ),
  );
  runApp(
    ProviderScope(
      child: HealSetLogApp(showOnboarding: await _needsOnboarding()),
    ),
  );
}

/// 온보딩을 본 적이 없고 로그인 상태도 아니면 먼저 소개 화면을 띄운다.
Future<bool> _needsOnboarding() async {
  if (supabaseClientOrNull?.auth.currentSession != null) return false;
  try {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(onboardingDoneKey) ?? false);
  } on Object {
    return false;
  }
}

/// 애플리케이션 루트다.
class HealSetLogApp extends ConsumerStatefulWidget {
  /// 애플리케이션 루트를 생성한다.
  const HealSetLogApp({this.showOnboarding = false, super.key});

  /// 첫 실행 소개 화면부터 시작할지 여부다.
  final bool showOnboarding;

  @override
  ConsumerState<HealSetLogApp> createState() => _HealSetLogAppState();
}

class _HealSetLogAppState extends ConsumerState<HealSetLogApp> {
  late final GoRouter _router = createAppRouter(
    initialLocation: widget.showOnboarding ? '/onboarding' : null,
  );

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
