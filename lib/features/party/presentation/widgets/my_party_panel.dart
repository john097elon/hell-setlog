import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_list.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../domain/entities/party.dart';
import '../../application/party_providers.dart';
import '../party_create_sheet.dart';

/// 내가 속한 파티 목록을 보여준다.
class MyPartyPanel extends ConsumerWidget {
  /// 내 파티 패널을 생성한다.
  const MyPartyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(myPartiesProvider)
      .when(
        loading: () => const AppLoading(),
        error: (_, _) =>
            const _Empty(message: '파티를 불러오지 못했습니다. 로그인 상태를 확인해 주세요.'),
        data: (parties) => parties.isEmpty
            ? const _Empty(message: '아직 참여한 파티가 없습니다.')
            : ListView.builder(
                itemCount: 1,
                itemBuilder: (context, _) => AppPagePadding(
                  top: AppSpacing.md,
                  child: AppSection(
                    children: <Widget>[
                      for (final party in parties)
                        _PartyCard(
                          party: party,
                          onTap: () => context.push('/party/room/${party.id}'),
                        ),
                    ],
                  ),
                ),
              ),
      );
}

class _Empty extends ConsumerWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        48,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: <Widget>[
        Icon(Icons.groups_outlined, size: 44, color: t.faintText),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, color: t.mutedText),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () => showPartyCreateSheet(context, ref),
          child: const Text('파티 만들기'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => _joinByCode(context, ref),
          child: const Text('참여 코드로 들어가기'),
        ),
      ],
    );
  }

  Future<void> _joinByCode(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('참여 코드 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: '예: A1B2C3'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('참여'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty || !context.mounted) return;
    final result = await ref.read(partyRepositoryProvider).joinByCode(code);
    if (!context.mounted) return;
    result.when(
      ok: (_) {
        ref.invalidate(myPartiesProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('파티에 참여했습니다.')));
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.party, required this.onTap});

  final Party party;
  final VoidCallback onTap;

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
      leading: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: t.border),
        ),
        child: Icon(Icons.bolt, color: t.mutedText, size: 18),
      ),
      onTap: onTap,
    );
  }
}
