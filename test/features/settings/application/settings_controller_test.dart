import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/features/settings/application/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restores the saved weight unit', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'weight_unit': WeightUnit.lb.name,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(settingsControllerProvider).weightUnit,
      WeightUnit.kg,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container.read(settingsControllerProvider).weightUnit,
      WeightUnit.lb,
    );
  });

  test('updates and persists the selected weight unit', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(settingsControllerProvider.notifier)
        .setWeightUnit(WeightUnit.lb);

    expect(
      container.read(settingsControllerProvider).weightUnit,
      WeightUnit.lb,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('weight_unit'), WeightUnit.lb.name);
  });
}
