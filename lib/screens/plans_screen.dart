import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:intl/intl.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider);
    final subjects = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习计划'),
        actions: [
          IconButton(
            icon: Icon(_showCalendar ? Icons.list : Icons.calendar_month),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
        ],
      ),
      body: _showCalendar
          ? _buildCalendarView(plans)
          : _buildListView(plans, subjects),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlanDialog(context, subjects),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarView(List<StudyPlan> plans) {
    return Column(
      children: [
        _buildDatePicker(),
        Expanded(
          child: _buildDayPlans(plans),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
            },
          ),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: Text(
              DateFormat('yyyy年MM月dd日').format(_selectedDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayPlans(List<StudyPlan> plans) {
    final dayPlans = plans.where((p) {
      if (p.deadline == null) return false;
      return p.deadline!.year == _selectedDate.year &&
          p.deadline!.month == _selectedDate.month &&
          p.deadline!.day == _selectedDate.day;
    }).toList();

    if (dayPlans.isEmpty) {
      return const Center(child: Text('当天没有计划'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayPlans.length,
      itemBuilder: (context, index) => _PlanCard(plan: dayPlans[index]),
    );
  }

  Widget _buildListView(List<StudyPlan> plans, List<Subject> subjects) {
    final activePlans = plans.where((p) => p.status != PlanStatus.completed).toList();
    final completedPlans = plans.where((p) => p.status == PlanStatus.completed).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activePlans.isNotEmpty) ...[
          Text('进行中', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...activePlans.map((p) => _PlanCard(plan: p)),
          const SizedBox(height: 24),
        ],
        if (completedPlans.isNotEmpty) ...[
          Text('已完成', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...completedPlans.map((p) => _PlanCard(plan: p)),
        ],
        if (plans.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('还没有计划，点击右下角按钮添加'),
            ),
          ),
      ],
    );
  }

  void _showAddPlanDialog(BuildContext context, List<Subject> subjects) {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加科目')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedSubjectId = subjects.first.id;
    int targetMinutes = 60;
    DateTime? deadline;
    PlanPriority priority = PlanPriority.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加计划'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '计划标题',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: '描述（可选）',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: '科目',
                    border: OutlineInputBorder(),
                  ),
                  items: subjects
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedSubjectId = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('目标时长: '),
                    Expanded(
                      child: Slider(
                        value: targetMinutes.toDouble(),
                        min: 15,
                        max: 480,
                        divisions: 31,
                        label: '$targetMinutes 分钟',
                        onChanged: (value) {
                          setDialogState(() => targetMinutes = value.round());
                        },
                      ),
                    ),
                    Text('$targetMinutes 分钟'),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('截止日期'),
                  subtitle: Text(deadline != null
                      ? DateFormat('yyyy/MM/dd').format(deadline!)
                      : '未设置'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: deadline ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() => deadline = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<PlanPriority>(
                  segments: const [
                    ButtonSegment(value: PlanPriority.low, label: Text('低')),
                    ButtonSegment(value: PlanPriority.medium, label: Text('中')),
                    ButtonSegment(value: PlanPriority.high, label: Text('高')),
                  ],
                  selected: {priority},
                  onSelectionChanged: (Set<PlanPriority> selection) {
                    setDialogState(() => priority = selection.first);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty) return;
                final subject = subjects.firstWhere((s) => s.id == selectedSubjectId);
                ref.read(plansProvider.notifier).addPlan(
                      StudyPlan(
                        title: titleController.text,
                        description: descController.text.isEmpty ? null : descController.text,
                        subjectId: selectedSubjectId,
                        subjectName: subject.name,
                        targetMinutes: targetMinutes,
                        deadline: deadline,
                        priority: priority,
                      ),
                    );
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final StudyPlan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(plan.priority),
          child: Icon(
            plan.status == PlanStatus.completed ? Icons.check : Icons.assignment,
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
              '${plan.completedMinutes}/${plan.targetMinutes} 分钟 (${plan.progressPercent}%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: plan.deadline != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MM/dd').format(plan.deadline!),
                    style: TextStyle(
                      color: plan.isOverdue ? Colors.red : null,
                    ),
                  ),
                  if (plan.isOverdue)
                    const Text('已过期', style: TextStyle(color: Colors.red, fontSize: 10)),
                ],
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.description != null) ...[
                  Text(plan.description!),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    if (plan.subjectName != null)
                      Chip(label: Text(plan.subjectName!)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref.read(plansProvider.notifier).deletePlan(plan.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(PlanPriority priority) {
    switch (priority) {
      case PlanPriority.high:
        return Colors.red;
      case PlanPriority.medium:
        return Colors.orange;
      case PlanPriority.low:
        return Colors.green;
    }
  }
}
