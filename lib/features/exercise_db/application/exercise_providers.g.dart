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
String _$recentExercisesHash() => r'da402988ad02930b5a55395ac0c90f646d469b2e';

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

/// 최근에 기록한 순서대로 운동을 돌려준다. 매번 목록을 뒤지지 않게 하려는 것이라
/// 정렬 기준은 마지막으로 기록한 시각이다.
///
/// Copied from [recentExercises].
@ProviderFor(recentExercises)
const recentExercisesProvider = RecentExercisesFamily();

/// 최근에 기록한 순서대로 운동을 돌려준다. 매번 목록을 뒤지지 않게 하려는 것이라
/// 정렬 기준은 마지막으로 기록한 시각이다.
///
/// Copied from [recentExercises].
class RecentExercisesFamily extends Family<AsyncValue<List<Exercise>>> {
  /// 최근에 기록한 순서대로 운동을 돌려준다. 매번 목록을 뒤지지 않게 하려는 것이라
  /// 정렬 기준은 마지막으로 기록한 시각이다.
  ///
  /// Copied from [recentExercises].
  const RecentExercisesFamily();

  /// 최근에 기록한 순서대로 운동을 돌려준다. 매번 목록을 뒤지지 않게 하려는 것이라
  /// 정렬 기준은 마지막으로 기록한 시각이다.
  ///
  /// Copied from [recentExercises].
  RecentExercisesProvider call({int limit = 8}) {
    return RecentExercisesProvider(limit: limit);
  }

