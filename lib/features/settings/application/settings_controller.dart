import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

enum WeightUnit { kg, lb }

class SettingsState {
  const SettingsState({
    this.workoutReminder = true,
    this.partyNotification = true,
    this.chatNotification = true,
    this.monsterGrowthNotification = false,
    this.darkMode = true,
    this.weightUnit = WeightUnit.kg,
  });

  final bool workoutReminder;
  final bool partyNotification;
  final bool chatNotification;
  final bool monsterGrowthNotification;
  final bool darkMode;
  final WeightUnit weightUnit;

  SettingsState copyWith({
    bool? workoutReminder,
    bool? partyNotification,
    bool? chatNotification,
    bool? monsterGrowthNotification,
    bool? darkMode,
    WeightUnit? weightUnit,
  }) => SettingsState(
    workoutReminder: workoutReminder ?? this.workoutReminder,
    partyNotification: partyNotification ?? this.partyNotification,
    chatNotification: chatNotification ?? this.chatNotification,
    monsterGrowthNotification:
        monsterGrowthNotification ?? this.monsterGrowthNotification,
    darkMode: darkMode ?? this.darkMode,
    weightUnit: weightUnit ?? this.weightUnit,
  );
}

/// Owns ephemeral settings mock state without persisting user data.
@riverpod
class SettingsController extends _$SettingsController {
  @override
  SettingsState build() => const SettingsState();

  void setWorkoutReminder(bool value) =>
      state = state.copyWith(workoutReminder: value);
  void setPartyNotification(bool value) =>
      state = state.copyWith(partyNotification: value);
  void setChatNotification(bool value) =>
      state = state.copyWith(chatNotification: value);
  void setMonsterGrowthNotification(bool value) =>
      state = state.copyWith(monsterGrowthNotification: value);
  void setDarkMode(bool value) => state = state.copyWith(darkMode: value);
  void setWeightUnit(WeightUnit value) =>
      state = state.copyWith(weightUnit: value);
}
