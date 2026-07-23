import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/widgets/app_states.dart';
import 'package:heal_setlog/features/party/presentation/models/party_view_data.dart';

/// 목업 파티를 검색하고 부위별로 거르는 패널이다.
class ExplorePanel extends StatefulWidget {
  /// 탐색 패널을 생성한다.
  const ExplorePanel({super.key});

  @override
  State<ExplorePanel> createState() => _ExplorePanelState();
}

class _ExplorePanelState extends State<ExplorePanel> {
  String _query = '';
  String _focus = '전체';

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final filters = <String>[
      copy.partyAll,
      copy.muscleChest,
      copy.muscleLowerBody,
      copy.muscleBack,
      copy.muscleShoulders,
      copy.muscleFullBody,
    ];
    final filtered = explorePartyViewData.where((PartyViewData party) {
      return (_focus == copy.partyAll || party.focus == _focus) &&
          party.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: <Widget>[
        TextField(
          onChanged: (String value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: copy.partySearchHint,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            itemBuilder: (BuildContext context, int index) {
              final filter = filters[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == filters.length - 1 ? 0 : AppSpacing.sm,
                ),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: filter == _focus,
                  onSelected: (_) => setState(() => _focus = filter),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (filtered.isEmpty)
          AppEmptyState(
            icon: Icons.groups_outlined,
            title: copy.partyExplore,
            message: copy.partySearchHint,
          )
        else
          ...List<Widget>.generate(filtered.length, (int index) {
            final party = filtered[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == filtered.length - 1 ? 0 : AppSpacing.md,
              ),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.groups_rounded,
                    color: AppColors.brand,
                  ),
                  title: Text(party.name),
                  subtitle: Text(
                    copy.partyMemberProgress(
                      party.members,
                      party.missionTarget,
                    ),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () => _showMockNotice(context),
                    child: Text(copy.join),
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.brand,
            ),
            title: Text(copy.partyProTitle),
            subtitle: Text(copy.partyProDescription),
            onTap: () => _showMockNotice(context),
          ),
        ),
      ],
    );
  }

  void _showMockNotice(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.mockOnlyNotice)));
  }
}
