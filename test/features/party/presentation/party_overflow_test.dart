import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/character_identity.dart';
import 'package:heal_setlog/domain/entities/party.dart';
import 'package:heal_setlog/domain/entities/party_member.dart';
import 'package:heal_setlog/domain/entities/party_mission.dart';
import 'package:heal_setlog/domain/entities/post.dart';
import 'package:heal_setlog/features/auth/application/auth_service.dart';
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

  testWidgets('파티원 전원의 캐릭터와 캐릭터 없는 자리를 렌더한다', (tester) async {
    _small(tester);
    final members = List<PartyMember>.generate(
      8,
      (index) => PartyMember(
        userId: 'u$index',
        nickname: '아주 긴 파티원 닉네임 $index',
        role: index == 0 ? 'owner' : 'member',
        joinedAt: DateTime(2026),
        characterName: index == 7 ? null : '아주 긴 캐릭터 이름 $index',
        characterSpecies: index == 7 ? null : CharacterSpecies.cat,
        characterLevel: index == 7 ? null : 8 - index,
        characterStage: index == 7 ? null : index.clamp(0, 4),
      ),
    );

    await tester.pumpWidget(
      _app(const PartyRoomPage(partyId: 'p1'), members: members),
    );
    await tester.pumpAndSettle();

    expect(find.text('파티원 캐릭터'), findsOneWidget);
    expect(find.text('아주 긴 캐릭터 이름 0'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('party-character-list')),
      const Offset(-900, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('아직 캐릭터가 없어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('파티장만 목표 수정 진입점을 볼 수 있다', (tester) async {
    final members = <PartyMember>[
      PartyMember(
        userId: 'owner-id',
        nickname: '파티장',
        role: 'owner',
        joinedAt: DateTime(2026),
      ),
      PartyMember(
        userId: 'member-id',
        nickname: '파티원',
        role: 'member',
        joinedAt: DateTime(2026),
      ),
    ];
    final mission = PartyMission(
      goalSessions: 6,
      doneSessions: 2,
      contributions: const <PartyContribution>[],
      weekStart: DateTime(2026),
    );

    await tester.pumpWidget(
      _app(
        const PartyRoomPage(partyId: 'p1'),
        auth: const _Auth('owner-id'),
        members: members,
        mission: mission,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('목표 수정'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        const PartyRoomPage(partyId: 'p1'),
        auth: const _Auth('member-id'),
        members: members,
        mission: mission,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('목표 수정'), findsNothing);
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
  AuthService auth = const LocalStubAuthService(),
  PartyMission? mission,
}) => ProviderScope(
  overrides: <Override>[
    authServiceProvider.overrideWithValue(auth),
    myPartiesProvider.overrideWith((ref) async => parties),
    partyMembersProvider.overrideWith((ref, id) async => members),
    partyFeedProvider.overrideWith((ref, id) async => feed),
    if (mission != null)
      partyMissionProvider.overrideWith((ref, id) async => mission),
  ],
  child: MaterialApp(
    theme: themeFor(AppThemeId.appleWhite),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

class _Auth extends LocalStubAuthService {
  const _Auth(this.userId);

  final String userId;

  @override
  String get currentUserId => userId;
}
