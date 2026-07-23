// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rest_timer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$restTimerHash() => r'dd4929842cc50666f57f27f4febeeac0caf97560';

/// Owns the rest countdown and releases its timer when the provider disposes.
///
/// Copied from [RestTimer].
@ProviderFor(RestTimer)
final restTimerProvider =
    AutoDisposeNotifierProvider<RestTimer, RestTimerState>.internal(
      RestTimer.new,
      name: r'restTimerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$restTimerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RestTimer = AutoDisposeNotifier<RestTimerState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
