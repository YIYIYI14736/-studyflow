import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/database/database.dart';
import 'package:drift/drift.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

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
    await updateSettings(state.copyWith(aiApiKey: key));
  }

  Future<void> setBaseUrl(String? url) async {
    await updateSettings(state.copyWith(aiBaseUrl: url));
  }

  Future<void> setModel(String model) async {
    await updateSettings(state.copyWith(aiModel: model));
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

  Future<void> setWebSearchEnabled(bool enabled) async {
    await updateSettings(state.copyWith(webSearchEnabled: enabled));
  }

  Future<void> setSearchApiKey(String? key) async {
    await updateSettings(state.copyWith(searchApiKey: key));
  }

  Future<void> setSearchProvider(String provider) async {
    await updateSettings(state.copyWith(searchProvider: provider));
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
    // 级联删除关联的 sessions 和 plans
    await (_db.delete(_db.sessions)..where((t) => t.subjectId.equals(id))).go();
    await (_db.delete(_db.plans)..where((t) => t.subjectId.equals(id))).go();
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
      final sessionDate =
          DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return sessionDate == DateTime(date.year, date.month, date.day);
    }).toList();
  }

  int getTotalMinutesForDate(DateTime date) {
    return getSessionsForDate(date)
        .fold(0, (sum, s) => sum + s.durationMinutes);
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

final plansProvider =
    StateNotifierProvider<PlansNotifier, List<StudyPlan>>((ref) {
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
    await (_db.update(_db.plans)..where((t) => t.id.equals(plan.id))).write(
      PlansCompanion(
        title: Value(plan.title),
        description: Value(plan.description),
        subjectId: Value(plan.subjectId),
        subjectName: Value(plan.subjectName),
        targetMinutes: Value(plan.targetMinutes),
        deadline: Value(plan.deadline),
        priority: Value(plan.priority.index),
        status: Value(plan.status.index),
        subTasks:
            Value(jsonEncode(plan.subTasks.map((e) => e.toJson()).toList())),
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
    if (minutes <= 0) return;
    final plans = state.where((p) => p.id == planId);
    if (plans.isEmpty) return; // 计划已被删除，静默忽略
    final plan = plans.first;
    final newMinutes = plan.completedMinutes + minutes;
    final newStatus = newMinutes >= plan.targetMinutes
        ? PlanStatus.completed
        : plan.status == PlanStatus.pending
            ? PlanStatus.inProgress
            : plan.status;

    // 直接构建新对象而非 copyWith，避免 nullable 字段无法清除的问题
    final updated = StudyPlan(
      id: plan.id,
      title: plan.title,
      description: plan.description,
      subjectId: plan.subjectId,
      subjectName: plan.subjectName,
      targetMinutes: plan.targetMinutes,
      deadline: plan.deadline,
      priority: plan.priority,
      status: newStatus,
      subTasks: plan.subTasks,
      completedMinutes: newMinutes,
      createdAt: plan.createdAt,
      startedAt: plan.startedAt ?? DateTime.now(),
      completedAt: newStatus == PlanStatus.completed && plan.completedAt == null
          ? DateTime.now()
          : plan.completedAt,
    );
    await updatePlan(updated);
  }
}

// ============================================================
//  错题 Provider
// ============================================================

/// 错题列表 + round 记录的联合状态
class WQState {
  final List<WrongQuestion> questions;
  final List<WrongQuestionRound> rounds;

  WQState({this.questions = const [], this.rounds = const []});

  WQState copyWith({
    List<WrongQuestion>? questions,
    List<WrongQuestionRound>? rounds,
  }) =>
      WQState(
        questions: questions ?? this.questions,
        rounds: rounds ?? this.rounds,
      );
}

final wrongQuestionProvider = StateNotifierProvider<WQNotifier, WQState>((ref) {
  return WQNotifier(ref.watch(databaseProvider));
});

class WQNotifier extends StateNotifier<WQState> {
  final AppDatabase _db;

  WQNotifier(this._db) : super(WQState()) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    final qData = await _db.select(_db.wrongQuestions).get();
    final rData = await _db.select(_db.wrongQuestionRounds).get();

    state = WQState(
      questions: qData
          .map((d) => WrongQuestion(
                id: d.id,
                subjectId: d.subjectId,
                pageNumber: d.pageNumber,
                questionNumber: d.questionNumber,
                note: d.note,
                createdAt: d.createdAt,
              ))
          .toList(),
      rounds: rData
          .map((d) => WrongQuestionRound(
                id: d.id,
                questionId: d.questionId,
                round: d.round,
                status: WQStatus.values[d.status],
                reviewedAt: d.reviewedAt,
                note: d.note,
              ))
          .toList(),
    );
  }

  // --- 获取某道错题的所有轮次记录 ---
  List<WrongQuestionRound> roundsFor(String questionId) {
    return state.rounds.where((r) => r.questionId == questionId).toList()
      ..sort((a, b) => a.round.compareTo(b.round));
  }

  // --- 获取某道错题的最新轮次 ---
  int latestRound(String questionId) {
    final rounds = roundsFor(questionId);
    return rounds.isEmpty ? 0 : rounds.last.round;
  }

  // --- 获取某道错题当前状态 ---
  WQStatus currentStatus(String questionId) {
    final rounds = roundsFor(questionId);
    if (rounds.isEmpty) return WQStatus.wrong;
    return rounds.last.status;
  }

  // --- 添加错题 ---
  Future<void> addQuestion(WrongQuestion q) async {
    // 自动创建第一轮记录（状态：wrong）
    final r1 = WrongQuestionRound(
      questionId: q.id,
      round: 1,
      status: WQStatus.wrong,
    );
    await _db.transaction(() async {
      await _db.into(_db.wrongQuestions).insert(
            WrongQuestionsCompanion.insert(
              id: q.id,
              subjectId: q.subjectId,
              pageNumber: q.pageNumber,
              questionNumber: q.questionNumber,
              note: Value(q.note),
              createdAt: q.createdAt,
            ),
          );
      await _db.into(_db.wrongQuestionRounds).insert(
            WrongQuestionRoundsCompanion.insert(
              id: r1.id,
              questionId: r1.questionId,
              round: r1.round,
              status: r1.status.index,
              reviewedAt: r1.reviewedAt,
              note: Value(r1.note),
            ),
          );
    });
    state = state.copyWith(
      questions: [...state.questions, q],
      rounds: [...state.rounds, r1],
    );
  }

  // --- 添加新轮次复习记录 ---
  Future<void> addRound(WrongQuestionRound round) async {
    await _db.into(_db.wrongQuestionRounds).insert(
          WrongQuestionRoundsCompanion.insert(
            id: round.id,
            questionId: round.questionId,
            round: round.round,
            status: round.status.index,
            reviewedAt: round.reviewedAt,
            note: Value(round.note),
          ),
        );
    state = state.copyWith(rounds: [...state.rounds, round]);
  }

  // --- 删除错题 ---
  Future<void> deleteQuestion(String id) async {
    await (_db.delete(_db.wrongQuestions)..where((t) => t.id.equals(id))).go();
    await (_db.delete(_db.wrongQuestionRounds)
          ..where((t) => t.questionId.equals(id)))
        .go();
    state = state.copyWith(
      questions: state.questions.where((q) => q.id != id).toList(),
      rounds: state.rounds.where((r) => r.questionId != id).toList(),
    );
  }

  // --- 更新错题 ---
  Future<void> updateQuestion(WrongQuestion q) async {
    await (_db.update(_db.wrongQuestions)..where((t) => t.id.equals(q.id)))
        .write(
      WrongQuestionsCompanion(
        subjectId: Value(q.subjectId),
        pageNumber: Value(q.pageNumber),
        questionNumber: Value(q.questionNumber),
        note: Value(q.note),
      ),
    );
    state = state.copyWith(
      questions:
          state.questions.map((old) => old.id == q.id ? q : old).toList(),
    );
  }

  // --- 统计：按科目分组的错题数 ---
  Map<String, int> countBySubject(Map<String, String> subjectNames) {
    final map = <String, int>{};
    for (final q in state.questions) {
      final name = subjectNames[q.subjectId] ?? '未知科目';
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  // --- 统计：各轮次题目数 ---
  Map<int, int> countByRound() {
    final map = <int, int>{};
    for (final q in state.questions) {
      final r = latestRound(q.id);
      map[r] = (map[r] ?? 0) + 1;
    }
    return map;
  }

  // --- 统计：各状态题目数 ---
  Map<WQStatus, int> countByStatus() {
    final map = <WQStatus, int>{
      WQStatus.wrong: 0,
      WQStatus.corrected: 0,
      WQStatus.mastered: 0,
    };
    for (final q in state.questions) {
      final s = currentStatus(q.id);
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  // --- 统计：掌握率 ---
  double get masteryRate {
    if (state.questions.isEmpty) return 0;
    final mastered = state.questions
        .where((q) => currentStatus(q.id) == WQStatus.mastered)
        .length;
    return mastered / state.questions.length;
  }

  // --- 统计：各轮次通过率 ---
  Map<int, double> passRateByRound() {
    final roundTotal = <int, int>{};
    final roundPass = <int, int>{};
    for (final r in state.rounds) {
      roundTotal[r.round] = (roundTotal[r.round] ?? 0) + 1;
      if (r.isCorrect) {
        roundPass[r.round] = (roundPass[r.round] ?? 0) + 1;
      }
    }
    final result = <int, double>{};
    for (final e in roundTotal.entries) {
      result[e.key] = (roundPass[e.key] ?? 0) / e.value;
    }
    return result;
  }
}
