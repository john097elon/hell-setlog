import 'package:drift/drift.dart';

class PersonalRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get type => integer()();
  RealColumn get value => real()();
  DateTimeColumn get achievedAt => dateTime()();
  TextColumn get sessionId => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
