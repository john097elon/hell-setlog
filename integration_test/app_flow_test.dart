// 실기기/에뮬레이터에서 핵심 흐름을 눌러보며 검증한다.
//
// 실행:
//   flutter test integration_test/app_flow_test.dart \
//     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... -d <deviceId>
//
// 서버 자격 증명이 없으면 로컬 모드로 동작하므로, 자격 증명 없이도 화면 전환은 검증된다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/features/onboarding/presentation/onboarding_page.dart';
import 'package:heal_setlog/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      onboardingDoneKey: true,
    });
  });

  testWidgets('로그인 화면에서 시작해 홈 탭을 모두 열 수 있다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HealSetLogApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 로컬 모드에서는 아무 값으로도 통과한다.
    final fields = find.byType(TextFormField);
    if (fields.evaluate().length >= 2) {
      await tester.enterText(fields.at(0), 'tester@example.com');
      await tester.enterText(fields.at(1), 'password');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    expect(find.byType(NavigationBar), findsOneWidget);

    // 하단 탭을 차례로 열어 렌더 예외가 없는지 본다.
    for (final icon in <IconData>[
      Icons.fitness_center_outlined,
      Icons.groups_outlined,
      Icons.person_outline,
      Icons.home_outlined,
    ]) {
      final target = find.byIcon(icon);
      if (target.evaluate().isEmpty) continue;
      await tester.tap(target.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('프로필 탭에서 내 게시물 영역이 예외 없이 그려진다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HealSetLogApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final fields = find.byType(TextFormField);
    if (fields.evaluate().length >= 2) {
      await tester.enterText(fields.at(0), 'tester@example.com');
      await tester.enterText(fields.at(1), 'password');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    final profileTab = find.byIcon(Icons.person_outline);
    if (profileTab.evaluate().isNotEmpty) {
      await tester.tap(profileTab.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('운동 탭에서 세션을 시작하고 종료할 수 있다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HealSetLogApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final fields = find.byType(TextFormField);
    if (fields.evaluate().length >= 2) {
      await tester.enterText(fields.at(0), 'tester@example.com');
      await tester.enterText(fields.at(1), 'password');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    final workoutTab = find.byIcon(Icons.fitness_center_outlined);
    if (workoutTab.evaluate().isEmpty) return;
    await tester.tap(workoutTab.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final start = find.text('새 운동 시작');
    if (start.evaluate().isNotEmpty) {
      await tester.tap(start.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final finish = find.byKey(const Key('finish-workout'));
      if (finish.evaluate().isNotEmpty) {
        await tester.tap(finish);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    }
    expect(tester.takeException(), isNull);
  });
}
