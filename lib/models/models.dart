import 'package:uuid/uuid.dart';
import 'package:studyflow/config/api_keys.dart';

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
        mode: TimerMode.values[json['mode'] as int],
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

  bool get isOverdue =>
      deadline != null &&
      deadline!.isBefore(DateTime.now()) &&
      status != PlanStatus.completed;

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
        priority: PlanPriority.values[json['priority'] as int],
        status: PlanStatus.values[json['status'] as int],
        subTasks: (json['subTasks'] as List)
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

class AppSettings {
  final String? openaiApiKey;
  final String? openaiBaseUrl;
  final String openaiModel;
  final bool notificationsEnabled;
  final int pomodoroWorkMinutes;
  final int pomodoroBreakMinutes;
  final bool isDarkMode;
  final bool webSearchEnabled;
  final String? searchApiKey;
  final String searchProvider; // 'tavily', 'bing', 'custom'

  AppSettings({
    this.openaiApiKey = kBuiltInApiKey,
    this.openaiBaseUrl = kBuiltInBaseUrl,
    this.openaiModel = kBuiltInModel,
    this.notificationsEnabled = true,
    this.pomodoroWorkMinutes = 25,
    this.pomodoroBreakMinutes = 5,
    this.isDarkMode = false,
    this.webSearchEnabled = false,
    this.searchApiKey = kBuiltInSearchApiKey,
    this.searchProvider = kBuiltInSearchProvider,
  });

  AppSettings copyWith({
    String? openaiApiKey,
    String? openaiBaseUrl,
    String? openaiModel,
    bool? notificationsEnabled,
    int? pomodoroWorkMinutes,
    int? pomodoroBreakMinutes,
    bool? isDarkMode,
    bool? webSearchEnabled,
    String? searchApiKey,
    String? searchProvider,
  }) {
    return AppSettings(
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      openaiBaseUrl: openaiBaseUrl ?? this.openaiBaseUrl,
      openaiModel: openaiModel ?? this.openaiModel,
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
        'openaiApiKey': openaiApiKey,
        'openaiBaseUrl': openaiBaseUrl,
        'openaiModel': openaiModel,
        'notificationsEnabled': notificationsEnabled,
        'pomodoroWorkMinutes': pomodoroWorkMinutes,
        'pomodoroBreakMinutes': pomodoroBreakMinutes,
        'isDarkMode': isDarkMode,
        'webSearchEnabled': webSearchEnabled,
        'searchApiKey': searchApiKey,
        'searchProvider': searchProvider,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        openaiApiKey: json['openaiApiKey'] as String? ?? kBuiltInApiKey,
        openaiBaseUrl: json['openaiBaseUrl'] as String? ?? kBuiltInBaseUrl,
        openaiModel: json['openaiModel'] as String? ?? kBuiltInModel,
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
