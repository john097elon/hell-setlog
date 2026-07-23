import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/features/party/presentation/party_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('switches among the three party tabs', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('번개 레이스'), findsOneWidget);
    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    expect(find.text('파티 검색'), findsOneWidget);
    await tester.tap(find.text('채팅'));
    await tester.pumpAndSettle();
    expect(find.text('오늘도 운동 완료!'), findsOneWidget);
  });

  testWidgets('shows my party and random match cards', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('번개 레이스'), findsOneWidget);
    expect(find.text('RANDOM MATCH'), findsOneWidget);
  });

  testWidgets('filters parties by search query and renders category chips', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();

    expect(find.text('전체'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '연구소');
    await tester.pumpAndSettle();
    expect(find.text('등 운동 연구소'), findsOneWidget);
    expect(find.text('번개 레이스'), findsNothing);
  });

  testWidgets('adds a chat bubble locally after sending', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('채팅'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '새 메시지');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('새 메시지'), findsOneWidget);
  });
}

Widget _app() => MaterialApp(
  theme: buildAppTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const PartyPage(),
);