  @override
  RecentExercisesProvider getProviderOverride(
    covariant RecentExercisesProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'recentExercisesProvider';
}

/// 최근에 기록한 순서대로 운동을 돌려준다. 매번 목록을 뒤지지 않게 하려는 것이라
/// 정렬 기준은 마지막으로 기록한 시각이다.
///
/// Copied from [recentExercises].
class RecentExercisesProvider
    extends AutoDisposeFutureProvider<List<Exercise>> {
  /// 최근에 기록한 순서대로 운동을 돌려준다. 매번 목록을 뒤지지 않게 하려는 것이라
  /// 정렬 기준은 마지막으로 기록한 시각이다.
  ///
  /// Copied from [recentExercises].
  RecentExercisesProvider({int limit = 8})
    : this._internal(
        (ref) => recentExercises(ref as RecentExercisesRef, limit: limit),
        from: recentExercisesProvider,
        name: r'recentExercisesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$recentExercisesHash,
        dependencies: RecentExercisesFamily._dependencies,
        allTransitiveDependencies:
            RecentExercisesFamily._allTransitiveDependencies,
        limit: limit,
      );

  RecentExercisesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<Exercise>> Function(RecentExercisesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecentExercisesProvider._internal(
        (ref) => create(ref as RecentExercisesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Exercise>> createElement() {
    return _RecentExercisesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentExercisesProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RecentExercisesRef on AutoDisposeFutureProviderRef<List<Exercise>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _RecentExercisesProviderElement
    extends AutoDisposeFutureProviderElement<List<Exercise>>
    with RecentExercisesRef {
  _RecentExercisesProviderElement(super.provider);

  @override
  int get limit => (origin as RecentExercisesProvider).limit;
}

String _$exerciseByIdHash() => r'ac4401f95677ade76a986682dee73ec63c46a743';

/// Loads the full exercise metadata used outside the exercise picker.
///
/// Copied from [exerciseById].
@ProviderFor(exerciseById)
const exerciseByIdProvider = ExerciseByIdFamily();

/// Loads the full exercise metadata used outside the exercise picker.
///
/// Copied from [exerciseById].
class ExerciseByIdFamily extends Family<AsyncValue<Result<Exercise, Failure>>> {
  /// Loads the full exercise metadata used outside the exercise picker.
  ///
  /// Copied from [exerciseById].
  const ExerciseByIdFamily();

  /// Loads the full exercise metadata used outside the exercise picker.
  ///
  /// Copied from [exerciseById].
  ExerciseByIdProvider call(String id) {
    return ExerciseByIdProvider(id);
  }

  @override
  ExerciseByIdProvider getProviderOverride(
    covariant ExerciseByIdProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'exerciseByIdProvider';
}

/// Loads the full exercise metadata used outside the exercise picker.
///
/// Copied from [exerciseById].
class ExerciseByIdProvider
    extends AutoDisposeFutureProvider<Result<Exercise, Failure>> {
  /// Loads the full exercise metadata used outside the exercise picker.
  ///
  /// Copied from [exerciseById].
  ExerciseByIdProvider(String id)
    : this._internal(
        (ref) => exerciseById(ref as ExerciseByIdRef, id),
        from: exerciseByIdProvider,
        name: r'exerciseByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$exerciseByIdHash,
        dependencies: ExerciseByIdFamily._dependencies,
        allTransitiveDependencies:
            ExerciseByIdFamily._allTransitiveDependencies,
        id: id,
      );

  ExerciseByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Result<Exercise, Failure>> Function(ExerciseByIdRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExerciseByIdProvider._internal(
        (ref) => create(ref as ExerciseByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Result<Exercise, Failure>> createElement() {
    return _ExerciseByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ExerciseByIdRef
    on AutoDisposeFutureProviderRef<Result<Exercise, Failure>> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ExerciseByIdProviderElement
    extends AutoDisposeFutureProviderElement<Result<Exercise, Failure>>
    with ExerciseByIdRef {
  _ExerciseByIdProviderElement(super.provider);

  @override
  String get id => (origin as ExerciseByIdProvider).id;
}

String _$customExerciseControllerHash() =>
    r'9a59375376d8ec2ada3cbf5d657e5ae8de0123d2';

/// See also [customExerciseController].
@ProviderFor(customExerciseController)
final customExerciseControllerProvider =
    AutoDisposeProvider<CustomExerciseController>.internal(
      customExerciseController,
      name: r'customExerciseControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$customExerciseControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CustomExerciseControllerRef =
    AutoDisposeProviderRef<CustomExerciseController>;
String _$exerciseSearchHash() => r'b6192c8c9e114f5499397ee01bc826e0988ffa87';

abstract class _$ExerciseSearch
    extends BuildlessAutoDisposeAsyncNotifier<Result<List<Exercise>, Failure>> {
  late final String? query;
  late final MuscleGroup? muscleGroup;
  late final Equipment? equipment;
  late final Discipline? discipline;

  FutureOr<Result<List<Exercise>, Failure>> build({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
    Discipline? discipline,
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
    Discipline? discipline,
  }) {
    return ExerciseSearchProvider(
      query: query,
      muscleGroup: muscleGroup,
      equipment: equipment,
      discipline: discipline,
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
      discipline: provider.discipline,
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
    Discipline? discipline,
  }) : this._internal(
         () => ExerciseSearch()
           ..query = query
           ..muscleGroup = muscleGroup
           ..equipment = equipment
           ..discipline = discipline,
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
         discipline: discipline,
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
    required this.discipline,
  }) : super.internal();

  final String? query;
  final MuscleGroup? muscleGroup;
  final Equipment? equipment;
  final Discipline? discipline;

  @override
  FutureOr<Result<List<Exercise>, Failure>> runNotifierBuild(
    covariant ExerciseSearch notifier,
  ) {
    return notifier.build(
      query: query,
      muscleGroup: muscleGroup,
      equipment: equipment,
      discipline: discipline,
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
          ..equipment = equipment
          ..discipline = discipline,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
        muscleGroup: muscleGroup,
        equipment: equipment,
        discipline: discipline,
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
        other.equipment == equipment &&
        other.discipline == discipline;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, muscleGroup.hashCode);
    hash = _SystemHash.combine(hash, equipment.hashCode);
    hash = _SystemHash.combine(hash, discipline.hashCode);

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

  /// The parameter `discipline` of this provider.
  Discipline? get discipline;
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
  @override
  Discipline? get discipline => (origin as ExerciseSearchProvider).discipline;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
