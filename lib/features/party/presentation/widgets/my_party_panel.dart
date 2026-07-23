import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/features/party/presentation/models/party_view_data.dart';

/// 내 파티 카드와 목업 초대 기능을 보여주는 패널이다.
class MyPartyPanel extends StatefulWidget {
  /// 내 파티 패널을 생성한다.
  const MyPartyPanel({super.key});

  @override
  State<MyPartyPanel> createState() => _MyPartyPanelState();
}

class _MyPartyPanelState extends State<MyPartyPanel> {
  final Set<String> _invitedFriends = <String>{};

  void _showMockNotice() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.mockOnlyNotice)));
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final party = myPartyViewData;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: <Widget>[
        Text(copy.myParties, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(party.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  copy.partyMemberProgress(party.members, party.missionTarget),
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: party.missionCompleted / party.missionTarget,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  copy.partyMissionProgress(
                    party.missionCompleted,
                    party.missionTarget,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  copy.partyTodayXp,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  copy.partyRandomMatch,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(copy.partyRandomMatchDescription),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _showMockNotice,
                    child: Text(copy.partyGo),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          copy.partyInviteFriends,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 104,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: partyFriendViewData.length,
            itemBuilder: (BuildContext context, int index) {
              final friend = partyFriendViewData[index];
              final isInvited = _invitedFriends.contains(friend.name);
              return Padding(
                padding: EdgeInsets.only(
                  right: index == partyFriendViewData.length - 1
                      ? 0
                      : AppSpacing.md,
                ),
                child: SizedBox(
                  width: 124,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        children: <Widget>[
                          Text(
                            friend.name,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(copy.partyLevel(friend.level)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(
                              () => _invitedFriends.add(friend.name),
                            ),
                            child: Text(
                              isInvited ? copy.partyInvited : copy.invite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
