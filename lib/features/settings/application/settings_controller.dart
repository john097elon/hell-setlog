import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_controller.g.dart';

const _weightUnitPreferenceKey = 'weight_unit';

class SettingsState {
  const SettingsState({this.weightUnit = WeightUnit.kg});

  final WeightUnit weightUnit;

  SettingsState copyWith({WeightUnit? weightUnit}) =>
      SettingsState(weightUnit: weightUnit ?? this.weightUnit);
}

/// 앱 설정을 즉시 제공하고 SharedPreferences에서 비동기로 복원한다.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  SettingsState build() {
    _restore();
    return const SettingsState();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_weightUnitPreferenceKey);
      for (final unit in WeightUnit.values) {
        if (unit.name == name && unit != state.weightUnit) {
          state = state.copyWith(weightUnit: unit);
          return;
        }
      }
    } on Object {
      // 저장소를 읽지 못하면 안전한 기본값인 kg를 유지한다.
    }
  }

  Future<void> setWeightUnit(WeightUnit value) async {
    state = state.copyWith(weightUnit: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_weightUnitPreferenceKey, value.name);
    } on Object {
      // 현재 세션의 선택은 유지하고 다음 실행에서는 기본값을 사용한다.
    }
  }
}
