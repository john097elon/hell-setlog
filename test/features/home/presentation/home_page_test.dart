import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/features/home/presentation/home_page.dart';

void main() {
  testWidgets('내 파티 피드가 기본으로 보인다', (tester) async {
    await _pumpHome(tester);

    expect(find.text('번개 레이더스'), findsOneWidget);
    expect(find.text('준혁'), findsOneWidget);
  });

  testWidgets('공개 탭으로 전환하면 공개 게시물과 팔로우가 보인다', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('공개'));
    await tester.pumpAndSettle();

    expect(find.text('헬창왕'), findsOneWidget);
    expect(find.text('팔로우'), findsWidgets);
    expect(find.text('번개 레이더스'), findsNothing);
  });

  testWidgets('공개 피드에서 종목 칩으로 필터링한다', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.text('공개'));
    await tester.pumpAndSettle();

    // 가슴 게시물 존재 → '등' 필터 선택 시 사라진다.
    expect(find.text('헬창왕'), findsOneWidget);
    await tester.tap(find.text('등'));
    await tester.pumpAndSettle();
    expect(find.text('헬창왕'), findsNothing);
  });
}

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: themeFor(AppThemeId.appleWhite),
        home: const HomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
