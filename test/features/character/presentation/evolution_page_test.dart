import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/character_identity.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/domain/usecases/calculate_character_growth.dart';
import 'package:heal_setlog/features/character/application/character_identity_controller.dart';
import 'package:heal_setlog/features/character/application/character_providers.dart';
import 'package:heal_setlog/features/character/presentation/character_setup_page.dart';
import 'package:heal_setlog/features/character/presentation/evolution_page.dart';
import 'package:heal_setlog/features/character/presentation/monster_page.dart';
import 'package:heal_setlog/features/character/presentation/widgets/growth_view.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _identity = CharacterIdentity(
  species: CharacterSpecies.cat,
  trait: CharacterTrait.balanced,
  name: '불꽃이',
);

void main() {
  testWidgets('이전 스프라이트가 새 진화 단계로 바뀌고 자동으로 닫히지 않는다', (tester) async {
    await tester.pumpWidget(
      _app(
        const EvolutionPage(identity: _identity, previousStage: 0, newStage: 1),
      ),
    );

    expect(find.byKey(const Key('evolution-stage-0')), findsOneWidget);
    expect(find.text('불꽃이'), findsOneWidget);
    expect(find.text(stageName(CharacterSpecies.cat, 1)), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.byKey(const Key('evolution-stage-1')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(EvolutionPage), findsOneWidget);
  });

  testWidgets('애니메이션 비활성화 설정이면 새 단계만 즉시 보여준다', (tester) async {
    await tester.pumpWidget(
      _app(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: EvolutionPage(
            identity: _identity,
            previousStage: 0,
            newStage: 1,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('evolution-stage-0')), findsNothing);
    expect(find.byKey(const Key('evolution-stage-1')), findsOneWidget);
  });

  testWidgets('한 번 본 진화는 몬스터 화면에 다시 들어와도 뜨지 않는다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      kSeenCharacterEvolutionStageKey: 0,
      kSeenCharacterLevelKey: 6,
    });

    await _pumpMonster(tester);
    expect(find.byType(EvolutionPage), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(kSeenCharacterEvolutionStageKey), 1);
    final expectedLevel = calculateCharacterGrowth(<Discipline, double>{
      Discipline.strength: 600,
    }).totalLevel;
    expect(prefs.getInt(kSeenCharacterLevelKey), expectedLevel);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.byType(EvolutionPage), findsNothing);
    expect(find.byType(LevelUpBanner), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _pumpMonster(tester);
    expect(find.byType(EvolutionPage), findsNothing);
  });

  for (final themeId in AppThemeId.values) {
    testWidgets('320px에서 ${themeId.name} 캐릭터 생성·진화가 넘치지 않는다', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: _app(const CharacterSetupPage(), themeId: themeId),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _app(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: EvolutionPage(
              identity: _identity,
              previousStage: 0,
              newStage: 1,
            ),
          ),
          themeId: themeId,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(Widget home, {AppThemeId themeId = AppThemeId.appleWhite}) =>
    MaterialApp(
      theme: themeFor(themeId),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

Future<void> _pumpMonster(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        characterIdentityProvider.overrideWith((_) async => _identity),
        characterGrowthProvider.overrideWith(
          (_) async => calculateCharacterGrowth(<Discipline, double>{
            Discipline.strength: 600,
          }),
        ),
      ],
      child: _app(const MonsterPage()),
    ),
  );
  await tester.pumpAndSettle();
}
