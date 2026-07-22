// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$workoutRepositoryHash() => r'283501e1eb64b93d468eee9b1b8f9e9e04da0af3';

/// See also [workoutRepository].
@ProviderFor(workoutRepository)
final workoutRepositoryProvider = Provider<WorkoutRepository>.internal(
  workoutRepository,
  name: r'workoutRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$workoutRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WorkoutRepositoryRef = ProviderRef<WorkoutRepository>;
String _$activeSessionHash() => r'66e7dba4104330035c9a3aa40681ffe2ac566ca2';

/// See also [activeSession].
@ProviderFor(activeSession)
final activeSessionProvider =
    AutoDisposeFutureProvider<Result<WorkoutSession, Failure>>.internal(
      activeSession,
      name: r'activeSessionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeSessionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveSessionRef =
    AutoDisposeFutureProviderRef<Result<WorkoutSession, Failure>>;
String _$sessionSetsHash() => r'58227ba64058f17f725b20139777858f9a937347';

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

/// See also [sessionSets].
@ProviderFor(sessionSets)
const sessionSetsProvider = SessionSetsFamily();

/// See also [sessionSets].
class SessionSetsFamily extends Family<AsyncValue<List<WorkoutSet>>> {
  /// See also [sessionSets].
  const SessionSetsFamily();

  /// See also [sessionSets].
  SessionSetsProvider call(String sessionId) {
    return SessionSetsProvider(sessionId);
  }

  @override
  SessionSetsProvider getProviderOverride(
    covariant SessionSetsProvider provider,
  ) {
    return call(provider.sessionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sessionSetsProvider';
}

/// See also [sessionSets].
class SessionSetsProvider extends AutoDisposeStreamProvider<List<WorkoutSet>> {
  /// See also [sessionSets].
  SessionSetsProvider(String sessionId)
    : this._internal(
        (ref) => sessionSets(ref as SessionSetsRef, sessionId),
        from: sessionSetsProvider,
        name: r'sessionSetsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sessionSetsHash,
        dependencies: SessionSetsFamily._dependencies,
        allTransitiveDependencies: SessionSetsFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  SessionSetsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sessionId,
  }) : super.internal();

  final String sessionId;

  @override
  Override overrideWith(
    Stream<List<WorkoutSet>> Function(SessionSetsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SessionSetsProvider._internal(
        (ref) => create(ref as SessionSetsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sessionId: sessionId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<WorkoutSet>> createElement() {
    return _SessionSetsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionSetsProvider && other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SessionSetsRef on AutoDisposeStreamProviderRef<List<WorkoutSet>> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _SessionSetsProviderElement
    extends AutoDisposeStreamProviderElement<List<WorkoutSet>>
    with SessionSetsRef {
  _SessionSetsProviderElement(super.provider);

  @override
  String get sessionId => (origin as SessionSetsProvider).sessionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
