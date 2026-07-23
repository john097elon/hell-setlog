import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/features/character/presentation/monster_page.dart';
import 'package:heal_setlog/features/character/presentation/widgets/monster_stat_grid.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('renders monster name, level, experience, and stats', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.text('타이냥'), findsOneWidget);
    expect(find.text('레벨 50 · 균형형'), findsOneWidget);
    expect(find.text('EXP'), findsOneWidget);
    expect(find.text('820 / 1,000'), findsOneWidget);
    expect(find.byType(MonsterStatGrid), findsOneWidget);
  });

  testWidgets('renders every mock stat in the grid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.text('ARM'), findsOneWidget);
    expect(find.text('LEG'), findsOneWidget);
    expect(find.text('CORE'), findsOneWidget);
    expect(find.text('ENDURE'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
  });

  testWidgets('renders the stage sprite asset without smoothing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/character/stage4_titannyang.png',
    );
    expect(image.filterQuality, FilterQuality.none);
    expect(image.isAntiAlias, isFalse);
  });
}

Widget _app() => MaterialApp(
  theme: buildAppTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const Scaffold(body: MonsterPage()),
);
