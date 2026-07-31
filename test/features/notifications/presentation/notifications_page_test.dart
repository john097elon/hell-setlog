import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/core/widgets/app_list.dart';
import 'package:heal_setlog/domain/entities/app_notification.dart';
import 'package:heal_setlog/features/notifications/application/notification_providers.dart';
import 'package:heal_setlog/features/notifications/presentation/notifications_page.dart';

void main() {
  testWidgets('두 테마의 좁은 화면에서 공용 목록으로 알림을 보여준다', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final theme in AppThemeId.values) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            myNotificationsProvider.overrideWith(
              (ref) async => <AppNotification>[
                AppNotification(
                  id: 'notification-1',
                  kind: NotificationKind.comment,
                  actorName: '아주 긴 닉네임을 가진 회원 이름',
                  createdAt: DateTime(2026, 7, 31),
                ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: themeFor(theme),
            home: const NotificationsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSection), findsOneWidget);
      expect(find.byType(AppRow), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
