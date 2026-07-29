import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/router/app_router.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/features/app_shell/presentation/workout_tab_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';
import 'package:heal_setlog/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the app inside a Riverpod scope', (tester) async {
    await _pumpApp(tester);

    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('opens the home shell after mock login', (tester) async {
    await _pumpApp(tester);
    await _login(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });

  testWidgets('opens the party tab with the three-tab mock', (tester) async {
    await _pumpApp(tester);
    await _login(tester);

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();

    expect(find.text('RANDOM MATCH'), findsOneWidget);
    expect(find.text('탐색'), findsOneWidget);
    expect(find.text('채팅'), findsOneWidget);
  });

  testWidgets('renders workout subtabs from the router shell', (tester) async {
    final router = createAppRouter();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    router.go('/home');
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(),
          home: const WorkoutTabPage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
  });
  await tester.pumpWidget(const ProviderScope(child: HealSetLogApp()));
  await tester.pump();
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password');
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}
