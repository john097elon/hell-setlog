import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/features/compose/presentation/capture_flow.dart';
import 'package:heal_setlog/features/compose/presentation/compose_page.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  testWidgets('accepts a caption and publishes the local post', (tester) async {
    String? publishedCaption;
    await tester.pumpWidget(
      MaterialApp(
        theme: themeFor(AppThemeId.appleWhite),
        home: Scaffold(
          body: ComposePage(
            media: CapturedMedia(file: XFile('workout.mp4'), isVideo: true),
            onPublished: (caption) => publishedCaption = caption,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('compose-caption')),
      '오늘 운동 완료',
    );
    await tester.ensureVisible(find.byKey(const Key('publish-post')));
    await tester.tap(find.byKey(const Key('publish-post')));
    await tester.pump();

    expect(publishedCaption, '오늘 운동 완료');
    expect(find.text('게시되었습니다'), findsOneWidget);
  });
}
