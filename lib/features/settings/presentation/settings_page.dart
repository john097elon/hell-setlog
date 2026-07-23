import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/features/settings/application/settings_controller.dart';
import 'package:heal_setlog/features/settings/presentation/models/settings_view_data.dart';
import 'package:heal_setlog/features/settings/presentation/widgets/setting_row.dart';
import 'package:heal_setlog/features/settings/presentation/widgets/setting_section.dart';
import 'package:heal_setlog/features/settings/presentation/widgets/setting_toggle.dart';

/// In-memory settings and profile mock shown from the profile tab.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = context.l10n;
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(copy.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _ProfileCard(onEdit: () => _showEditDialog(context)),
          const SizedBox(height: 24),
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
              SettingRow(
                title: copy.settingsLogout,
                onTap: () =>
                    _showSnackBar(context, copy.settingsLogoutMockMessage),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final copy = context.l10n;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(copy.settingsEditProfile),
        content: TextFormField(
          initialValue: SettingsViewData.mock.name,
          decoration: InputDecoration(labelText: copy.settingsEditName),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(copy.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showSnackBar(context, copy.settingsMockMessage);
            },
            child: Text(copy.settingsEditSave),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(message),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(context.l10n.cancel),
                ),
              ],
            ),
          ),
        ),
      );

  void _showSnackBar(BuildContext context, String message) =>
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final data = SettingsViewData.mock;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    data.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy.settingsLevelXp(data.level, data.experience),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: copy.settingsEditProfile,
            ),
          ],
        ),
      ),
    );
  }
}
