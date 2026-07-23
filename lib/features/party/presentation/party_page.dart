import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/features/party/presentation/widgets/explore_panel.dart';
import 'package:heal_setlog/features/party/presentation/widgets/my_party_panel.dart';
import 'package:heal_setlog/features/party/presentation/widgets/party_chat_panel.dart';

/// 내 파티, 파티 탐색, 채팅 목업을 전환하는 화면이다.
class PartyPage extends StatelessWidget {
  /// 파티 목업 화면을 생성한다.
  const PartyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(copy.party),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () => _showMockNotice(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(copy.partyCreateShort),
            ),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: copy.myParties),
              Tab(text: copy.partyExplore),
              Tab(text: copy.partyChat),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[MyPartyPanel(), ExplorePanel(), PartyChatPanel()],
        ),
      ),
    );
  }

  void _showMockNotice(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.mockOnlyNotice)));
  }
}
