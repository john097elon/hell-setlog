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
String _$routineItemsHash() => r'4f26ba9aa021729cf11b41d83b19a19fce7023c7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [routineItems].
@ProviderFor(routineItems)
const routineItemsProvider = RoutineItemsFamily();

/// See also [routineItems].
class RoutineItemsFamily
    extends Family<AsyncValue<Result<List<RoutineItem>, Failure>>> {
  /// See also [routineItems].
  const RoutineItemsFamily();

  /// See also [routineItems].
  RoutineItemsProvider call(String routineId) {
    return RoutineItemsProvider(routineId);
  }

  @override
  RoutineItemsProvider getProviderOverride(
    covariant RoutineItemsProvider provider,
  ) {
    return call(provider.routineId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'routineItemsProvider';
}

/// See also [routineItems].
class RoutineItemsProvider
    extends AutoDisposeFutureProvider<Result<List<RoutineItem>, Failure>> {
  /// See also [routineItems].
  RoutineItemsProvider(String routineId)
    : this._internal(
        (ref) => routineItems(ref as RoutineItemsRef, routineId),
        from: routineItemsProvider,
        name: r'routineItemsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$routineItemsHash,
        dependencies: RoutineItemsFamily._dependencies,
        allTransitiveDependencies:
            RoutineItemsFamily._allTransitiveDependencies,
        routineId: routineId,
      );

  RoutineItemsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.routineId,
  }) : super.internal();

  final String routineId;

  @override
  Override overrideWith(
    FutureOr<Result<List<RoutineItem>, Failure>> Function(
      RoutineItemsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RoutineItemsProvider._internal(
        (ref) => create(ref as RoutineItemsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        routineId: routineId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Result<List<RoutineItem>, Failure>>
  createElement() {
    return _RoutineItemsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RoutineItemsProvider && other.routineId == routineId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, routineId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RoutineItemsRef
    on AutoDisposeFutureProviderRef<Result<List<RoutineItem>, Failure>> {
  /// The parameter `routineId` of this provider.
  String get routineId;
}

class _RoutineItemsProviderElement
    extends AutoDisposeFutureProviderElement<Result<List<RoutineItem>, Failure>>
    with RoutineItemsRef {
  _RoutineItemsProviderElement(super.provider);

  @override
  String get routineId => (origin as RoutineItemsProvider).routineId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
