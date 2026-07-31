import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/workout_set.dart';
import 'package:heal_setlog/features/workout_log/application/rest_timer_controller.dart';
import 'package:heal_setlog/features/workout_log/presentation/widgets/rest_timer_bar.dart';
import 'package:heal_setlog/features/workout_log/presentation/widgets/set_row.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('swipe deletes and displays undo snackbar', (tester) async {
    var deleted = false;
    final set = WorkoutSet(
      id: 'set',
      sessionId: 'session',
      exerciseId: 'exercise',
      setIndex: 0,
      weight: 60,
      reps: 10,
      updatedAt: DateTime(2026),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => SetRow(
              index: 0,
              weight: 60,
              reps: 10,
              set: set,
              onWeightChanged: (_) {},
              onRepsChanged: (_) {},
              onComplete: () {},
              onDelete: () {
                deleted = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('deleted'),
                    action: SnackBarAction(label: 'undo', onPressed: _noop),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byKey(const Key('set-set')), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
    expect(find.text('deleted'), findsOneWidget);
    expect(find.text('undo'), findsOneWidget);
  });

  testWidgets('draft set calls callbacks when weight and reps are typed', (
    tester,
  ) async {
    double? weight;
    int? reps;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SetRow(
            index: 0,
            weight: 60,
            reps: 10,
            onWeightChanged: (value) => weight = value,
            onRepsChanged: (value) => reps = value,
            onComplete: _noop,
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('set-weight-input')), '62.5');
    await tester.enterText(find.byKey(const Key('set-reps-input')), '12');

    expect(weight, 62.5);
    expect(reps, 12);
  });

  testWidgets('lb input is displayed as lb and returned as kg', (tester) async {
    double? storedKg;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SetRow(
            index: 0,
            weight: 60,
            weightUnit: WeightUnit.lb,
            reps: 10,
            onWeightChanged: (value) => storedKg = value,
            onRepsChanged: (_) {},
            onComplete: _noop,
          ),
        ),
      ),
    );

    final input = find.byKey(const Key('set-weight-input'));
    expect(tester.widget<TextField>(input).controller?.text, '132.3');
    await tester.enterText(input, '220.5');
    expect(storedKg, closeTo(weightToKg(220.5, WeightUnit.lb), 0.000001));
  });

  for (final themeId in AppThemeId.values) {
    testWidgets('320px에서 ${themeId.name} 세트 입력이 넘치지 않는다', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: themeFor(themeId),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SetRow(
                    index: 98,
                    weight: 999,
                    reps: 999,
                    onWeightChanged: (_) {},
                    onRepsChanged: (_) {},
                    onComplete: _noop,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: RestTimerBar(
                    state: RestTimerState(3599, isRunning: true),
                    onAdd: _noop,
                    onSkip: _noop,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}

void _noop() {}
