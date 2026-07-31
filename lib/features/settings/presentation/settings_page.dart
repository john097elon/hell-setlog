import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/config/app_env.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/features/settings/application/settings_controller.dart';
import 'package:heal_setlog/features/settings/application/theme_controller.dart';
import 'package:heal_setlog/features/settings/presentation/widgets/setting_row.dart';
import 'package:heal_setlog/features/settings/presentation/widgets/setting_section.dart';
import 'package:heal_setlog/features/auth/application/auth_service.dart';
import 'package:heal_setlog/features/auth/application/session_controller.dart';
import 'package:heal_setlog/features/help/presentation/help_page.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(copy.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          SettingSection(
            title: copy.settingsApp,
            children: <Widget>[
              SettingRow(
                title: '테마',
                trailing: SegmentedButton<AppThemeId>(
                  segments: AppThemeId.values
                      .map(
                        (id) => ButtonSegment<AppThemeId>(
                          value: id,
                          label: Text(id.label),
                        ),
                      )
                      .toList(growable: false),
                  selected: <AppThemeId>{selectedTheme},
                  onSelectionChanged: (value) =>
                      themeController.select(value.single),
                ),
              ),
              SettingRow(
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
                  onSelectionChanged: (Set<WeightUnit> value) =>
                      controller.setWeightUnit(value.single),
                ),
              ),
            ],
          ),
          SettingSection(
            title: copy.settingsOther,
            children: <Widget>[
              SettingRow(
                title: '도움말',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const HelpPage()),
                ),
              ),
              SettingRow(
                title: copy.settingsPrivacyPolicy,
                subtitle: '출시 전 공개 예정입니다',
              ),
              SettingRow(title: copy.settingsVersion, subtitle: 'v0.1.0'),
              if (isSignedIn)
                SettingRow(
                  title: copy.settingsLogout,
                  onTap: () async {
                    final outcome = await ref
                        .read(sessionControllerProvider)
                        .signOut();
                    if (!context.mounted) return;
                    if (outcome.localDataKept) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('일부 기록을 서버에 올리지 못해 이 기기에 남겨 뒀어요.'),
                        ),
                      );
                    }
                    context.go('/login');
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
