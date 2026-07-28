import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/features/auth/presentation/login_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('shows validation errors for invalid credentials', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호는 6자 이상이어야 합니다.'), findsOneWidget);
  });

  testWidgets('uses local mode login when credentials are not configured', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}

Widget _app() => ProviderScope(
  child: MaterialApp.router(
    theme: buildAppTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: GoRouter(
      initialLocation: '/login',
      routes: <RouteBase>[
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(path: '/register', builder: (_, _) => const SizedBox.shrink()),
      ],
    ),
  ),
);
