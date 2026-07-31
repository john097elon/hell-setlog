import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/features/settings/presentation/settings_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders only settings that actually work', (tester) async {
    await tester.pumpWidget(await _app());

    expect(find.byType(Switch), findsNothing);
    expect(_themeButton, findsOneWidget);
    expect(_weightUnitButton, findsOneWidget);
    expect(find.text('개인정보처리방침'), findsOneWidget);
    expect(find.text('출시 전 공개 예정입니다'), findsOneWidget);
    expect(find.text('도움말'), findsOneWidget);
    expect(find.text('v0.1.0'), findsOneWidget);
  });

  testWidgets('does not render mock-only settings', (tester) async {
    await tester.pumpWidget(await _app());

    for (final title in <String>[
      '운동 리마인더',
      '파티 알림',
      '채팅 알림',
      '몬스터 성장 알림',
      '피드 공개범위',
      '운동기록 공개',
      '다크 모드',
      '언어',
      '공지사항',
      '문의하기',
      '이용약관',
      'HELL-LOG PRO 업그레이드',
    ]) {
      expect(find.text(title), findsNothing);
    }
  });

  testWidgets('selects kg and lb weight units', (WidgetTester tester) async {
    await tester.pumpWidget(await _app());
    final finder = _weightUnitButton;
    expect(tester.widget<SegmentedButton>(finder).selected, isNotEmpty);
    await tester.tap(find.text('lb'));
    await tester.pump();
    final button = tester.widget<SegmentedButton>(finder);
    expect(button.selected.single.toString(), contains('lb'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('weight_unit'), WeightUnit.lb.name);
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

final Finder _weightUnitButton = find.byWidgetPredicate(
  (Widget widget) => widget is SegmentedButton<WeightUnit>,
);

final Finder _themeButton = find.byWidgetPredicate(
  (Widget widget) => widget is SegmentedButton<AppThemeId>,
);
