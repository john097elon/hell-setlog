import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/features/feed/presentation/models/feed_post.dart';
import 'package:heal_setlog/features/feed/presentation/widgets/feed_post_card.dart';

void main() {
  testWidgets('아주 긴 캡션과 이름에도 레이아웃이 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final post = FeedPost(
      author: FeedAuthor(name: '가' * 40, level: 99),
      timeLabel: '방금',
      bodyPart: '가슴',
      media: const FeedMedia(
        kind: FeedMediaKind.photo,
        gradient: <Color>[Color(0xFFECECEE), Color(0xFFDCDCE0)],
      ),
      summary: const WorkoutSummary(
        metrics: <({String label, String value})>[
          (label: '아주 긴 지표 이름입니다', value: '999,999 kg'),
          (label: '시간', value: '999분'),
        ],
        prLabel: '엄청 긴 개인 기록 라벨 텍스트',
      ),
      likes: 123456,
      comments: 9999,
      caption: '긴 캡션 ' * 40,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: themeFor(AppThemeId.appleWhite),
          home: Scaffold(
            body: SingleChildScrollView(child: FeedPostCard(post: post)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('좁은 화면에서도 카드가 렌더된다', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 560 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const post = FeedPost(
      author: FeedAuthor(name: '나', level: 1),
      timeLabel: '1시간',
      bodyPart: '등',
      media: FeedMedia(
        kind: FeedMediaKind.video,
        gradient: <Color>[Color(0xFFECECEE), Color(0xFFDCDCE0)],
        durationLabel: '0:12',
      ),
      summary: WorkoutSummary(
        metrics: <({String label, String value})>[
          (label: '볼륨', value: '1,000 kg'),
        ],
      ),
      likes: 0,
      comments: 0,
      caption: '짧게',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: themeFor(AppThemeId.appleWhite),
          home: const Scaffold(
            body: SingleChildScrollView(child: FeedPostCard(post: post)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
