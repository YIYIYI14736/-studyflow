import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DataClassName('SubjectData')
class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SessionData')
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text()();
  TextColumn get subjectName => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  IntColumn get durationSeconds => integer()();
  IntColumn get mode => integer()();
  TextColumn get planId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlanData')
class Plans extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get subjectId => text()();
  TextColumn get subjectName => text().nullable()();
  IntColumn get targetMinutes => integer()();
  DateTimeColumn get deadline => dateTime().nullable()();
  IntColumn get priority => integer()();
  IntColumn get status => integer()();
  TextColumn get subTasks => text()();
  IntColumn get completedMinutes => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Subjects, Sessions, Plans])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'studyflow.db'));
    return NativeDatabase.createInBackground(file);
  });
}
