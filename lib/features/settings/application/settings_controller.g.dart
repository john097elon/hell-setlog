// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsControllerHash() =>
    r'0a2d8169e3dfe8e994d952be3d679063cf6b257f';

/// 앱 설정을 즉시 제공하고 SharedPreferences에서 비동기로 복원한다.
///
/// Copied from [SettingsController].
@ProviderFor(SettingsController)
final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>.internal(
      SettingsController.new,
      name: r'settingsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$settingsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SettingsController = Notifier<SettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
