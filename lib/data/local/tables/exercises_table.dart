import 'package:drift/drift.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get nameKo => text()();
  IntColumn get muscleGroup => integer()();
  IntColumn get equipment => integer()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get thumbnailUrl => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
