import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/features/workout_log/presentation/widgets/tracking_set_row.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('종목의 기록 방식에 따라 입력 칸이 바뀐다', (tester) async {
    await _pumpRow(tester, Discipline.strength);
    expect(find.byKey(const Key('set-weight-input')), findsOneWidget);
    expect(find.byKey(const Key('set-reps-input')), findsOneWidget);
    expect(find.byKey(const Key('set-distance-input')), findsNothing);

    await _pumpRow(tester, Discipline.running);
    expect(find.byKey(const Key('set-distance-input')), findsOneWidget);
    expect(find.byKey(const Key('set-duration-input')), findsOneWidget);
    expect(find.byKey(const Key('set-weight-input')), findsNothing);

    await _pumpRow(tester, Discipline.grappling);
    expect(find.byKey(const Key('set-duration-input')), findsOneWidget);
    expect(find.byKey(const Key('set-intensity-input')), findsOneWidget);
    expect(find.byKey(const Key('set-distance-input')), findsNothing);
  });

  testWidgets('거리와 시간을 입력하면 미터·초로 바꾼다', (tester) async {
    double? distanceMeters;
    int? durationSeconds;
    await _pumpRow(
      tester,
      Discipline.running,
      onDistanceChanged: (value) => distanceMeters = value,
      onDurationChanged: (value) => durationSeconds = value,
    );

    await tester.enterText(find.byKey(const Key('set-distance-input')), '5');
    await tester.enterText(find.byKey(const Key('set-duration-input')), '25');
    await tester.pump();

    expect(distanceMeters, 5000);
    expect(durationSeconds, 1500);
  });

  testWidgets('거리와 시간이 있으면 페이스를 표시한다', (tester) async {
    await _pumpRow(
      tester,
      Discipline.running,
      distanceMeters: 5000,
      durationSeconds: 1500,
    );

    expect(find.text('페이스 5:00/km'), findsOneWidget);
  });

  for (final themeId in AppThemeId.values) {
    testWidgets('320px ${themeId.name}에서 비웨이트 입력이 넘치지 않는다', (tester) async {
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
                _row(Discipline.running),
                _row(Discipline.grappling),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (var value = 1; value <= 5; value++) {
        expect(
          tester.getSize(find.byKey(Key('set-intensity-$value'))).width,
          greaterThanOrEqualTo(48),
        );
      }
    });
  }
}

Future<void> _pumpRow(
  WidgetTester tester,
  Discipline discipline, {
  double? distanceMeters,
  int? durationSeconds,
  ValueChanged<double?>? onDistanceChanged,
  ValueChanged<int?>? onDurationChanged,
}) => tester.pumpWidget(
  MaterialApp(
    theme: themeFor(AppThemeId.appleWhite),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: _row(
        discipline,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        onDistanceChanged: onDistanceChanged,
        onDurationChanged: onDurationChanged,
      ),
    ),
  ),
);

TrackingSetRow _row(
  Discipline discipline, {
  double? distanceMeters,
  int? durationSeconds,
  ValueChanged<double?>? onDistanceChanged,
  ValueChanged<int?>? onDurationChanged,
}) => TrackingSetRow(
  index: 0,
  discipline: discipline,
  weight: 60,
  reps: 10,
  distanceMeters: distanceMeters,
  durationSeconds: durationSeconds,
  intensity: 3,
  onWeightChanged: (_) {},
  onRepsChanged: (_) {},
  onDistanceChanged: onDistanceChanged ?? (_) {},
  onDurationChanged: onDurationChanged ?? (_) {},
  onIntensityChanged: (_) {},
  onComplete: () {},
);
