import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:studyflow/providers/timer_provider.dart';
import 'package:studyflow/widgets/subject_selector.dart';
import 'package:studyflow/main.dart';

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

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin {
  TimerMode _selectedMode = TimerMode.pomodoro;
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String? _selectedPlanId;
  int _customMinutes = 30;

  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
    _selectedSubjectName = widget.initialSubjectName;

    _animController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _rotationAnimation =
        Tween<double>(begin: 0, end: 2 * pi).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final settings = ref.watch(settingsProvider);
    final isRunning = timerState.state != TimerState.idle;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isRunning
                ? [
                    timerState.isBreak
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.tertiaryContainer,
                    Theme.of(context).colorScheme.surface,
                  ]
                : [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          isRunning ? _getTimerTitle(timerState) : '学习计时',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (timerState.state != TimerState.idle)
                      IconButton(
                        icon: const Icon(Icons.stop_rounded,
                            color: Color(0xFFFF6B35)),
                        onPressed: () =>
                            ref.read(timerProvider.notifier).stop(),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      if (timerState.state == TimerState.idle) ...[
                        const SizedBox(height: 8),
                        _buildModeSelector(),
                      ],
                      const SizedBox(height: 28),
                      _buildTimerDisplay(timerState),
                      const SizedBox(height: 32),
                      if (timerState.state == TimerState.idle) ...[
                        _buildSubjectSelector(),
                        const SizedBox(height: 16),
                        if (_selectedMode == TimerMode.countdown)
                          _buildDurationPicker(),
                        const SizedBox(height: 28),
                        _buildStartButton(settings),
                      ] else ...[
                        _buildControlButtons(timerState),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimerTitle(TimerStateData state) {
    if (state.isBreak) return '休息时间';
    switch (state.mode) {
      case TimerMode.pomodoro:
        return '番茄钟';
      case TimerMode.countdown:
        return '倒计时';
      case TimerMode.stopwatch:
        return '正计时';
    }
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildModeChip(TimerMode.pomodoro, '番茄钟', Icons.timer_outlined),
          _buildModeChip(TimerMode.countdown, '倒计时', Icons.hourglass_empty),
          _buildModeChip(TimerMode.stopwatch, '正计时', Icons.play_circle_outline),
        ],
      ),
    );
  }

  Widget _buildModeChip(TimerMode mode, String label, IconData icon) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: AppColors.primaryGradient)
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(TimerStateData state) {
    String timeText;
    double progressValue;
    TimerMode displayMode;

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
        timeText =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        timeText =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      progressValue = 0.0;
    } else if (displayMode == TimerMode.pomodoro) {
      if (state.state == TimerState.idle) {
        final settings = ref.read(settingsProvider);
        final mins = settings.pomodoroWorkMinutes;
        timeText = '${mins.toString().padLeft(2, '0')}:00';
      } else {
        timeText =
            '${state.minutes.toString().padLeft(2, '0')}:${state.seconds.toString().padLeft(2, '0')}';
      }
      progressValue = state.progress;
    } else {
      if (state.state == TimerState.idle) {
        timeText = '${_customMinutes.toString().padLeft(2, '0')}:00';
      } else {
        timeText =
            '${state.minutes.toString().padLeft(2, '0')}:${state.seconds.toString().padLeft(2, '0')}';
      }
      progressValue = state.progress;
    }

    final fontSize = timeText.length > 5 ? 44.0 : 60.0;
    final isRunning = state.state == TimerState.running;
    final isBreak = state.isBreak;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.subjectName != null && state.state != TimerState.idle) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getRingColor(state).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _getRingColor(state).withValues(alpha: 0.2)),
            ),
            child: Text(
              state.subjectName!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getRingColor(state),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],

        // 主计时器圆环
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return ScaleTransition(
              scale: isRunning
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外圈光晕效果
                    if (isRunning)
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(260, 260),
                            painter: _GlowRingPainter(
                              progress: progressValue,
                              rotation: _rotationAnimation.value,
                              color: _getRingColor(state),
                              isBreak: isBreak,
                            ),
                          );
                        },
                      ),

                    // 主体圆环
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progressValue),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (ctx, value, child) {
                          return CustomPaint(
                            painter: _TimerRingPainter(
                              progress: value,
                              isBreak: isBreak,
                              strokeWidth: 10,
                              running: isRunning,
                              ringBgColor: isBreak
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.3)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              tickBgColor:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          );
                        },
                      ),
                    ),

                    // 中心内容
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: fontSize,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            letterSpacing: 2,
                            color: isBreak
                                ? const Color(0xFF66BB6A)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (isBreak) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF66BB6A)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.coffee,
                                    size: 14, color: Color(0xFF66BB6A)),
                                SizedBox(width: 4),
                                Text('休息中',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF66BB6A))),
                              ],
                            ),
                          ),
                        ],
                        if (displayMode == TimerMode.stopwatch &&
                            state.state == TimerState.running) ...[
                          const SizedBox(height: 4),
                          Text('计时中...',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        if (state.state == TimerState.completed) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: AppColors.successGradient
                      .map((c) => c.withValues(alpha: 0.1))
                      .toList()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF66BB6A), size: 20),
                SizedBox(width: 8),
                Text('计时完成',
                    style: TextStyle(
                        color: Color(0xFF66BB6A),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getRingColor(TimerStateData state) {
    if (state.isBreak) return const Color(0xFF66BB6A);
    return AppColors.primary;
  }

  Widget _buildSubjectSelector() {
    final subjects = ref.watch(subjectsProvider);
    final plans = ref.watch(plansProvider);
    final activePlans =
        plans.where((p) => p.status != PlanStatus.completed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择科目',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
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
          Text('关联计划（可选）',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedPlanId,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintText: '选择计划',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('无')),
                ...activePlans.map(
                    (p) => DropdownMenuItem(value: p.id, child: Text(p.title))),
              ],
              onChanged: (value) => setState(() => _selectedPlanId = value),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDurationPicker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('设置时长',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$_customMinutes 分钟',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 10, elevation: 4),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: _customMinutes.toDouble(),
              min: 5,
              max: 180,
              onChanged: (value) =>
                  setState(() => _customMinutes = value.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5分钟',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text('180分钟',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(AppSettings settings) {
    final canStart = _selectedSubjectId != null;
    return GestureDetector(
      onTap: canStart
          ? () {
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
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: canStart
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: canStart
              ? null
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: canStart
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded,
                color: canStart ? Colors.white : const Color(0xFFB09988),
                size: 24),
            const SizedBox(width: 8),
            Text(
              '开始',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: canStart ? Colors.white : const Color(0xFFB09988),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(TimerStateData state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 暂停/继续按钮
        GestureDetector(
          onTap: () {
            if (state.state == TimerState.running) {
              ref.read(timerProvider.notifier).pause();
            } else if (state.state == TimerState.paused) {
              ref.read(timerProvider.notifier).resume();
            }
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Icon(
              state.state == TimerState.running
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 28),
        // 结束按钮
        GestureDetector(
          onTap: () => ref.read(timerProvider.notifier).stop(),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: const Icon(Icons.stop_rounded,
                color: Color(0xFFFF6B35), size: 28),
          ),
        ),
      ],
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final bool isBreak;
  final double strokeWidth;
  final bool running;
  final Color ringBgColor;
  final Color tickBgColor;

  _TimerRingPainter({
    required this.progress,
    required this.isBreak,
    required this.strokeWidth,
    this.running = false,
    required this.ringBgColor,
    required this.tickBgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // 背景环 - 带轻微渐变效果
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    bgPaint.color = ringBgColor;
    canvas.drawCircle(center, radius, bgPaint);

    // 刻度线
    if (progress > 0) {
      final tickCount = 60;
      final tickPaint = Paint()
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < tickCount; i++) {
        final angle = -pi / 2 + (2 * pi * i / tickCount);
        final isHighlighted = i / tickCount <= progress;
        final isMajor = i % 5 == 0;

        final innerR = radius - (isMajor ? 12 : 8);
        final outerR = radius + (isMajor ? 2 : 0);

        tickPaint.color = isHighlighted
            ? (isBreak ? const Color(0xFF66BB6A) : AppColors.primary)
            : tickBgColor;

        canvas.drawLine(
          Offset(
              center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
          Offset(
              center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
          tickPaint,
        );
      }
    }

    // 进度弧
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -pi / 2;
      final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (isBreak) {
        paint.shader = const SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + 2 * pi,
          colors: [Color(0xFF66BB6A), Color(0xFF81C784), Color(0xFF66BB6A)],
        ).createShader(rect);
      } else {
        paint.shader = const SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + 2 * pi,
          colors: [
            Color(0xFFFF6B35),
            Color(0xFFFF8F65),
            Color(0xFFFFAB91),
            Color(0xFFFF6B35)
          ],
        ).createShader(rect);
      }

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    // 进度端点 - 小圆点
    if (progress > 0.005 && progress < 1.0) {
      final angle = -pi / 2 + 2 * pi * progress;
      final dotCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final dotPaint = Paint()
        ..color = isBreak ? const Color(0xFF66BB6A) : AppColors.primary
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dotCenter, 8, dotPaint);
      canvas.drawCircle(dotCenter, 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress || old.isBreak != isBreak;
}

class _GlowRingPainter extends CustomPainter {
  final double progress;
  final double rotation;
  final Color color;
  final bool isBreak;

  _GlowRingPainter({
    required this.progress,
    required this.rotation,
    required this.color,
    required this.isBreak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 旋转光晕效果
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..strokeCap = StrokeCap.round;

    if (progress > 0) {
      final startAngle = rotation;
      final sweepAngle = min(2 * pi * progress, pi / 2);

      glowPaint.color = color.withValues(alpha: 0.5);
      canvas.drawArc(rect, startAngle, sweepAngle * 2, false, glowPaint);

      // 反向旋转的小光弧
      glowPaint.color = color.withValues(alpha: 0.3);
      canvas.drawArc(rect, startAngle + pi, sweepAngle, false, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter old) =>
      old.rotation != rotation || old.progress != progress;
}
