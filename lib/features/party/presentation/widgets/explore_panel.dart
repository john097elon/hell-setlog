import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_list.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../domain/entities/party.dart';
import '../../application/party_providers.dart';

const _focusFilters = <String>['3대측정', '다이어트', '벌크업', '홈트', '러닝', '크로스핏'];

/// 공개 파티를 찾아 참여한다.
class ExplorePanel extends ConsumerStatefulWidget {
  /// 탐색 패널을 생성한다.
  const ExplorePanel({super.key});

  @override
  ConsumerState<ExplorePanel> createState() => _ExplorePanelState();
}

class _ExplorePanelState extends ConsumerState<ExplorePanel> {
  String? _focus;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final myIds =
        ref.watch(myPartiesProvider).valueOrNull?.map((p) => p.id).toSet() ??
        <String>{};
    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            children: <Widget>[
              for (final focus in _focusFilters)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(focus),
                    selected: _focus == focus,
                    onSelected: (value) =>
                        setState(() => _focus = value ? focus : null),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ref
              .watch(partyExploreProvider((region: null, focus: _focus)))
              .when(
                loading: () => const AppLoading(),
                error: (_, _) => Center(
                  child: Text(
                    '파티를 불러오지 못했습니다.',
                    style: TextStyle(color: t.mutedText),
                  ),
                ),
                data: (parties) => parties.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: '공개 파티가 없습니다',
                        message: '직접 파티를 만들어 보세요.',
                      )
                    : ListView.builder(
                        itemCount: 1,
                        itemBuilder: (context, _) => AppPagePadding(
                          top: AppSpacing.xs,
                          child: AppSection(
                            children: <Widget>[
                              for (final party in parties)
                                _ExploreCard(
                                  party: party,
                                  joined: myIds.contains(party.id),
                                  onJoin: () => _join(party),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
        ),
      ],
    );
  }

  Future<void> _join(Party party) async {
    final result = await ref.read(partyRepositoryProvider).joinParty(party.id);
    if (!mounted) return;
    result.when(
      ok: (_) {
        ref.invalidate(myPartiesProvider);
        ref.invalidate(partyExploreProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${party.name} 파티에 참여했습니다.')));
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.party,
    required this.joined,
    required this.onJoin,
  });

  final Party party;
  final bool joined;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppRow(
      title: party.name,
      subtitle: <String?>[
        party.region,
        party.focus,
      ].whereType<String>().join(' · '),
      value: '${party.memberCount}/${party.maxMembers}명',
      trailing: joined
          ? Text(
              '참여됨',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.faintText,
              ),
            )
          : FilledButton(
              onPressed: onJoin,
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 48),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              child: const Text('참여'),
            ),
    );
  }
}
