import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/character_identity.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/usecases/calculate_character_growth.dart';
import 'package:heal_setlog/features/character/application/character_identity_controller.dart';
import 'package:heal_setlog/features/character/application/character_providers.dart';
import 'package:heal_setlog/features/character/presentation/monster_page.dart';
import 'package:heal_setlog/features/character/presentation/widgets/growth_view.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('캐릭터를 아직 안 만들었으면 만들기부터 안내한다', (tester) async {
    await _pump(tester, volumes: const <MuscleGroup, double>{}, identity: null);

    expect(find.text('함께 운동할 캐릭터를 만들어요'), findsOneWidget);
    expect(find.text('캐릭터 만들기'), findsOneWidget);
  });

  testWidgets('내가 지은 이름과 성향을 캐릭터 카드에 보여준다', (tester) async {
    await _pump(
      tester,
      volumes: <MuscleGroup, double>{MuscleGroup.chest: 3000},
    );

    expect(find.text('불꽃이'), findsOneWidget);
    expect(find.textContaining('파워형'), findsWidgets);
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
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
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

  for (final themeId in AppThemeId.values) {
    testWidgets('320px에서 ${themeId.name} 몬스터 화면이 넘치지 않는다', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pump(
        tester,
        volumes: <MuscleGroup, double>{MuscleGroup.chest: 3000},
        identity: const CharacterIdentity(
          species: CharacterSpecies.cat,
          trait: CharacterTrait.power,
          name: '오늘도성장하는불꽃이',
        ),
        themeId: themeId,
      );

      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required Map<MuscleGroup, double> volumes,
  Map<MuscleGroup, double> weekly = const <MuscleGroup, double>{},
  int? seenLevel,
  int? seenEvolutionStage = 0,
  CharacterIdentity? identity = const CharacterIdentity(
    species: CharacterSpecies.cat,
    trait: CharacterTrait.power,
    name: '불꽃이',
  ),
  AppThemeId themeId = AppThemeId.appleWhite,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        characterGrowthProvider.overrideWith(
          (ref) async =>
              calculateCharacterGrowth(volumes, weeklyVolumes: weekly),
        ),
        seenCharacterLevelProvider.overrideWith((ref) async => seenLevel),
        seenCharacterEvolutionStageProvider.overrideWith(
          (ref) async => seenEvolutionStage,
        ),
        characterIdentityProvider.overrideWith((ref) async => identity),
      ],
      child: MaterialApp(
        theme: themeFor(themeId),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MonsterPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
