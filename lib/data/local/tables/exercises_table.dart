import 'package:drift/drift.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get nameKo => text()();
  IntColumn get muscleGroup => integer()();
  IntColumn get equipment => integer()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
