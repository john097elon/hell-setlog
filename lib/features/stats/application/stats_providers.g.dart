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

String _$personalRecordsHash() => r'76bcc6124edd91adaf1e6a32aa90a8dff4b33647';

/// Loads the personal records for one exercise.
///
/// Copied from [personalRecords].
@ProviderFor(personalRecords)
const personalRecordsProvider = PersonalRecordsFamily();

/// Loads the personal records for one exercise.
///
/// Copied from [personalRecords].
class PersonalRecordsFamily
    extends Family<AsyncValue<Result<List<PersonalRecord>, Failure>>> {
  /// Loads the personal records for one exercise.
  ///
  /// Copied from [personalRecords].
  const PersonalRecordsFamily();

  /// Loads the personal records for one exercise.
  ///
  /// Copied from [personalRecords].
  PersonalRecordsProvider call(String exerciseId) {
    return PersonalRecordsProvider(exerciseId);
  }

  @override
  PersonalRecordsProvider getProviderOverride(
    covariant PersonalRecordsProvider provider,
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
  String? get name => r'personalRecordsProvider';
}

/// Loads the personal records for one exercise.
///
/// Copied from [personalRecords].
class PersonalRecordsProvider
    extends AutoDisposeFutureProvider<Result<List<PersonalRecord>, Failure>> {
  /// Loads the personal records for one exercise.
  ///
  /// Copied from [personalRecords].
  PersonalRecordsProvider(String exerciseId)
    : this._internal(
        (ref) => personalRecords(ref as PersonalRecordsRef, exerciseId),
        from: personalRecordsProvider,
        name: r'personalRecordsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$personalRecordsHash,
        dependencies: PersonalRecordsFamily._dependencies,
        allTransitiveDependencies:
            PersonalRecordsFamily._allTransitiveDependencies,
        exerciseId: exerciseId,
      );

  PersonalRecordsProvider._internal(
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
    FutureOr<Result<List<PersonalRecord>, Failure>> Function(
      PersonalRecordsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PersonalRecordsProvider._internal(
        (ref) => create(ref as PersonalRecordsRef),
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
  AutoDisposeFutureProviderElement<Result<List<PersonalRecord>, Failure>>
  createElement() {
    return _PersonalRecordsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PersonalRecordsProvider && other.exerciseId == exerciseId;
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
mixin PersonalRecordsRef
    on AutoDisposeFutureProviderRef<Result<List<PersonalRecord>, Failure>> {
  /// The parameter `exerciseId` of this provider.
  String get exerciseId;
}

class _PersonalRecordsProviderElement
    extends
        AutoDisposeFutureProviderElement<Result<List<PersonalRecord>, Failure>>
    with PersonalRecordsRef {
  _PersonalRecordsProviderElement(super.provider);

  @override
  String get exerciseId => (origin as PersonalRecordsProvider).exerciseId;
}

String _$weeklyWorkoutDaysHash() => r'7a3b71f61b6142ec4f5a8dceae42f76e79e413ef';

/// 이번 주에 실제로 운동한 날 수. 볼륨으로 세면 러닝·주짓수만 한 주가 0일이 된다.
///
/// Copied from [weeklyWorkoutDays].
@ProviderFor(weeklyWorkoutDays)
const weeklyWorkoutDaysProvider = WeeklyWorkoutDaysFamily();

/// 이번 주에 실제로 운동한 날 수. 볼륨으로 세면 러닝·주짓수만 한 주가 0일이 된다.
///
/// Copied from [weeklyWorkoutDays].
class WeeklyWorkoutDaysFamily extends Family<AsyncValue<Result<int, Failure>>> {
  /// 이번 주에 실제로 운동한 날 수. 볼륨으로 세면 러닝·주짓수만 한 주가 0일이 된다.
  ///
  /// Copied from [weeklyWorkoutDays].
  const WeeklyWorkoutDaysFamily();

  /// 이번 주에 실제로 운동한 날 수. 볼륨으로 세면 러닝·주짓수만 한 주가 0일이 된다.
  ///
  /// Copied from [weeklyWorkoutDays].
  WeeklyWorkoutDaysProvider call({int days = 7}) {
    return WeeklyWorkoutDaysProvider(days: days);
  }

  @override
  WeeklyWorkoutDaysProvider getProviderOverride(
    covariant WeeklyWorkoutDaysProvider provider,
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
  String? get name => r'weeklyWorkoutDaysProvider';
}

/// 이번 주에 실제로 운동한 날 수. 볼륨으로 세면 러닝·주짓수만 한 주가 0일이 된다.
///
/// Copied from [weeklyWorkoutDays].
class WeeklyWorkoutDaysProvider
    extends AutoDisposeFutureProvider<Result<int, Failure>> {
  /// 이번 주에 실제로 운동한 날 수. 볼륨으로 세면 러닝·주짓수만 한 주가 0일이 된다.
  ///
  /// Copied from [weeklyWorkoutDays].
  WeeklyWorkoutDaysProvider({int days = 7})
    : this._internal(
        (ref) => weeklyWorkoutDays(ref as WeeklyWorkoutDaysRef, days: days),
        from: weeklyWorkoutDaysProvider,
        name: r'weeklyWorkoutDaysProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$weeklyWorkoutDaysHash,
        dependencies: WeeklyWorkoutDaysFamily._dependencies,
        allTransitiveDependencies:
            WeeklyWorkoutDaysFamily._allTransitiveDependencies,
        days: days,
      );

  WeeklyWorkoutDaysProvider._internal(
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
    FutureOr<Result<int, Failure>> Function(WeeklyWorkoutDaysRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyWorkoutDaysProvider._internal(
        (ref) => create(ref as WeeklyWorkoutDaysRef),
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
  AutoDisposeFutureProviderElement<Result<int, Failure>> createElement() {
    return _WeeklyWorkoutDaysProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyWorkoutDaysProvider && other.days == days;
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
mixin WeeklyWorkoutDaysRef
    on AutoDisposeFutureProviderRef<Result<int, Failure>> {
  /// The parameter `days` of this provider.
  int get days;
}

class _WeeklyWorkoutDaysProviderElement
    extends AutoDisposeFutureProviderElement<Result<int, Failure>>
    with WeeklyWorkoutDaysRef {
  _WeeklyWorkoutDaysProviderElement(super.provider);

  @override
  int get days => (origin as WeeklyWorkoutDaysProvider).days;
}

String _$weeklyDisciplineCountsHash() =>
    r'98bde82df6dad6f52cfeebc482d60b24c478f2b2';

/// Counts completed weekly records by discipline, including non-weight sports.
///
/// Copied from [weeklyDisciplineCounts].
@ProviderFor(weeklyDisciplineCounts)
const weeklyDisciplineCountsProvider = WeeklyDisciplineCountsFamily();

/// Counts completed weekly records by discipline, including non-weight sports.
///
/// Copied from [weeklyDisciplineCounts].
class WeeklyDisciplineCountsFamily
    extends Family<AsyncValue<Result<Map<Discipline, int>, Failure>>> {
  /// Counts completed weekly records by discipline, including non-weight sports.
  ///
  /// Copied from [weeklyDisciplineCounts].
  const WeeklyDisciplineCountsFamily();

  /// Counts completed weekly records by discipline, including non-weight sports.
  ///
  /// Copied from [weeklyDisciplineCounts].
  WeeklyDisciplineCountsProvider call({int days = 7}) {
    return WeeklyDisciplineCountsProvider(days: days);
  }

  @override
  WeeklyDisciplineCountsProvider getProviderOverride(
    covariant WeeklyDisciplineCountsProvider provider,
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
  String? get name => r'weeklyDisciplineCountsProvider';
}

/// Counts completed weekly records by discipline, including non-weight sports.
///
/// Copied from [weeklyDisciplineCounts].
class WeeklyDisciplineCountsProvider
    extends AutoDisposeFutureProvider<Result<Map<Discipline, int>, Failure>> {
  /// Counts completed weekly records by discipline, including non-weight sports.
  ///
  /// Copied from [weeklyDisciplineCounts].
  WeeklyDisciplineCountsProvider({int days = 7})
    : this._internal(
        (ref) => weeklyDisciplineCounts(
          ref as WeeklyDisciplineCountsRef,
          days: days,
        ),
        from: weeklyDisciplineCountsProvider,
        name: r'weeklyDisciplineCountsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$weeklyDisciplineCountsHash,
        dependencies: WeeklyDisciplineCountsFamily._dependencies,
        allTransitiveDependencies:
            WeeklyDisciplineCountsFamily._allTransitiveDependencies,
        days: days,
      );

  WeeklyDisciplineCountsProvider._internal(
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
    FutureOr<Result<Map<Discipline, int>, Failure>> Function(
      WeeklyDisciplineCountsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyDisciplineCountsProvider._internal(
        (ref) => create(ref as WeeklyDisciplineCountsRef),
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
  AutoDisposeFutureProviderElement<Result<Map<Discipline, int>, Failure>>
  createElement() {
    return _WeeklyDisciplineCountsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyDisciplineCountsProvider && other.days == days;
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
mixin WeeklyDisciplineCountsRef
    on AutoDisposeFutureProviderRef<Result<Map<Discipline, int>, Failure>> {
  /// The parameter `days` of this provider.
  int get days;
}

class _WeeklyDisciplineCountsProviderElement
    extends
        AutoDisposeFutureProviderElement<Result<Map<Discipline, int>, Failure>>
    with WeeklyDisciplineCountsRef {
  _WeeklyDisciplineCountsProviderElement(super.provider);

  @override
  int get days => (origin as WeeklyDisciplineCountsProvider).days;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
