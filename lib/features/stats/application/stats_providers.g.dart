// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statsRepositoryHash() => r'ce8a1271a68f47bcc18dcac5e037a9e627935076';

/// See also [statsRepository].
@ProviderFor(statsRepository)
final statsRepositoryProvider = Provider<StatsRepository>.internal(
  statsRepository,
  name: r'statsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatsRepositoryRef = ProviderRef<StatsRepository>;
String _$weeklyVolumeHash() => r'b6de7cd211eb13344c807139ae004b0ab18ce614';

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

/// See also [weeklyVolume].
@ProviderFor(weeklyVolume)
const weeklyVolumeProvider = WeeklyVolumeFamily();

/// See also [weeklyVolume].
class WeeklyVolumeFamily
    extends Family<AsyncValue<Result<Map<DateTime, double>, Failure>>> {
  /// See also [weeklyVolume].
  const WeeklyVolumeFamily();

  /// See also [weeklyVolume].
  WeeklyVolumeProvider call({int days = 7}) {
    return WeeklyVolumeProvider(days: days);
  }

  @override
  WeeklyVolumeProvider getProviderOverride(
    covariant WeeklyVolumeProvider provider,
  ) {
    return call(days: provider.days);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'weeklyVolumeProvider';
}

/// See also [weeklyVolume].
class WeeklyVolumeProvider
    extends AutoDisposeFutureProvider<Result<Map<DateTime, double>, Failure>> {
  /// See also [weeklyVolume].
  WeeklyVolumeProvider({int days = 7})
    : this._internal(
        (ref) => weeklyVolume(ref as WeeklyVolumeRef, days: days),
        from: weeklyVolumeProvider,
        name: r'weeklyVolumeProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$weeklyVolumeHash,
        dependencies: WeeklyVolumeFamily._dependencies,
        allTransitiveDependencies:
            WeeklyVolumeFamily._allTransitiveDependencies,
        days: days,
      );

  WeeklyVolumeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.days,
  }) : super.internal();

  final int days;

  @override
  Override overrideWith(
    FutureOr<Result<Map<DateTime, double>, Failure>> Function(
      WeeklyVolumeRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyVolumeProvider._internal(
        (ref) => create(ref as WeeklyVolumeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        days: days,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Result<Map<DateTime, double>, Failure>>
  createElement() {
    return _WeeklyVolumeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyVolumeProvider && other.days == days;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, days.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WeeklyVolumeRef
    on AutoDisposeFutureProviderRef<Result<Map<DateTime, double>, Failure>> {
  /// The parameter `days` of this provider.
  int get days;
}

class _WeeklyVolumeProviderElement
    extends
        AutoDisposeFutureProviderElement<Result<Map<DateTime, double>, Failure>>
    with WeeklyVolumeRef {
  _WeeklyVolumeProviderElement(super.provider);

  @override
  int get days => (origin as WeeklyVolumeProvider).days;
}

String _$bodyPartSplitHash() => r'22e2224ee07e40d4ac814d6cf57305d3416066fd';

/// See also [bodyPartSplit].
@ProviderFor(bodyPartSplit)
const bodyPartSplitProvider = BodyPartSplitFamily();

/// See also [bodyPartSplit].
class BodyPartSplitFamily
    extends Family<AsyncValue<Result<Map<MuscleGroup, double>, Failure>>> {
  /// See also [bodyPartSplit].
  const BodyPartSplitFamily();

  /// See also [bodyPartSplit].
  BodyPartSplitProvider call({int days = 30}) {
    return BodyPartSplitProvider(days: days);
  }

  @override
  BodyPartSplitProvider getProviderOverride(
    covariant BodyPartSplitProvider provider,
  ) {
    return call(days: provider.days);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bodyPartSplitProvider';
}

/// See also [bodyPartSplit].
class BodyPartSplitProvider
    extends
        AutoDisposeFutureProvider<Result<Map<MuscleGroup, double>, Failure>> {
  /// See also [bodyPartSplit].
  BodyPartSplitProvider({int days = 30})
    : this._internal(
        (ref) => bodyPartSplit(ref as BodyPartSplitRef, days: days),
        from: bodyPartSplitProvider,
        name: r'bodyPartSplitProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bodyPartSplitHash,
        dependencies: BodyPartSplitFamily._dependencies,
        allTransitiveDependencies:
            BodyPartSplitFamily._allTransitiveDependencies,
        days: days,
      );

  BodyPartSplitProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.days,
  }) : super.internal();

  final int days;

  @override
  Override overrideWith(
    FutureOr<Result<Map<MuscleGroup, double>, Failure>> Function(
      BodyPartSplitRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BodyPartSplitProvider._internal(
        (ref) => create(ref as BodyPartSplitRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        days: days,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Result<Map<MuscleGroup, double>, Failure>>
  createElement() {
    return _BodyPartSplitProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BodyPartSplitProvider && other.days == days;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, days.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BodyPartSplitRef
    on AutoDisposeFutureProviderRef<Result<Map<MuscleGroup, double>, Failure>> {
  /// The parameter `days` of this provider.
  int get days;
}

class _BodyPartSplitProviderElement
    extends
        AutoDisposeFutureProviderElement<
          Result<Map<MuscleGroup, double>, Failure>
        >
    with BodyPartSplitRef {
  _BodyPartSplitProviderElement(super.provider);

  @override
  int get days => (origin as BodyPartSplitProvider).days;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
