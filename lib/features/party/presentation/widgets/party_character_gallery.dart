import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../domain/entities/party_member.dart';
import '../../../character/presentation/widgets/growth_view.dart'
    show CharacterSprite;
import '../../../profile/presentation/user_profile_page.dart';
import '../../application/party_providers.dart';

/// 파티원 전원의 캐릭터를 레벨 높은 순서로 보여준다.
class PartyCharacterGallery extends ConsumerWidget {
  const PartyCharacterGallery({required this.partyId, super.key});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(partyMembersProvider(partyId))
      .when(
        loading: () => const SizedBox(height: 194, child: AppLoading()),
        error: (_, _) => Text(
          '파티원 캐릭터를 불러오지 못했습니다.',
          style: TextStyle(color: context.tokens.mutedText),
        ),
        data: (members) {
          if (members.isEmpty) {
            return Text(
              '파티원이 없습니다.',
              style: TextStyle(color: context.tokens.mutedText),
            );
          }
          final sorted = <PartyMember>[...members]
            ..sort((a, b) => _levelOf(b).compareTo(_levelOf(a)));
          return SizedBox(
            height: 194,
            child: ListView.builder(
              key: const Key('party-character-list'),
              scrollDirection: Axis.horizontal,
              itemCount: sorted.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  right: index == sorted.length - 1 ? 0 : AppSpacing.md,
                ),
                child: _CharacterCard(member: sorted[index]),
              ),
            ),
          );
        },
      );
}

int _levelOf(PartyMember member) =>
    member.hasCharacter ? member.characterLevel ?? 0 : -1;

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.member});

  final PartyMember member;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      key: ValueKey<String>('party-character-${member.userId}'),
      width: 132,
      child: Material(
        color: t.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: t.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => UserProfilePage(userId: member.userId),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 88,
                  child: member.hasCharacter
                      ? CharacterSprite(
                          species: member.characterSpecies!,
                          stage: member.characterStage ?? 0,
                          discipline: member.characterDiscipline,
                          size: 88,
                        )
                      : Center(
                          child: Text(
                            '아직 캐릭터가 없어요',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: t.faintText,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  member.characterName ?? '캐릭터 없음',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  member.hasCharacter
                      ? 'Lv. ${member.characterLevel ?? 1}'
                      : '레벨 없음',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: t.mutedText,
                    fontFeatures: kTabularFigures,
                  ),
                ),
                const Spacer(),
                Text(
                  member.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: t.faintText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
