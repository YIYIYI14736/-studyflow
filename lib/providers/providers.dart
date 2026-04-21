import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/database/database.dart';
import 'package:drift/drift.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('app_settings');
    if (json != null) {
      state = AppSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', jsonEncode(newSettings.toJson()));
  }

  Future<void> setApiKey(String? key) async {
    await updateSettings(state.copyWith(openaiApiKey: key));
  }

  Future<void> setBaseUrl(String? url) async {
    await updateSettings(state.copyWith(openaiBaseUrl: url));
  }

  Future<void> setModel(String model) async {
    await updateSettings(state.copyWith(openaiModel: model));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await updateSettings(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> setPomodoroWorkMinutes(int minutes) async {
    await updateSettings(state.copyWith(pomodoroWorkMinutes: minutes));
  }

  Future<void> setPomodoroBreakMinutes(int minutes) async {
    await updateSettings(state.copyWith(pomodoroBreakMinutes: minutes));
  }

  Future<void> setDarkMode(bool isDark) async {
    await updateSettings(state.copyWith(isDarkMode: isDark));
  }
}

final subjectsProvider =
    StateNotifierProvider<SubjectsNotifier, List<Subject>>((ref) {
  return SubjectsNotifier(ref.watch(databaseProvider));
});

class SubjectsNotifier extends StateNotifier<List<Subject>> {
  final AppDatabase _db;

  SubjectsNotifier(this._db) : super([]) {
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final data = await _db.select(_db.subjects).get();
    state = data
        .map((d) => Subject(
              id: d.id,
              name: d.name,
              color: d.color,
              icon: d.icon,
              createdAt: d.createdAt,
            ))
        .toList();
  }

  Future<void> addSubject(Subject subject) async {
    await _db.into(_db.subjects).insert(
          SubjectsCompanion.insert(
            id: subject.id,
            name: subject.name,
            color: Value(subject.color),
            icon: Value(subject.icon),
            createdAt: subject.createdAt,
          ),
        );
    state = [...state, subject];
  }

  Future<void> updateSubject(Subject subject) async {
    await (_db.update(_db.subjects)..where((t) => t.id.equals(subject.id)))
        .write(
      SubjectsCompanion(
        name: Value(subject.name),
        color: Value(subject.color),
        icon: Value(subject.icon),
      ),
    );
    state = state.map((s) => s.id == subject.id ? subject : s).toList();
  }

  Future<void> deleteSubject(String id) async {
    await (_db.delete(_db.subjects)..where((t) => t.id.equals(id))).go();
    state = state.where((s) => s.id != id).toList();
  }
}

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, List<StudySession>>((ref) {
  return SessionsNotifier(ref.watch(databaseProvider));
});

class SessionsNotifier extends StateNotifier<List<StudySession>> {
  final AppDatabase _db;

  SessionsNotifier(this._db) : super([]) {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final data = await _db.select(_db.sessions).get();
    state = data
        .map((d) => StudySession(
              id: d.id,
              subjectId: d.subjectId,
              subjectName: d.subjectName,
              startTime: d.startTime,
              endTime: d.endTime,
              durationSeconds: d.durationSeconds,
              mode: TimerMode.values[d.mode],
              planId: d.planId,
              createdAt: d.createdAt,
            ))
        .toList();
  }

  Future<void> addSession(StudySession session) async {
    await _db.into(_db.sessions).insert(
          SessionsCompanion.insert(
            id: session.id,
            subjectId: session.subjectId,
            subjectName: Value(session.subjectName),
            startTime: session.startTime,
            endTime: session.endTime,
            durationSeconds: session.durationSeconds,
            mode: session.mode.index,
            planId: Value(session.planId),
            createdAt: session.createdAt,
          ),
        );
    state = [...state, session];
  }

  Future<void> deleteSession(String id) async {
    await (_db.delete(_db.sessions)..where((t) => t.id.equals(id))).go();
    state = state.where((s) => s.id != id).toList();
  }

  List<StudySession> getSessionsForDate(DateTime date) {
    return state.where((s) {
      final sessionDate = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return sessionDate == DateTime(date.year, date.month, date.day);
    }).toList();
  }

  int getTotalMinutesForDate(DateTime date) {
    return getSessionsForDate(date).fold(0, (sum, s) => sum + s.durationMinutes);
  }

  Map<String, int> getSubjectDistributionForDate(DateTime date) {
    final sessions = getSessionsForDate(date);
    final Map<String, int> distribution = {};
    for (final session in sessions) {
      final name = session.subjectName ?? 'Unknown';
      distribution[name] = (distribution[name] ?? 0) + session.durationMinutes;
    }
    return distribution;
  }
}

final plansProvider = StateNotifierProvider<PlansNotifier, List<StudyPlan>>((ref) {
  return PlansNotifier(ref.watch(databaseProvider));
});

class PlansNotifier extends StateNotifier<List<StudyPlan>> {
  final AppDatabase _db;

  PlansNotifier(this._db) : super([]) {
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final data = await _db.select(_db.plans).get();
    state = data
        .map((d) => StudyPlan(
              id: d.id,
              title: d.title,
              description: d.description,
              subjectId: d.subjectId,
              subjectName: d.subjectName,
              targetMinutes: d.targetMinutes,
              deadline: d.deadline,
              priority: PlanPriority.values[d.priority],
              status: PlanStatus.values[d.status],
              subTasks: (jsonDecode(d.subTasks) as List)
                  .map((e) => SubTask.fromJson(e as Map<String, dynamic>))
                  .toList(),
              completedMinutes: d.completedMinutes,
              createdAt: d.createdAt,
              startedAt: d.startedAt,
              completedAt: d.completedAt,
            ))
        .toList();
  }

  Future<void> addPlan(StudyPlan plan) async {
    await _db.into(_db.plans).insert(
          PlansCompanion.insert(
            id: plan.id,
            title: plan.title,
            description: Value(plan.description),
            subjectId: plan.subjectId,
            subjectName: Value(plan.subjectName),
            targetMinutes: plan.targetMinutes,
            deadline: Value(plan.deadline),
            priority: plan.priority.index,
            status: plan.status.index,
            subTasks: jsonEncode(plan.subTasks.map((e) => e.toJson()).toList()),
            completedMinutes: plan.completedMinutes,
            createdAt: plan.createdAt,
            startedAt: Value(plan.startedAt),
            completedAt: Value(plan.completedAt),
          ),
        );
    state = [...state, plan];
  }

  Future<void> updatePlan(StudyPlan plan) async {
    await (_db.update(_db.plans)..where((t) => t.id.equals(plan.id)))
        .write(
      PlansCompanion(
        title: Value(plan.title),
        description: Value(plan.description),
        targetMinutes: Value(plan.targetMinutes),
        deadline: Value(plan.deadline),
        priority: Value(plan.priority.index),
        status: Value(plan.status.index),
        subTasks: Value(jsonEncode(plan.subTasks.map((e) => e.toJson()).toList())),
        completedMinutes: Value(plan.completedMinutes),
        startedAt: Value(plan.startedAt),
        completedAt: Value(plan.completedAt),
      ),
    );
    state = state.map((p) => p.id == plan.id ? plan : p).toList();
  }

  Future<void> deletePlan(String id) async {
    await (_db.delete(_db.plans)..where((t) => t.id.equals(id))).go();
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> addProgress(String planId, int minutes) async {
    final plan = state.firstWhere((p) => p.id == planId);
    final newMinutes = plan.completedMinutes + minutes;
    final newStatus = newMinutes >= plan.targetMinutes
        ? PlanStatus.completed
        : plan.status == PlanStatus.pending
            ? PlanStatus.inProgress
            : plan.status;

    final updated = plan.copyWith(
      completedMinutes: newMinutes,
      status: newStatus,
      startedAt: plan.startedAt ?? DateTime.now(),
      completedAt: newStatus == PlanStatus.completed ? DateTime.now() : null,
    );
    await updatePlan(updated);
  }
}
