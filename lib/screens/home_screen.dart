import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:studyflow/screens/timer_screen.dart';
import 'package:studyflow/screens/plans_screen.dart';
import 'package:studyflow/screens/stats_screen.dart';
import 'package:studyflow/screens/ai_screen.dart';
import 'package:studyflow/screens/settings_screen.dart';
import 'package:studyflow/widgets/study_card.dart';
import 'package:studyflow/models/models.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeContent(),
      const TimerScreen(),
      const PlansScreen(),
      const StatsScreen(),
      const AIScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.timer), label: '计时'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: '计划'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '统计'),
          NavigationDestination(icon: Icon(Icons.smart_toy), label: 'AI'),
        ],
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    final subjects = ref.watch(subjectsProvider);

    final todayMinutes = ref.read(sessionsProvider.notifier).getTotalMinutesForDate(DateTime.now());
    final activePlans = plans.where((p) => p.status != PlanStatus.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StudyCard(
            title: '今日学习',
            value: '${todayMinutes ~/ 60}小时${todayMinutes % 60}分钟',
            icon: Icons.timer,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StudyCard(
                  title: '进行中计划',
                  value: '${activePlans.length}',
                  icon: Icons.assignment,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StudyCard(
                  title: '科目数量',
                  value: '${subjects.length}',
                  icon: Icons.book,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '快速开始',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (subjects.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('还没有科目，先添加一个吧'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showAddSubjectDialog(context, ref),
                      child: const Text('添加科目'),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjects.map((subject) {
                      return ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor: _parseColor(subject.color),
                          child: Text(
                            subject.name[0],
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        label: Text(subject.name),
                        onPressed: () => _quickStart(context, ref, subject),
                      );
                    }).toList(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showAddSubjectDialog(context, ref),
                  tooltip: '添加科目',
                ),
              ],
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '今日计划',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlansScreen()),
                ),
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activePlans.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('暂无进行中的计划'),
              ),
            )
          else
            ...activePlans.take(3).map((plan) => _PlanListItem(plan: plan)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickStartDialog(context, ref),
        icon: const Icon(Icons.play_arrow),
        label: const Text('开始学习'),
      ),
    );
  }

  Color _parseColor(String? color) {
    if (color == null) return Colors.blue;
    try {
      return Color(int.parse(color));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _quickStart(BuildContext context, WidgetRef ref, Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          initialSubjectId: subject.id,
          initialSubjectName: subject.name,
        ),
      ),
    );
  }

  void _showQuickStartDialog(BuildContext context, WidgetRef ref) {
    final subjects = ref.read(subjectsProvider);
    if (subjects.isEmpty) {
      _showAddSubjectDialog(context, ref);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择科目',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((subject) {
                  return ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor: _parseColor(subject.color),
                      child: Text(
                        subject.name[0],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    label: Text(subject.name),
                    onPressed: () {
                      Navigator.pop(context);
                      _quickStart(context, ref, subject);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加科目'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '科目名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  Colors.blue, Colors.red, Colors.green, Colors.orange,
                  Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
                ].map((color) {
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() => selectedColor = color);
                    },
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 16,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref.read(subjectsProvider.notifier).addSubject(
                        Subject(
                          name: controller.text,
                          color: selectedColor.value.toString(),
                        ),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanListItem extends ConsumerWidget {
  final StudyPlan plan;

  const _PlanListItem({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: plan.priority == PlanPriority.high
              ? Colors.red
              : plan.priority == PlanPriority.medium
                  ? Colors.orange
                  : Colors.green,
          child: Icon(
            plan.status == PlanStatus.completed
                ? Icons.check
                : Icons.assignment,
            color: Colors.white,
          ),
        ),
        title: Text(plan.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(value: plan.progress),
            const SizedBox(height: 4),
            Text(
              '${plan.completedMinutes}/${plan.targetMinutes} 分钟',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: plan.deadline != null
            ? Text(
                DateFormat('MM/dd').format(plan.deadline!),
                style: TextStyle(
                  color: plan.isOverdue ? Colors.red : null,
                ),
              )
            : null,
      ),
    );
  }
}
