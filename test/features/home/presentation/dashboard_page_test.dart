import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/character_identity.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/domain/entities/party.dart';
import 'package:heal_setlog/domain/entities/post.dart';
import 'package:heal_setlog/domain/entities/party_mission.dart';
import 'package:heal_setlog/domain/usecases/calculate_character_growth.dart';
import 'package:heal_setlog/features/character/application/character_identity_controller.dart';
import 'package:heal_setlog/features/character/application/character_providers.dart';
import 'package:heal_setlog/features/feed/application/post_providers.dart';
import 'package:heal_setlog/features/home/presentation/dashboard_page.dart';
import 'package:heal_setlog/features/notifications/application/notification_providers.dart';
import 'package:heal_setlog/features/party/application/party_providers.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('홈이 내 캐릭터와 파티 미션을 먼저 보여준다', (tester) async {
    await _pump(tester);

    expect(find.text('불꽃이'), findsOneWidget);
    expect(find.text('강남 새벽팀'), findsOneWidget);
    expect(find.text('이번 주 파티 미션'), findsOneWidget);
    expect(find.text('3 / 12회'), findsOneWidget);
    expect(find.text('운동 시작하기'), findsOneWidget);
  });

  testWidgets('홈에서 피드를 바로 볼 수 있다', (tester) async {
    await _pump(tester);

    // 피드를 하단 탭에서 뺐어도 홈에서 사라지면 안 된다.
    expect(find.text('피드'), findsOneWidget);
    expect(find.text('오늘 가슴 끝'), findsOneWidget);
  });

  testWidgets('캐릭터가 없으면 만들기부터 안내한다', (tester) async {
    await _pump(tester, identity: null);

    expect(find.text('함께 운동할 캐릭터를 만들어요'), findsOneWidget);
  });

  testWidgets('파티가 없으면 참여를 권한다', (tester) async {
    await _pump(tester, parties: const <Party>[]);

    expect(find.text('파티에 참여하면 함께 목표를 채워요'), findsOneWidget);
  });
}

final _party = Party(
  id: 'p1',
  ownerId: 'me',
  name: '강남 새벽팀',
  maxMembers: 8,
  isPublic: true,
  createdAt: DateTime(2026),
  memberCount: 4,
);

Future<void> _pump(
  WidgetTester tester, {
  CharacterIdentity? identity = const CharacterIdentity(
    species: CharacterSpecies.cat,
    trait: CharacterTrait.power,
    name: '불꽃이',
  ),
  List<Party>? parties,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        characterIdentityProvider.overrideWith((ref) async => identity),
        characterGrowthProvider.overrideWith(
          (ref) async => calculateCharacterGrowth(<Discipline, double>{Discipline.strength: 12000}),
        ),
        myPartiesProvider.overrideWith(
          (ref) async => parties ?? <Party>[_party],
        ),
        partyMissionProvider('p1').overrideWith(
          (ref) async => PartyMission(
            goalSessions: 12,
            doneSessions: 3,
            contributions: const <PartyContribution>[],
            weekStart: DateTime(2026, 7, 27),
          ),
        ),
        unreadNotificationCountProvider.overrideWith((ref) async => 0),
        partyFeedProvider('p1').overrideWith(
          (ref) async => <Post>[
            Post(
              id: 'post-1',
              userId: 'u1',
              caption: '오늘 가슴 끝',
              mediaUrl: '',
              mediaKind: PostMediaKind.photo,
              createdAt: DateTime(2026, 7, 30),
              authorName: '김헬스',
            ),
          ],
        ),
        publicFeedProvider(null).overrideWith((ref) async => <Post>[]),
      ],
      child: MaterialApp(
        theme: themeFor(AppThemeId.appleWhite),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DashboardPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
