import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/usecases/calculate_character_growth.dart';
import 'package:heal_setlog/features/character/application/character_providers.dart';
import 'package:heal_setlog/features/character/presentation/monster_page.dart';
import 'package:heal_setlog/features/character/presentation/widgets/growth_view.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('기록이 없으면 성장 안내를 보여준다', (tester) async {
    await _pump(tester, volumes: const <MuscleGroup, double>{});

    expect(find.text('운동을 기록하면 캐릭터가 자랍니다'), findsOneWidget);
  });

  testWidgets('부위별 레벨과 이번 주 경험치를 보여준다', (tester) async {
    await _pump(
      tester,
      volumes: <MuscleGroup, double>{
        MuscleGroup.chest: 12000,
        MuscleGroup.legs: 6000,
      },
      weekly: <MuscleGroup, double>{MuscleGroup.chest: 3000},
    );

    expect(find.text('+30 XP'), findsOneWidget);

    // 부위별 목록은 화면 아래에 있다.
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('가슴'), findsOneWidget);
    expect(find.text('하체'), findsOneWidget);
    expect(find.text('Lv. 3'), findsOneWidget);
  });

  testWidgets('레벨이 올랐으면 축하 배너를 띄운다', (tester) async {
    await _pump(
      tester,
      volumes: <MuscleGroup, double>{MuscleGroup.chest: 12000},
      seenLevel: 5,
    );

    // 부위 6개 기본 레벨 6 + 가슴 2레벨 = 8, 직전에 본 값은 5.
    expect(find.byType(LevelUpBanner), findsOneWidget);
    expect(find.text('레벨이 3 올랐어요'), findsOneWidget);
  });

  testWidgets('처음 보는 사용자에게는 축하 배너를 띄우지 않는다', (tester) async {
    await _pump(
      tester,
      volumes: <MuscleGroup, double>{MuscleGroup.chest: 12000},
    );

    expect(find.byType(LevelUpBanner), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Map<MuscleGroup, double> volumes,
  Map<MuscleGroup, double> weekly = const <MuscleGroup, double>{},
  int? seenLevel,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        characterGrowthProvider.overrideWith(
          (ref) async =>
              calculateCharacterGrowth(volumes, weeklyVolumes: weekly),
        ),
        seenCharacterLevelProvider.overrideWith((ref) async => seenLevel),
      ],
      child: MaterialApp(
        theme: themeFor(AppThemeId.appleWhite),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MonsterPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
