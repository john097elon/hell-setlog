import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/domain/entities/routine.dart';
import 'package:heal_setlog/domain/entities/workout_session.dart';
import 'package:heal_setlog/features/home/presentation/home_page.dart';
import 'package:heal_setlog/features/routine/application/routine_providers.dart';
import 'package:heal_setlog/features/stats/application/stats_providers.dart';
import 'package:heal_setlog/features/workout_log/application/workout_providers.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('renders weekly summary and workout CTA', (tester) async {
    await _pumpHome(
      tester,
      weeklyVolume: Ok(<DateTime, double>{DateTime(2026, 1, 1): 1200}),
    );

    expect(find.text('1200 kg'), findsOneWidget);
    expect(find.text('운동 시작하기'), findsOneWidget);
  });

  testWidgets('shows an indicator while data is loading', (tester) async {
    final pending = Completer<Result<Map<DateTime, double>, Failure>>();
    await _pumpHome(tester, weeklyVolumeFuture: pending.future);

    expect(find.byIcon(Icons.hourglass_top_rounded), findsWidgets);
  });

  testWidgets('renders routines from routinesProvider', (tester) async {
    await _pumpHome(
      tester,
      routines: Ok(<Routine>[_routine('푸시 데이'), _routine('하체 데이')]),
    );

    expect(find.text('푸시 데이'), findsOneWidget);
    expect(find.text('하체 데이'), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  Result<Map<DateTime, double>, Failure>? weeklyVolume,
  Future<Result<Map<DateTime, double>, Failure>>? weeklyVolumeFuture,
  Result<List<Routine>, Failure>? routines,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        weeklyVolumeProvider().overrideWith(
          (_) =>
              weeklyVolumeFuture ??
              Future.value(weeklyVolume ?? const Ok(<DateTime, double>{})),
        ),
        activeSessionProvider.overrideWith(
          (_) async => Ok(
            WorkoutSession(
              id: 'complete',
              userId: 'user',
              startedAt: DateTime(2026),
              endedAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          ),
        ),
        routinesProvider.overrideWith(
          (_) async => routines ?? const Ok(<Routine>[]),
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomePage(),
      ),
    ),
  );
  await tester.pump();
  if (weeklyVolumeFuture == null) {
    await tester.pumpAndSettle();
  }
}

Routine _routine(String name) => Routine(
  id: name,
  name: name,
  ownerId: 'user',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
