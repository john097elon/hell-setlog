import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/config/app_env.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/features/settings/application/settings_controller.dart';
import 'package:heal_setlog/features/settings/application/theme_controller.dart';
import 'package:heal_setlog/features/settings/presentation/widgets/setting_row.dart';
import 'package:heal_setlog/features/settings/presentation/widgets/setting_section.dart';
import 'package:heal_setlog/features/settings/presentation/widgets/setting_toggle.dart';
import 'package:heal_setlog/features/auth/application/auth_service.dart';

/// In-memory settings and profile mock shown from the profile tab.
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
            title: copy.settingsNotifications,
            children: <Widget>[
              SettingToggle(
                title: copy.settingsWorkoutReminder,
                value: state.workoutReminder,
                onChanged: controller.setWorkoutReminder,
              ),
              SettingToggle(
                title: copy.settingsPartyNotification,
                value: state.partyNotification,
                onChanged: controller.setPartyNotification,
              ),
              SettingToggle(
                title: copy.settingsChatNotification,
                value: state.chatNotification,
                onChanged: controller.setChatNotification,
              ),
              SettingToggle(
                title: copy.settingsMonsterGrowth,
                value: state.monsterGrowthNotification,
                onChanged: controller.setMonsterGrowthNotification,
              ),
            ],
          ),
          SettingSection(
            title: copy.settingsPrivacy,
            children: <Widget>[
              SettingRow(
                title: copy.settingsFeedVisibility,
                subtitle: copy.settingsPublic,
                onTap: () =>
                    _showMockSheet(context, copy.settingsFeedVisibility),
              ),
              SettingRow(
                title: copy.settingsWorkoutVisibility,
                subtitle: copy.settingsPrivate,
                onTap: () =>
                    _showMockSheet(context, copy.settingsWorkoutVisibility),
              ),
            ],
          ),
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
              SettingToggle(
                title: copy.settingsDarkMode,
                value: state.darkMode,
                onChanged: controller.setDarkMode,
              ),
              SettingRow(
                title: copy.settingsLanguage,
                subtitle: copy.settingsKorean,
                onTap: () => _showMockSheet(context, copy.settingsLanguage),
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
            title: copy.settingsSubscription,
            children: <Widget>[
              SettingRow(
                title: copy.settingsProUpgrade,
                subtitle: copy.settingsProDescription,
                onTap: () =>
                    _showMockSheet(context, copy.settingsProMockMessage),
              ),
            ],
          ),
          SettingSection(
            title: copy.settingsOther,
            children: <Widget>[
              SettingRow(
                title: copy.settingsNotices,
                onTap: () => _showMockSheet(context, copy.settingsNotices),
              ),
              SettingRow(
                title: copy.settingsSupport,
                onTap: () => _showMockSheet(context, copy.settingsSupport),
              ),
              SettingRow(
                title: copy.settingsPrivacyPolicy,
                onTap: () =>
                    _showMockSheet(context, copy.settingsPrivacyPolicy),
              ),
              SettingRow(title: copy.settingsVersion, subtitle: 'v0.1.0'),
              if (isSignedIn)
                SettingRow(
                  title: copy.settingsLogout,
                  onTap: () async {
                    await authService.signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMockSheet(BuildContext context, String message) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(message),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(context.l10n.cancel),
                ),
              ],
            ),
          ),
        ),
      );
}
