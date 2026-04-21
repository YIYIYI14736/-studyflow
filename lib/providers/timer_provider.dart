import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/providers/providers.dart';

enum TimerState { idle, running, paused, completed }

class TimerStateData {
  final TimerState state;
  final TimerMode mode;
  final int remainingSeconds;
  final int elapsedSeconds;
  final int totalSeconds;
  final String? subjectId;
  final String? subjectName;
  final String? planId;
  final bool isBreak;

  TimerStateData({
    this.state = TimerState.idle,
    this.mode = TimerMode.pomodoro,
    this.remainingSeconds = 0,
    this.elapsedSeconds = 0,
    this.totalSeconds = 0,
    this.subjectId,
    this.subjectName,
    this.planId,
    this.isBreak = false,
  });

  int get minutes => remainingSeconds ~/ 60;
  int get seconds => remainingSeconds % 60;
  double get progress => totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0;

  TimerStateData copyWith({
    TimerState? state,
    TimerMode? mode,
    int? remainingSeconds,
    int? elapsedSeconds,
    int? totalSeconds,
    String? subjectId,
    String? subjectName,
    String? planId,
    bool? isBreak,
  }) {
    return TimerStateData(
      state: state ?? this.state,
      mode: mode ?? this.mode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      planId: planId ?? this.planId,
      isBreak: isBreak ?? this.isBreak,
    );
  }
}

final timerProvider =
    StateNotifierProvider<TimerNotifier, TimerStateData>((ref) {
  return TimerNotifier(ref);
});

class TimerNotifier extends StateNotifier<TimerStateData> {
  final Ref _ref;
  Timer? _timer;

  TimerNotifier(this._ref) : super(TimerStateData());

  void startPomodoro({
    required int workMinutes,
    required int breakMinutes,
    String? subjectId,
    String? subjectName,
    String? planId,
  }) {
    state = TimerStateData(
      state: TimerState.running,
      mode: TimerMode.pomodoro,
      remainingSeconds: workMinutes * 60,
      totalSeconds: workMinutes * 60,
      subjectId: subjectId,
      subjectName: subjectName,
      planId: planId,
      isBreak: false,
    );
    _startTimer();
  }

  void startCountdown({
    required int minutes,
    String? subjectId,
    String? subjectName,
    String? planId,
  }) {
    state = TimerStateData(
      state: TimerState.running,
      mode: TimerMode.countdown,
      remainingSeconds: minutes * 60,
      totalSeconds: minutes * 60,
      subjectId: subjectId,
      subjectName: subjectName,
      planId: planId,
    );
    _startTimer();
  }

  void startStopwatch({
    String? subjectId,
    String? subjectName,
    String? planId,
  }) {
    state = TimerStateData(
      state: TimerState.running,
      mode: TimerMode.stopwatch,
      elapsedSeconds: 0,
      subjectId: subjectId,
      subjectName: subjectName,
      planId: planId,
    );
    _startStopwatchTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _complete();
      }
    });
  }

  void _startStopwatchTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pause() {
    if (state.state == TimerState.running) {
      _timer?.cancel();
      state = state.copyWith(state: TimerState.paused);
    }
  }

  void resume() {
    if (state.state == TimerState.paused) {
      state = state.copyWith(state: TimerState.running);
      if (state.mode == TimerMode.stopwatch) {
        _startStopwatchTimer();
      } else {
        _startTimer();
      }
    }
  }

  void stop() {
    _timer?.cancel();
    if (state.state == TimerState.running || state.state == TimerState.paused) {
      _saveSession();
    }
    state = TimerStateData();
  }

  void _complete() {
    _timer?.cancel();
    _saveSession();
    state = state.copyWith(state: TimerState.completed);

    if (state.mode == TimerMode.pomodoro && !state.isBreak) {
      final settings = _ref.read(settingsProvider);
      final breakMinutes = settings.pomodoroBreakMinutes;
      state = state.copyWith(
        state: TimerState.running,
        remainingSeconds: breakMinutes * 60,
        totalSeconds: breakMinutes * 60,
        isBreak: true,
      );
      _startTimer();
    }
  }

  void _saveSession() {
    final duration = state.mode == TimerMode.stopwatch
        ? state.elapsedSeconds
        : state.totalSeconds - state.remainingSeconds;

    if (duration > 0 && state.subjectId != null) {
      final session = StudySession(
        subjectId: state.subjectId!,
        subjectName: state.subjectName,
        startTime: DateTime.now().subtract(Duration(seconds: duration)),
        endTime: DateTime.now(),
        durationSeconds: duration,
        mode: state.mode,
        planId: state.planId,
      );
      _ref.read(sessionsProvider.notifier).addSession(session);

      if (state.planId != null) {
        _ref.read(plansProvider.notifier).addProgress(state.planId!, duration ~/ 60);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
