import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/features/settings/application/settings_controller.dart';
import 'package:heal_setlog/features/settings/presentation/settings_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders settings sections and rows', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _app());

    expect(find.byType(Switch), findsNWidgets(4));
    await _scrollDown(tester);
    expect(_weightUnitButton, findsOneWidget);
    await _scrollDown(tester);
    expect(find.textContaining('HELL-LOG PRO'), findsOneWidget);
    await _scrollDown(tester);
    expect(find.text('v0.1.0'), findsOneWidget);
  });

  testWidgets('reflects notification toggle state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _app());

    final toggle = find.byType(Switch).first;
    expect(tester.widget<Switch>(toggle).value, isTrue);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<Switch>(toggle).value, isFalse);
  });

  testWidgets('selects kg and lb weight units', (WidgetTester tester) async {
    await tester.pumpWidget(await _app());
    await _scrollDown(tester);
    final finder = _weightUnitButton;
    expect(tester.widget<SegmentedButton>(finder).selected, isNotEmpty);
    await tester.tap(find.text('lb'));
    await tester.pump();
    final button = tester.widget<SegmentedButton>(finder);
    expect(button.selected.single.toString(), contains('lb'));
  });
}

Future<Widget> _app() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsPage(),
    ),
  );
}

Future<void> _scrollDown(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -400));
  await tester.pumpAndSettle();
}

final Finder _weightUnitButton = find.byWidgetPredicate(
  (Widget widget) => widget is SegmentedButton<WeightUnit>,
);
