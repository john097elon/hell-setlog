import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/party.dart';
import 'package:heal_setlog/features/party/application/party_providers.dart';
import 'package:heal_setlog/features/party/presentation/party_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('내 파티가 없으면 만들기 안내를 보여준다', (tester) async {
    await _pump(tester, const <Party>[]);

    expect(find.text('파티 만들기'), findsOneWidget);
    expect(find.text('참여 코드로 들어가기'), findsOneWidget);
  });

  testWidgets('내 파티 목록을 렌더한다', (tester) async {
    await _pump(tester, <Party>[
      Party(
        id: 'party-1',
        ownerId: 'me',
        name: '번개 레이더스',
        maxMembers: 8,
        isPublic: true,
        createdAt: DateTime(2026),
        region: '강남구',
        memberCount: 3,
      ),
    ]);

    expect(find.text('번개 레이더스'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, List<Party> parties) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        myPartiesProvider.overrideWith((ref) async => parties),
      ],
      child: MaterialApp(
        theme: themeFor(AppThemeId.appleWhite),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PartyPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
