import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyflow/database/database.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/services/data_backup_service.dart';

void main() {
  group('DataBackupService', () {
    late AppDatabase db;
    late DataBackupService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
      service = DataBackupService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('exports, clears, and restores app data', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'app_settings',
        jsonEncode(AppSettings().toJson()),
      );

      await db.into(db.subjects).insert(
            SubjectsCompanion.insert(
              id: 'subject-1',
              name: '数学',
              color: const Value('4294198070'),
              createdAt: DateTime(2026, 1, 1),
            ),
          );
      await db.into(db.plans).insert(
            PlansCompanion.insert(
              id: 'plan-1',
              title: '复习函数',
              subjectId: 'subject-1',
              targetMinutes: 120,
              priority: PlanPriority.medium.index,
              status: PlanStatus.inProgress.index,
              subTasks: jsonEncode([
                SubTask(title: '整理公式').toJson(),
              ]),
              completedMinutes: 30,
              createdAt: DateTime(2026, 1, 1),
            ),
          );
      await db.into(db.wrongQuestions).insert(
            WrongQuestionsCompanion.insert(
              id: 'question-1',
              subjectId: 'subject-1',
              pageNumber: 12,
              questionNumber: 3,
              createdAt: DateTime(2026, 1, 1),
            ),
          );
      await db.into(db.wrongQuestionRounds).insert(
            WrongQuestionRoundsCompanion.insert(
              id: 'round-1',
              questionId: 'question-1',
              round: 1,
              status: WQStatus.wrong.index,
              reviewedAt: DateTime(2026, 1, 2),
            ),
          );

      final backup = await service.exportData();
      await service.clearAllData();

      expect(await db.select(db.subjects).get(), isEmpty);
      expect(await db.select(db.plans).get(), isEmpty);
      expect(await db.select(db.wrongQuestions).get(), isEmpty);
      expect(await db.select(db.wrongQuestionRounds).get(), isEmpty);
      expect(prefs.getString('app_settings'), isNull);

      await service.importData(backup);

      expect(await db.select(db.subjects).get(), hasLength(1));
      expect(await db.select(db.plans).get(), hasLength(1));
      expect(await db.select(db.wrongQuestions).get(), hasLength(1));
      expect(await db.select(db.wrongQuestionRounds).get(), hasLength(1));
      expect(
        jsonDecode(prefs.getString('app_settings')!)['pomodoroWorkMinutes'],
        25,
      );
    });
  });
}
