import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/party.dart';
import 'package:heal_setlog/domain/entities/party_member.dart';
import 'package:heal_setlog/domain/entities/post.dart';
import 'package:heal_setlog/features/party/application/party_providers.dart';
import 'package:heal_setlog/features/party/presentation/party_page.dart';
import 'package:heal_setlog/features/party/presentation/party_room_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('긴 파티 이름과 많은 인원에도 목록이 넘치지 않는다', (tester) async {
    _small(tester);
    await tester.pumpWidget(
      _app(
        const PartyPage(),
        parties: <Party>[
          Party(
            id: 'p1',
            ownerId: 'me',
            name: '아주아주 긴 파티 이름을 가진 모임입니다 정말 깁니다',
            maxMembers: 20,
            isPublic: true,
            createdAt: DateTime(2026),
            region: '경기도 성남시 분당구',
            focus: '3대측정 및 파워리프팅',
            memberCount: 19,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('파티 방에서 긴 소개와 멤버 이름을 견딘다', (tester) async {
    _small(tester);
    await tester.pumpWidget(
      _app(
        const PartyRoomPage(partyId: 'p1'),
        parties: <Party>[
          Party(
            id: 'p1',
            ownerId: 'me',
            name: '파티',
            description: '소개 ' * 40,
            maxMembers: 8,
            isPublic: false,
            joinCode: 'ABC123',
            createdAt: DateTime(2026),
            memberCount: 3,
          ),
        ],
        members: <PartyMember>[
          PartyMember(
            userId: 'u1',
            nickname: '가' * 30,
            role: 'owner',
            joinedAt: DateTime(2026),
          ),
        ],
        feed: <Post>[
          Post(
            id: 'post-1',
            userId: 'u1',
            caption: '캡션 ' * 30,
            mediaUrl: '',
            mediaKind: PostMediaKind.photo,
            createdAt: DateTime(2026),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

void _small(WidgetTester tester) {
  tester.view.physicalSize = const Size(320 * 3, 640 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(
  Widget home, {
  List<Party> parties = const <Party>[],
  List<PartyMember> members = const <PartyMember>[],
  List<Post> feed = const <Post>[],
}) => ProviderScope(
  overrides: <Override>[
    myPartiesProvider.overrideWith((ref) async => parties),
    partyMembersProvider.overrideWith((ref, id) async => members),
    partyFeedProvider.overrideWith((ref, id) async => feed),
  ],
  child: MaterialApp(
    theme: themeFor(AppThemeId.appleWhite),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);
