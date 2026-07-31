import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/features/feed/presentation/video_player_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

void main() {
  testWidgets('네트워크 없이 로딩과 초기화 오류 상태를 보여준다', (tester) async {
    final initialization = Completer<void>();
    final controller = VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video.mp4'),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeFor(AppThemeId.appleWhite),
        home: VideoPlayerPage(
          mediaUrl: controller.dataSource,
          isVideo: true,
          controller: controller,
          initializeController: (_) => initialization.future,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    initialization.completeError(StateError('unsupported codec'));
    await tester.pump();

    expect(find.text('영상을 재생할 수 없습니다. URL 또는 코덱을 확인해 주세요.'), findsOneWidget);
  });
}
