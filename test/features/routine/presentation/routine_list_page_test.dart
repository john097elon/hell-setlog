import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/routine.dart';
import 'package:heal_setlog/features/routine/application/routine_providers.dart';
import 'package:heal_setlog/features/routine/presentation/routine_list_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('renders routines supplied by routinesProvider', (tester) async {
    await tester.pumpWidget(_app(Ok(<Routine>[_routine('Push day')])));
    await tester.pumpAndSettle();

    expect(find.text('Push day'), findsOneWidget);
  });

  testWidgets('shows create CTA for an empty routine list', (tester) async {
    await tester.pumpWidget(_app(const Ok(<Routine>[])));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsWidgets);
  });

  for (final themeId in AppThemeId.values) {
    testWidgets('320px에서 ${themeId.name} 루틴 목록이 넘치지 않는다', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _app(
          Ok(<Routine>[_routine('상체와 하체를 모두 포함한 아주 긴 루틴')]),
          themeId: themeId,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(
  Result<List<Routine>, Failure> result, {
  AppThemeId themeId = AppThemeId.appleWhite,
}) => ProviderScope(
  overrides: <Override>[routinesProvider.overrideWith((ref) async => result)],
  child: MaterialApp(
    theme: themeFor(themeId),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const RoutineListPage(),
  ),
);

Routine _routine(String name) => Routine(
  id: name,
  name: name,
  ownerId: 'user',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
