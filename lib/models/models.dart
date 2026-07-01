import 'package:uuid/uuid.dart';
import 'package:studyflow/config/api_keys.dart';

T _safeEnumFromIndex<T>(List<T> values, int index, T fallback) {
  if (index >= 0 && index < values.length) return values[index];
  return fallback;
}

enum TimerMode { pomodoro, countdown, stopwatch }

enum PlanStatus { pending, inProgress, completed }

enum PlanPriority { low, medium, high }

class Subject {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final DateTime createdAt;

  Subject({
    String? id,
    required this.name,
    this.color,
    this.icon,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Subject copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as String?,
        icon: json['icon'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

// ============================================================
//  错题模型
// ============================================================

/// 错题状态
enum WQStatus { wrong, corrected, mastered }

/// 一道错题
class WrongQuestion {
  final String id;
  final String subjectId; // 科目ID（三级索引：课程）
  final int pageNumber; // 页码（三级索引：页码）
  final int questionNumber; // 题号（三级索引：题号）
  final String? note; // 备注
  final DateTime createdAt;

  WrongQuestion({
    String? id,
    required this.subjectId,
    required this.pageNumber,
    required this.questionNumber,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// 三级索引标识
  String get indexLabel => 'P$pageNumber-#$questionNumber';

  WrongQuestion copyWith({
    String? id,
    String? subjectId,
    int? pageNumber,
    int? questionNumber,
    String? note,
    DateTime? createdAt,
  }) =>
      WrongQuestion(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        pageNumber: pageNumber ?? this.pageNumber,
        questionNumber: questionNumber ?? this.questionNumber,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'pageNumber': pageNumber,
        'questionNumber': questionNumber,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WrongQuestion.fromJson(Map<String, dynamic> json) => WrongQuestion(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        pageNumber: json['pageNumber'] as int,
        questionNumber: json['questionNumber'] as int,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// 一轮复习记录
class WrongQuestionRound {
  final String id;
  final String questionId; // 关联的错题
  final int round; // 第几轮（1/2/3...）
  final WQStatus status; // 本轮状态
  final DateTime reviewedAt;
  final String? note;

  WrongQuestionRound({
    String? id,
    required this.questionId,
    required this.round,
    required this.status,
    DateTime? reviewedAt,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        reviewedAt = reviewedAt ?? DateTime.now();

  bool get isCorrect =>
      status == WQStatus.corrected || status == WQStatus.mastered;

  WrongQuestionRound copyWith({
    String? id,
    String? questionId,
    int? round,
    WQStatus? status,
    DateTime? reviewedAt,
    String? note,
  }) =>
      WrongQuestionRound(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        round: round ?? this.round,
        status: status ?? this.status,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionId': questionId,
        'round': round,
        'status': status.index,
        'reviewedAt': reviewedAt.toIso8601String(),
        'note': note,
      };

  factory WrongQuestionRound.fromJson(Map<String, dynamic> json) =>
      WrongQuestionRound(
        id: json['id'] as String,
        questionId: json['questionId'] as String,
        round: json['round'] as int,
        status: _safeEnumFromIndex(
            WQStatus.values, json['status'] as int, WQStatus.wrong),
        reviewedAt: DateTime.parse(json['reviewedAt'] as String),
        note: json['note'] as String?,
      );
}

class StudySession {
  final String id;
  final String subjectId;
  final String? subjectName;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final TimerMode mode;
  final String? planId;
  final DateTime createdAt;

  StudySession({
    String? id,
    required this.subjectId,
    this.subjectName,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.mode,
    this.planId,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  int get durationMinutes => durationSeconds ~/ 60;

  StudySession copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    TimerMode? mode,
    String? planId,
    DateTime? createdAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      mode: mode ?? this.mode,
      planId: planId ?? this.planId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationSeconds': durationSeconds,
        'mode': mode.index,
        'planId': planId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        subjectName: json['subjectName'] as String?,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        durationSeconds: json['durationSeconds'] as int,
        mode: _safeEnumFromIndex(
            TimerMode.values, json['mode'] as int, TimerMode.pomodoro),
        planId: json['planId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;
  final int? estimatedMinutes;

  SubTask({
    String? id,
    required this.title,
    this.isCompleted = false,
    this.estimatedMinutes,
  }) : id = id ?? const Uuid().v4();

  SubTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? estimatedMinutes,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'estimatedMinutes': estimatedMinutes,
      };

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool,
        estimatedMinutes: json['estimatedMinutes'] as int?,
      );
}

class StudyPlan {
  final String id;
  final String title;
  final String? description;
  final String subjectId;
  final String? subjectName;
  final int targetMinutes;
  final DateTime? deadline;
  final PlanPriority priority;
  final PlanStatus status;
  final List<SubTask> subTasks;
  final int completedMinutes;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  StudyPlan({
    String? id,
    required this.title,
    this.description,
    required this.subjectId,
    this.subjectName,
    required this.targetMinutes,
    this.deadline,
    this.priority = PlanPriority.medium,
    this.status = PlanStatus.pending,
    this.subTasks = const [],
    this.completedMinutes = 0,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (targetMinutes == 0) return 0;
    return (completedMinutes / targetMinutes).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();

  bool get isOverdue {
    if (deadline == null || status == PlanStatus.completed) return false;
    final endOfDeadlineDay =
        DateTime(deadline!.year, deadline!.month, deadline!.day, 23, 59, 59);
    return DateTime.now().isAfter(endOfDeadlineDay);
  }

  StudyPlan copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    String? subjectName,
    int? targetMinutes,
    DateTime? deadline,
    PlanPriority? priority,
    PlanStatus? status,
    List<SubTask>? subTasks,
    int? completedMinutes,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      subTasks: subTasks ?? this.subTasks,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'targetMinutes': targetMinutes,
        'deadline': deadline?.toIso8601String(),
        'priority': priority.index,
        'status': status.index,
        'subTasks': subTasks.map((e) => e.toJson()).toList(),
        'completedMinutes': completedMinutes,
        'createdAt': createdAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        subjectId: json['subjectId'] as String,
        subjectName: json['subjectName'] as String?,
        targetMinutes: json['targetMinutes'] as int,
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        priority: _safeEnumFromIndex(
            PlanPriority.values, json['priority'] as int, PlanPriority.medium),
        status: _safeEnumFromIndex(
            PlanStatus.values, json['status'] as int, PlanStatus.pending),
        subTasks: (json['subTasks'] as List? ?? [])
            .map((e) => SubTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        completedMinutes: json['completedMinutes'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}

const Object _unsetSettingValue = Object();

class AppSettings {
  final String? aiApiKey;
  final String? aiBaseUrl;
  final String aiModel;
  final bool notificationsEnabled;
  final int pomodoroWorkMinutes;
  final int pomodoroBreakMinutes;
  final bool isDarkMode;
  final bool webSearchEnabled;
  final String? searchApiKey;
  final String searchProvider; // 'tavily', 'bing', 'custom'

  AppSettings({
    this.aiApiKey = kBuiltInApiKey,
    this.aiBaseUrl = kBuiltInBaseUrl,
    this.aiModel = kBuiltInModel,
    this.notificationsEnabled = true,
    this.pomodoroWorkMinutes = 25,
    this.pomodoroBreakMinutes = 5,
    this.isDarkMode = false,
    this.webSearchEnabled = false,
    this.searchApiKey = kBuiltInSearchApiKey,
    this.searchProvider = kBuiltInSearchProvider,
  });

  AppSettings copyWith({
    Object? aiApiKey = _unsetSettingValue,
    Object? aiBaseUrl = _unsetSettingValue,
    String? aiModel,
    bool? notificationsEnabled,
    int? pomodoroWorkMinutes,
    int? pomodoroBreakMinutes,
    bool? isDarkMode,
    bool? webSearchEnabled,
    String? searchApiKey,
    String? searchProvider,
  }) {
    return AppSettings(
      aiApiKey: identical(aiApiKey, _unsetSettingValue)
          ? this.aiApiKey
          : aiApiKey as String?,
      aiBaseUrl: identical(aiBaseUrl, _unsetSettingValue)
          ? this.aiBaseUrl
          : aiBaseUrl as String?,
      aiModel: aiModel ?? this.aiModel,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pomodoroWorkMinutes: pomodoroWorkMinutes ?? this.pomodoroWorkMinutes,
      pomodoroBreakMinutes: pomodoroBreakMinutes ?? this.pomodoroBreakMinutes,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      webSearchEnabled: webSearchEnabled ?? this.webSearchEnabled,
      searchApiKey: searchApiKey ?? this.searchApiKey,
      searchProvider: searchProvider ?? this.searchProvider,
    );
  }

  Map<String, dynamic> toJson() => {
        'aiApiKey': aiApiKey,
        'aiBaseUrl': aiBaseUrl,
        'aiModel': aiModel,
        'notificationsEnabled': notificationsEnabled,
        'pomodoroWorkMinutes': pomodoroWorkMinutes,
        'pomodoroBreakMinutes': pomodoroBreakMinutes,
        'isDarkMode': isDarkMode,
        'webSearchEnabled': webSearchEnabled,
        'searchApiKey': searchApiKey,
        'searchProvider': searchProvider,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        aiApiKey: json['aiApiKey'] as String? ??
            json['openaiApiKey'] as String? ??
            kBuiltInApiKey,
        aiBaseUrl: json['aiBaseUrl'] as String? ??
            json['openaiBaseUrl'] as String? ??
            kBuiltInBaseUrl,
        aiModel: json['aiModel'] as String? ??
            json['openaiModel'] as String? ??
            kBuiltInModel,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        pomodoroWorkMinutes: json['pomodoroWorkMinutes'] as int? ?? 25,
        pomodoroBreakMinutes: json['pomodoroBreakMinutes'] as int? ?? 5,
        isDarkMode: json['isDarkMode'] as bool? ?? false,
        webSearchEnabled: json['webSearchEnabled'] as bool? ?? false,
        searchApiKey: json['searchApiKey'] as String? ?? kBuiltInSearchApiKey,
        searchProvider:
            json['searchProvider'] as String? ?? kBuiltInSearchProvider,
      );
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final List<AIPlanSuggestion>? planSuggestions; // AI 生成的计划建议

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    DateTime? createdAt,
    this.planSuggestions,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'createdAt': createdAt.toIso8601String(),
        'planSuggestions': planSuggestions?.map((p) => p.toJson()).toList(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        content: json['content'] as String,
        isUser: json['isUser'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        planSuggestions: json['planSuggestions'] != null
            ? (json['planSuggestions'] as List)
                .map(
                    (e) => AIPlanSuggestion.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
      );
}

// AI 生成的计划建议
class AIPlanSuggestion {
  final String title;
  final String? description;
  final String subjectName;
  final int targetMinutes;
  final DateTime? deadline;
  final String priority; // 'low', 'medium', 'high'

  AIPlanSuggestion({
    required this.title,
    this.description,
    required this.subjectName,
    required this.targetMinutes,
    this.deadline,
    this.priority = 'medium',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'subjectName': subjectName,
        'targetMinutes': targetMinutes,
        'deadline': deadline?.toIso8601String(),
        'priority': priority,
      };

  factory AIPlanSuggestion.fromJson(Map<String, dynamic> json) =>
      AIPlanSuggestion(
        title: json['title'] as String,
        description: json['description'] as String?,
        subjectName: json['subjectName'] as String,
        targetMinutes: json['targetMinutes'] as int,
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        priority: json['priority'] as String? ?? 'medium',
      );
}
