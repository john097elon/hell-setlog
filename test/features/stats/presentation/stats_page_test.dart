import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/features/stats/application/stats_providers.dart';
import 'package:heal_setlog/features/stats/presentation/stats_page.dart';
import 'package:heal_setlog/features/stats/presentation/widgets/body_part_split.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('renders weekly summary cards from weekly volume', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        weekly: <DateTime, double>{
          DateUtils.dateOnly(DateTime.now()): 1200,
          DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 1))):
              800,
        },
        split: const <MuscleGroup, double>{MuscleGroup.chest: 1000},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('운동 일수'), findsOneWidget);
    expect(find.text('2일'), findsOneWidget);
    expect(find.text('총 볼륨'), findsOneWidget);
    expect(find.text('2000 kg'), findsOneWidget);
  });

  testWidgets('renders body-part split percentages', (tester) async {
    await tester.pumpWidget(
      _app(
        weekly: <DateTime, double>{DateUtils.dateOnly(DateTime.now()): 1000},
        split: const <MuscleGroup, double>{
          MuscleGroup.chest: 750,
          MuscleGroup.back: 250,
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byType(BodyPartSplit), findsOneWidget);
    expect(find.text('가슴'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('등'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('shows empty state when weekly volume is empty', (tester) async {
    await tester.pumpWidget(
      _app(
        weekly: const <DateTime, double>{},
        split: const <MuscleGroup, double>{},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 기록된 운동이 없어요'), findsOneWidget);
  });

  testWidgets('builds weekly volume bar chart', (tester) async {
    await tester.pumpWidget(
      _app(
        weekly: <DateTime, double>{DateUtils.dateOnly(DateTime.now()): 1000},
        split: const <MuscleGroup, double>{MuscleGroup.legs: 1000},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
  });
}

Widget _app({
  required Map<DateTime, double> weekly,
  required Map<MuscleGroup, double> split,
}) => ProviderScope(
  overrides: <Override>[
    weeklyVolumeProvider().overrideWith(
      (ref) async => Ok<Map<DateTime, double>, Failure>(weekly),
    ),
    bodyPartSplitProvider().overrideWith(
      (ref) async => Ok<Map<MuscleGroup, double>, Failure>(split),
    ),
  ],
  child: MaterialApp(
    theme: buildAppTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const StatsPage(),
  ),
);
