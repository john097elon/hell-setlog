// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_name_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$exerciseNameHash() => r'4b165811d28765101561211d353e5fbb4f15ed52';

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

/// Resolves an exercise identifier to display text outside presentation code.
///
/// Copied from [exerciseName].
@ProviderFor(exerciseName)
const exerciseNameProvider = ExerciseNameFamily();

/// Resolves an exercise identifier to display text outside presentation code.
///
/// Copied from [exerciseName].
class ExerciseNameFamily extends Family<AsyncValue<String?>> {
  /// Resolves an exercise identifier to display text outside presentation code.
  ///
  /// Copied from [exerciseName].
  const ExerciseNameFamily();

  /// Resolves an exercise identifier to display text outside presentation code.
  ///
  /// Copied from [exerciseName].
  ExerciseNameProvider call(String exerciseId) {
    return ExerciseNameProvider(exerciseId);
  }

  @override
  ExerciseNameProvider getProviderOverride(
    covariant ExerciseNameProvider provider,
  ) {
    return call(provider.exerciseId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'exerciseNameProvider';
}

/// Resolves an exercise identifier to display text outside presentation code.
///
/// Copied from [exerciseName].
class ExerciseNameProvider extends AutoDisposeFutureProvider<String?> {
  /// Resolves an exercise identifier to display text outside presentation code.
  ///
  /// Copied from [exerciseName].
  ExerciseNameProvider(String exerciseId)
    : this._internal(
        (ref) => exerciseName(ref as ExerciseNameRef, exerciseId),
        from: exerciseNameProvider,
        name: r'exerciseNameProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$exerciseNameHash,
        dependencies: ExerciseNameFamily._dependencies,
        allTransitiveDependencies:
            ExerciseNameFamily._allTransitiveDependencies,
        exerciseId: exerciseId,
      );

  ExerciseNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.exerciseId,
  }) : super.internal();

  final String exerciseId;

  @override
  Override overrideWith(
    FutureOr<String?> Function(ExerciseNameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExerciseNameProvider._internal(
        (ref) => create(ref as ExerciseNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        exerciseId: exerciseId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _ExerciseNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseNameProvider && other.exerciseId == exerciseId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, exerciseId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ExerciseNameRef on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `exerciseId` of this provider.
  String get exerciseId;
}

class _ExerciseNameProviderElement
    extends AutoDisposeFutureProviderElement<String?>
    with ExerciseNameRef {
  _ExerciseNameProviderElement(super.provider);

  @override
  String get exerciseId => (origin as ExerciseNameProvider).exerciseId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
