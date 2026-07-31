import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/party.dart';
import 'package:heal_setlog/domain/entities/party_message.dart';
import 'package:heal_setlog/domain/repositories/party_repository.dart';
import 'package:heal_setlog/features/party/application/party_providers.dart';
import 'package:heal_setlog/features/party/presentation/widgets/party_chat_panel.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  testWidgets('새 메시지가 들어오면 채팅 화면에 바로 나타난다', (tester) async {
    final repository = _MockPartyRepository();
    final messages = StreamController<Result<List<PartyMessage>, Failure>>();
    addTearDown(messages.close);
    when(
      () => repository.watchMessages('party-1'),
    ).thenAnswer((_) => messages.stream);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          partyRepositoryProvider.overrideWithValue(repository),
          myPartiesProvider.overrideWith((ref) async => <Party>[_party]),
        ],
        child: MaterialApp(
          theme: themeFor(AppThemeId.appleWhite),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: PartyChatPanel(initialPartyId: 'party-1')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    messages.add(Ok<List<PartyMessage>, Failure>(<PartyMessage>[_oldMessage]));
    await tester.pump();
    expect(find.text('기존 메시지'), findsOneWidget);

    messages.add(
      Ok<List<PartyMessage>, Failure>(<PartyMessage>[_oldMessage, _newMessage]),
    );
    await tester.pump();
    expect(find.text('새 메시지'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(messages.hasListener, isFalse);
  });
}

class _MockPartyRepository extends Mock implements PartyRepository {}

final Party _party = Party(
  id: 'party-1',
  ownerId: 'owner-1',
  name: '실시간 파티',
  maxMembers: 8,
  isPublic: true,
  createdAt: DateTime(2026),
);

final PartyMessage _oldMessage = PartyMessage(
  id: 'message-1',
  partyId: 'party-1',
  userId: 'user-1',
  body: '기존 메시지',
  createdAt: DateTime(2026),
);

final PartyMessage _newMessage = PartyMessage(
  id: 'message-2',
  partyId: 'party-1',
  userId: 'user-2',
  body: '새 메시지',
  createdAt: DateTime(2026, 1, 1, 0, 1),
);
