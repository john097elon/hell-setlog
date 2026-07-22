// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'8ab73ef1293e27f6de024928c2e888eefcb35e1d';

/// See also [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = ProviderRef<AppDatabase>;
String _$exerciseRepositoryHash() =>
    r'6ce5611d0c4b9fd5a4be753da177270353c91f14';

/// Provides the local repository after its built-in exercise list is seeded.
///
/// Copied from [exerciseRepository].
@ProviderFor(exerciseRepository)
final exerciseRepositoryProvider = FutureProvider<ExerciseRepository>.internal(
  exerciseRepository,
  name: r'exerciseRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exerciseRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExerciseRepositoryRef = FutureProviderRef<ExerciseRepository>;
String _$exerciseSearchHash() => r'b52f3db0df75cf786c0c6a03fe2e0e9ec6943673';

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

abstract class _$ExerciseSearch
    extends BuildlessAutoDisposeAsyncNotifier<Result<List<Exercise>, Failure>> {
  late final String? query;
  late final MuscleGroup? muscleGroup;
  late final Equipment? equipment;

  FutureOr<Result<List<Exercise>, Failure>> build({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
  });
}

/// Holds the result of a searchable, filterable exercise query.
///
/// Copied from [ExerciseSearch].
@ProviderFor(ExerciseSearch)
const exerciseSearchProvider = ExerciseSearchFamily();

/// Holds the result of a searchable, filterable exercise query.
///
/// Copied from [ExerciseSearch].
class ExerciseSearchFamily
    extends Family<AsyncValue<Result<List<Exercise>, Failure>>> {
  /// Holds the result of a searchable, filterable exercise query.
  ///
  /// Copied from [ExerciseSearch].
  const ExerciseSearchFamily();

  /// Holds the result of a searchable, filterable exercise query.
  ///
  /// Copied from [ExerciseSearch].
  ExerciseSearchProvider call({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
  }) {
    return ExerciseSearchProvider(
      query: query,
      muscleGroup: muscleGroup,
      equipment: equipment,
    );
  }

  @override
  ExerciseSearchProvider getProviderOverride(
    covariant ExerciseSearchProvider provider,
  ) {
    return call(
      query: provider.query,
      muscleGroup: provider.muscleGroup,
      equipment: provider.equipment,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'exerciseSearchProvider';
}

/// Holds the result of a searchable, filterable exercise query.
///
/// Copied from [ExerciseSearch].
class ExerciseSearchProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ExerciseSearch,
          Result<List<Exercise>, Failure>
        > {
  /// Holds the result of a searchable, filterable exercise query.
  ///
  /// Copied from [ExerciseSearch].
  ExerciseSearchProvider({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
  }) : this._internal(
         () => ExerciseSearch()
           ..query = query
           ..muscleGroup = muscleGroup
           ..equipment = equipment,
         from: exerciseSearchProvider,
         name: r'exerciseSearchProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$exerciseSearchHash,
         dependencies: ExerciseSearchFamily._dependencies,
         allTransitiveDependencies:
             ExerciseSearchFamily._allTransitiveDependencies,
         query: query,
         muscleGroup: muscleGroup,
         equipment: equipment,
       );

  ExerciseSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
    required this.muscleGroup,
    required this.equipment,
  }) : super.internal();

  final String? query;
  final MuscleGroup? muscleGroup;
  final Equipment? equipment;

  @override
  FutureOr<Result<List<Exercise>, Failure>> runNotifierBuild(
    covariant ExerciseSearch notifier,
  ) {
    return notifier.build(
      query: query,
      muscleGroup: muscleGroup,
      equipment: equipment,
    );
  }

  @override
  Override overrideWith(ExerciseSearch Function() create) {
    return ProviderOverride(
      origin: this,
      override: ExerciseSearchProvider._internal(
        () => create()
          ..query = query
          ..muscleGroup = muscleGroup
          ..equipment = equipment,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
        muscleGroup: muscleGroup,
        equipment: equipment,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ExerciseSearch,
    Result<List<Exercise>, Failure>
  >
  createElement() {
    return _ExerciseSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseSearchProvider &&
        other.query == query &&
        other.muscleGroup == muscleGroup &&
        other.equipment == equipment;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, muscleGroup.hashCode);
    hash = _SystemHash.combine(hash, equipment.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ExerciseSearchRef
    on AutoDisposeAsyncNotifierProviderRef<Result<List<Exercise>, Failure>> {
  /// The parameter `query` of this provider.
  String? get query;

  /// The parameter `muscleGroup` of this provider.
  MuscleGroup? get muscleGroup;

  /// The parameter `equipment` of this provider.
  Equipment? get equipment;
}

class _ExerciseSearchProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ExerciseSearch,
          Result<List<Exercise>, Failure>
        >
    with ExerciseSearchRef {
  _ExerciseSearchProviderElement(super.provider);

  @override
  String? get query => (origin as ExerciseSearchProvider).query;
  @override
  MuscleGroup? get muscleGroup =>
      (origin as ExerciseSearchProvider).muscleGroup;
  @override
  Equipment? get equipment => (origin as ExerciseSearchProvider).equipment;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
