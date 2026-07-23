// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$routineRepositoryHash() => r'3cdcd9212721ac7945b2c4d51ef970a35e9bbf07';

/// See also [routineRepository].
@ProviderFor(routineRepository)
final routineRepositoryProvider = Provider<RoutineRepository>.internal(
  routineRepository,
  name: r'routineRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$routineRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RoutineRepositoryRef = ProviderRef<RoutineRepository>;
String _$routinesHash() => r'502b216e59689f48a27537871bc09025ca309560';

/// See also [routines].
@ProviderFor(routines)
final routinesProvider =
    AutoDisposeFutureProvider<Result<List<Routine>, Failure>>.internal(
      routines,
      name: r'routinesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$routinesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RoutinesRef =
    AutoDisposeFutureProviderRef<Result<List<Routine>, Failure>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
