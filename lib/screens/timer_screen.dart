import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:studyflow/providers/timer_provider.dart';
import 'package:studyflow/widgets/subject_selector.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;
  final String? initialSubjectName;

  const TimerScreen({
    super.key,
    this.initialSubjectId,
    this.initialSubjectName,
  });

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  TimerMode _selectedMode = TimerMode.pomodoro;
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String? _selectedPlanId;
  int _customMinutes = 30;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
    _selectedSubjectName = widget.initialSubjectName;
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习计时'),
        actions: [
          if (timerState.state != TimerState.idle)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => ref.read(timerProvider.notifier).stop(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildModeSelector(),
            const SizedBox(height: 24),
            _buildTimerDisplay(timerState),
            const SizedBox(height: 24),
            if (timerState.state == TimerState.idle) ...[
              _buildSubjectSelector(),
              const SizedBox(height: 16),
              if (_selectedMode == TimerMode.countdown) _buildDurationPicker(),
              const SizedBox(height: 24),
              _buildStartButton(settings),
            ] else
              _buildControlButtons(timerState),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return SegmentedButton<TimerMode>(
      segments: const [
        ButtonSegment(value: TimerMode.pomodoro, label: Text('番茄钟')),
        ButtonSegment(value: TimerMode.countdown, label: Text('倒计时')),
        ButtonSegment(value: TimerMode.stopwatch, label: Text('正计时')),
      ],
      selected: {_selectedMode},
      onSelectionChanged: (Set<TimerMode> selection) {
        setState(() => _selectedMode = selection.first);
      },
    );
  }

  Widget _buildTimerDisplay(TimerStateData state) {
    String timeText;
    double progressValue;
    TimerMode displayMode;

    // 确定使用哪个模式来显示：运行时用 state.mode，空闲时用用户选择的 _selectedMode
    if (state.state == TimerState.idle) {
      displayMode = _selectedMode;
    } else {
      displayMode = state.mode;
    }

    if (displayMode == TimerMode.stopwatch) {
      final hours = state.elapsedSeconds ~/ 3600;
      final minutes = (state.elapsedSeconds % 3600) ~/ 60;
      final seconds = state.elapsedSeconds % 60;
      if (hours > 0) {
        timeText = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      progressValue = 0.0; // 正计时不显示进度
    } else if (displayMode == TimerMode.pomodoro) {
      // 番茄钟空闲时显示设置的工作时间
      if (state.state == TimerState.idle) {
        final settings = ref.read(settingsProvider);
        final mins = settings.pomodoroWorkMinutes;
        timeText = '${mins.toString().padLeft(2, '0')}:00';
      } else {
        timeText = '${state.minutes.toString().padLeft(2, '0')}:${state.seconds.toString().padLeft(2, '0')}';
      }
      progressValue = state.progress;
    } else {
      // 倒计时
      if (state.state == TimerState.idle) {
        timeText = '${_customMinutes.toString().padLeft(2, '0')}:00';
      } else {
        timeText = '${state.minutes.toString().padLeft(2, '0')}:${state.seconds.toString().padLeft(2, '0')}';
      }
      progressValue = state.progress;
    }

    // 计算字体大小
    final fontSize = timeText.length > 5 ? 40.0 : 56.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (state.subjectName != null) ...[
              Chip(label: Text(state.subjectName!)),
              const SizedBox(height: 16),
            ],
            // 圆形计时器 - 使用固定大小的正方形容器
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 圆形进度条 - 正计时只显示空白背景环
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 8,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: state.isBreak
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  // 中心时间显示
                  Text(
                    timeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 状态显示
            if (state.isBreak)
              Text(
                '休息中',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green,
                ),
              ),
            if (displayMode == TimerMode.stopwatch && state.state == TimerState.running)
              Text(
                '计时中',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            if (state.state == TimerState.completed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('计时完成', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelector() {
    final subjects = ref.watch(subjectsProvider);
    final plans = ref.watch(plansProvider);
    final activePlans = plans.where((p) => p.status != PlanStatus.completed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择科目', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SubjectSelector(
          subjects: subjects,
          selectedSubjectId: _selectedSubjectId,
          onSubjectSelected: (subject) {
            setState(() {
              _selectedSubjectId = subject?.id;
              _selectedSubjectName = subject?.name;
            });
          },
        ),
        if (activePlans.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('关联计划（可选）', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPlanId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '选择计划',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('无')),
              ...activePlans.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.title),
                  )),
            ],
            onChanged: (value) {
              setState(() => _selectedPlanId = value);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('设置时长', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _customMinutes.toDouble(),
                min: 5,
                max: 180,
                divisions: 35,
                label: '$_customMinutes 分钟',
                onChanged: (value) {
                  setState(() => _customMinutes = value.round());
                },
              ),
            ),
            Text('$_customMinutes 分钟'),
          ],
        ),
      ],
    );
  }

  Widget _buildStartButton(AppSettings settings) {
    return FilledButton.icon(
      onPressed: _selectedSubjectId == null
          ? null
          : () {
              final notifier = ref.read(timerProvider.notifier);
              switch (_selectedMode) {
                case TimerMode.pomodoro:
                  notifier.startPomodoro(
                    workMinutes: settings.pomodoroWorkMinutes,
                    breakMinutes: settings.pomodoroBreakMinutes,
                    subjectId: _selectedSubjectId,
                    subjectName: _selectedSubjectName,
                    planId: _selectedPlanId,
                  );
                  break;
                case TimerMode.countdown:
                  notifier.startCountdown(
                    minutes: _customMinutes,
                    subjectId: _selectedSubjectId,
                    subjectName: _selectedSubjectName,
                    planId: _selectedPlanId,
                  );
                  break;
                case TimerMode.stopwatch:
                  notifier.startStopwatch(
                    subjectId: _selectedSubjectId,
                    subjectName: _selectedSubjectName,
                    planId: _selectedPlanId,
                  );
                  break;
              }
            },
      icon: const Icon(Icons.play_arrow),
      label: const Text('开始'),
    );
  }

  Widget _buildControlButtons(TimerStateData state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state.state == TimerState.running)
          FilledButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).pause(),
            icon: const Icon(Icons.pause),
            label: const Text('暂停'),
          )
        else if (state.state == TimerState.paused)
          FilledButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).resume(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('继续'),
          ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () => ref.read(timerProvider.notifier).stop(),
          icon: const Icon(Icons.stop),
          label: const Text('结束'),
        ),
      ],
    );
  }
}
