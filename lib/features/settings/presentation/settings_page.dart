import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/config/app_env.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/core/widgets/app_list.dart';
import 'package:heal_setlog/core/widgets/app_screen.dart';
import 'package:heal_setlog/features/auth/application/auth_service.dart';
import 'package:heal_setlog/features/auth/application/session_controller.dart';
import 'package:heal_setlog/features/profile/application/profile_providers.dart';
import 'package:heal_setlog/features/help/presentation/help_page.dart';
import 'package:heal_setlog/features/settings/application/settings_controller.dart';
import 'package:heal_setlog/features/settings/application/theme_controller.dart';

/// 실제로 제공하는 앱 설정과 지원 정보만 보여준다.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = context.l10n;
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final selectedTheme = ref.watch(themeControllerProvider);
    final themeController = ref.read(themeControllerProvider.notifier);
    final authService = ref.read(authServiceProvider);
    final isSignedIn =
        isSupabaseConfigured && authService.currentUserId != null;
    return AppScreen(
      title: copy.settingsTitle,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: AppPagePadding(
            child: Column(
              children: <Widget>[
                AppSection(
                  title: copy.settingsApp,
                  children: <Widget>[
                    AppRow(
                      title: '테마',
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<AppThemeId>(
                          value: selectedTheme,
                          items: AppThemeId.values
                              .map(
                                (id) => DropdownMenuItem<AppThemeId>(
                                  value: id,
                                  child: Text(id.label),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value != null) themeController.select(value);
                          },
                        ),
                      ),
                    ),
                    AppRow(
                      title: copy.settingsWeightUnit,
                      trailing: SegmentedButton<WeightUnit>(
                        segments: <ButtonSegment<WeightUnit>>[
                          ButtonSegment<WeightUnit>(
                            value: WeightUnit.kg,
                            label: Text(copy.settingsKg),
                          ),
                          ButtonSegment<WeightUnit>(
                            value: WeightUnit.lb,
                            label: Text(copy.settingsLb),
                          ),
                        ],
                        selected: <WeightUnit>{state.weightUnit},
                        showSelectedIcon: false,
                        onSelectionChanged: (Set<WeightUnit> value) =>
                            controller.setWeightUnit(value.single),
                      ),
                    ),
                  ],
                ),
                AppSection(
                  title: copy.settingsOther,
                  children: <Widget>[
                    AppRow(
                      title: '도움말',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpPage(),
                        ),
                      ),
                    ),
                    AppRow(
                      title: copy.settingsPrivacyPolicy,
                      subtitle: '출시 전 공개 예정입니다',
                    ),
                    AppRow(title: copy.settingsVersion, value: 'v0.1.0'),
                    if (isSignedIn) ...<Widget>[
                      AppRow(
                        title: copy.settingsLogout,
                        destructive: true,
                        onTap: () => _signOut(context, ref),
                      ),
                      AppRow(
                        title: '회원 탈퇴',
                        subtitle: '계정과 모든 기록이 삭제됩니다',
                        destructive: true,
                        onTap: () => _deleteAccount(context, ref),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 되돌릴 수 없는 삭제라 닉네임을 직접 입력하게 한다. 확인 버튼 하나로는
  /// 잘못 눌러 계정을 잃는다.
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final nickname =
        ref.read(myProfileProvider).valueOrNull?.nickname.trim() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DeleteAccountDialog(nickname: nickname),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(sessionControllerProvider).deleteAccount();
    if (!context.mounted) return;
    result.when(
      ok: (_) => context.go('/login'),
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final outcome = await ref.read(sessionControllerProvider).signOut();
    if (!context.mounted) return;
    if (outcome.localDataKept) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일부 기록을 서버에 올리지 못해 이 기기에 남겨 뒀어요.')),
      );
    }
    context.go('/login');
  }
}

/// 탈퇴 확인. 파티장이면 파티까지 사라지므로 그 사실도 알린다.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.nickname});

  final String nickname;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _deleting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _controller.text.trim() == widget.nickname;
    return AlertDialog(
      title: const Text('회원 탈퇴'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '운동 기록, 캐릭터, 게시물, 파티 활동이 모두 삭제됩니다. '
            '내가 만든 파티는 파티원에게도 사라집니다. 되돌릴 수 없습니다.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('확인하려면 "${widget.nickname}"을 입력하세요.'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: widget.nickname),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: !matches || _deleting
              ? null
              : () {
                  setState(() => _deleting = true);
                  Navigator.pop(context, true);
                },
          child: const Text('탈퇴'),
        ),
      ],
    );
  }
}
