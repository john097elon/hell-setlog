import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/features/workout_log/presentation/share_workout_sheet.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('renders the share mock and completes its local interactions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showShareWorkoutSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('운동 공유'), findsOneWidget);
    expect(find.text('BENCH 80KG × 4'), findsOneWidget);
    expect(find.text('SQUAT 100KG × 3'), findsOneWidget);
    expect(find.text('+210 XP'), findsOneWidget);
    expect(find.text('카메라 미리보기 (P5)'), findsOneWidget);
    expect(find.text('탭하여 녹화'), findsOneWidget);
    expect(find.text('피드에 공유'), findsOneWidget);

    final recordButton = find.byKey(const Key('record-ring-button'));
    await tester.ensureVisible(recordButton);
    await tester.tap(recordButton);
    await tester.pump();
    expect(find.textContaining('녹화 중'), findsOneWidget);

    final shareButton = find.byKey(const Key('share-to-feed-button'));
    await tester.ensureVisible(shareButton);
    await tester.tap(shareButton);
    await tester.pumpAndSettle();
    expect(find.text('피드에 공유됨 (mock)'), findsOneWidget);
    expect(find.text('운동 공유'), findsNothing);
  });
}
