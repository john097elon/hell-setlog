import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/main.dart' as app;

void main() {
  testWidgets('앱 루트가 Riverpod 범위 안에서 렌더링된다', (WidgetTester tester) async {
    app.main();
    await tester.pump();

    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('목업 로그인 뒤 다섯 탭이 있는 홈으로 이동한다', (WidgetTester tester) async {
    app.main();
    await tester.pump();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 운동'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('파티'), findsOneWidget);
  });

  testWidgets('기록 탭에서 운동 시작과 완료 목업을 이어서 표시한다', (WidgetTester tester) async {
    app.main();
    await tester.pump();
    await _login(tester);

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    expect(find.text('운동 시작하기'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '운동 시작하기'));
    await tester.pump();
    expect(find.text('운동 진행 중'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, '세트 완료'));
    await tester.tap(find.widgetWithText(OutlinedButton, '운동 종료'));
    await tester.pump();
    expect(find.text('운동 완료!'), findsOneWidget);
  });

  testWidgets('파티 탭에서 파티 방과 활동 피드를 연다', (WidgetTester tester) async {
    app.main();
    await tester.pump();
    await _login(tester);

    await tester.tap(find.text('파티'));
    await tester.pumpAndSettle();
    expect(find.text('내 파티'), findsWidgets);

    await tester.tap(find.text('파티 열기').first);
    await tester.pumpAndSettle();
    expect(find.text('파티 방'), findsOneWidget);
    expect(find.text('활동'), findsOneWidget);
  });

  testWidgets('프로필 탭에서 태그를 저장하는 목업을 표시한다', (WidgetTester tester) async {
    app.main();
    await tester.pump();
    await _login(tester);

    await tester.tap(find.text('프로필'));
    await tester.pumpAndSettle();
    expect(find.text('내 캐릭터'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, '러닝'));
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();
    expect(find.text('설정이 저장되었습니다'), findsOneWidget);
  });

  testWidgets('운동 진행 화면에 레거시 기록 유형과 사진 목업 버튼이 있다', (WidgetTester tester) async {
    app.main();
    await tester.pump();
    await _login(tester);

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '운동 시작하기'));
    await tester.pump();

    expect(find.text('중간'), findsOneWidget);
    expect(find.text('사진'), findsOneWidget);
  });

  testWidgets('프로필에 레거시 설정 입력 항목이 있다', (WidgetTester tester) async {
    app.main();
    await tester.pump();
    await _login(tester);

    await tester.tap(find.text('프로필'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password');
  await tester.tap(find.widgetWithText(FilledButton, '로그인'));
  await tester.pumpAndSettle();
}
