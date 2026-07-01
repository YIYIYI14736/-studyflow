import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyflow/database/database.dart';
import 'package:studyflow/models/models.dart';

class DataBackupService {
  DataBackupService(this._db);

  final AppDatabase _db;

  static const int backupVersion = 1;
  static const String _settingsKey = 'app_settings';
  static const String _memoriesKey = 'ai_memories';

  Future<Map<String, dynamic>> exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = _decodeObject(prefs.getString(_settingsKey));
    final memories = _decodeList(prefs.getString(_memoriesKey));

    return {
      'version': backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'appSettings':
          settings == null ? null : AppSettings.fromJson(settings).toJson(),
      'aiMemories': memories,
      'database': {
        'subjects': (await _db.select(_db.subjects).get())
            .map((row) => row.toJson())
            .toList(),
        'sessions': (await _db.select(_db.sessions).get())
            .map((row) => row.toJson())
            .toList(),
        'plans': (await _db.select(_db.plans).get())
            .map((row) => row.toJson())
            .toList(),
        'wrongQuestions': (await _db.select(_db.wrongQuestions).get())
            .map((row) => row.toJson())
            .toList(),
        'wrongQuestionRounds': (await _db.select(_db.wrongQuestionRounds).get())
            .map((row) => row.toJson())
            .toList(),
      },
    };
  }

  Future<File> createBackupFile() async {
    final data = await exportData();
    final directory = await _backupDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '-');
    final file =
        File(p.join(directory.path, 'studyflow-backup-$timestamp.json'));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
    return file;
  }

  Future<File?> latestBackupFile() async {
    final directory = await _backupDirectory(create: false);
    if (!await directory.exists()) return null;

    final files = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
    if (files.isEmpty) return null;

    files.sort((a, b) {
      final aTime = a.statSync().modified;
      final bTime = b.statSync().modified;
      return bTime.compareTo(aTime);
    });
    return files.first;
  }

  Future<File> restoreLatestBackupFile() async {
    final file = await latestBackupFile();
    if (file == null) {
      throw StateError('没有找到可恢复的备份文件');
    }

    final raw = await file.readAsString();
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('备份文件格式无效');
    }

    await importData(data);
    return file;
  }

  Future<void> importData(Map<String, dynamic> backup) async {
    final database = backup['database'];
    if (database is! Map) {
      throw const FormatException('备份文件缺少 database 节点');
    }
    final dbMap = Map<String, dynamic>.from(database);

    await _db.transaction(() async {
      await _clearDatabaseTables();
      await _insertRows(
        dbMap['subjects'],
        (json) => _db.into(_db.subjects).insert(SubjectData.fromJson(json)),
      );
      await _insertRows(
        dbMap['sessions'],
        (json) => _db.into(_db.sessions).insert(SessionData.fromJson(json)),
      );
      await _insertRows(
        dbMap['plans'],
        (json) => _db.into(_db.plans).insert(PlanData.fromJson(json)),
      );
      await _insertRows(
        dbMap['wrongQuestions'],
        (json) => _db.into(_db.wrongQuestions).insert(WQData.fromJson(json)),
      );
      await _insertRows(
        dbMap['wrongQuestionRounds'],
        (json) => _db
            .into(_db.wrongQuestionRounds)
            .insert(WQRoundData.fromJson(json)),
      );
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    await prefs.remove(_memoriesKey);

    final settings = backup['appSettings'];
    if (settings is Map) {
      final normalized =
          AppSettings.fromJson(Map<String, dynamic>.from(settings));
      await prefs.setString(_settingsKey, jsonEncode(normalized.toJson()));
    }

    final memories = backup['aiMemories'];
    if (memories is List) {
      await prefs.setString(_memoriesKey, jsonEncode(memories));
    }
  }

  Future<void> clearAllData() async {
    await _db.transaction(_clearDatabaseTables);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    await prefs.remove(_memoriesKey);
  }

  Future<void> _insertRows(
    Object? rawRows,
    Future<void> Function(Map<String, dynamic> json) insert,
  ) async {
    if (rawRows is! List) return;
    for (final row in rawRows) {
      if (row is Map) {
        await insert(Map<String, dynamic>.from(row));
      }
    }
  }

  Future<void> _clearDatabaseTables() async {
    await _db.delete(_db.wrongQuestionRounds).go();
    await _db.delete(_db.wrongQuestions).go();
    await _db.delete(_db.plans).go();
    await _db.delete(_db.sessions).go();
    await _db.delete(_db.subjects).go();
  }

  Future<Directory> _backupDirectory({bool create = true}) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'studyflow_backups'));
    if (create) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Map<String, dynamic>? _decodeObject(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  List<dynamic> _decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded : const [];
  }
}
