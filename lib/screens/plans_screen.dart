import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:studyflow/main.dart';

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showCalendar
                ? Icons.list_rounded
                : Icons.calendar_month_rounded),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
        ],
      ),
      body: _showCalendar
          ? _buildCalendarView(plans)
          : _buildListView(plans, subjects),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: AppColors.primaryGradient),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddPlanDialog(context, subjects),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCalendarView(List<StudyPlan> plans) {
    return Column(
      children: [
        _buildDatePicker(),
        Expanded(child: _buildDayPlans(plans)),
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
            onPressed: () => setState(() => _selectedDate =
                _selectedDate.subtract(const Duration(days: 1))),
          ),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Text(
              DateFormat('yyyy年MM月dd日').format(_selectedDate),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() =>
                _selectedDate = _selectedDate.add(const Duration(days: 1))),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
            const SizedBox(height: 12),
            Text('当天没有计划',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayPlans.length,
      itemBuilder: (context, index) => _PlanCard(plan: dayPlans[index]),
    );
  }

  Widget _buildListView(List<StudyPlan> plans, List<Subject> subjects) {
    final activePlans =
        plans.where((p) => p.status != PlanStatus.completed).toList();
    final completedPlans =
        plans.where((p) => p.status == PlanStatus.completed).toList();

    if (plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
            const SizedBox(height: 16),
            Text('还没有学习计划',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text('点击右下角 + 创建第一个任务',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activePlans.isNotEmpty) ...[
          const _SectionTitle('进行中'),
          const SizedBox(height: 10),
          ...activePlans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanCard(plan: p),
              )),
          const SizedBox(height: 12),
        ],
        if (completedPlans.isNotEmpty) ...[
          const _SectionTitle('已完成'),
          const SizedBox(height: 10),
          ...completedPlans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanCard(plan: p),
              )),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  添加计划对话框
  // ──────────────────────────────────────────────
  void _showAddPlanDialog(BuildContext context, List<Subject> subjects) {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加科目')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedSubjectId = subjects.first.id;
    DateTime? deadline;
    PlanPriority priority = PlanPriority.medium;
    final List<_SubTaskDraft> subTaskDrafts = [];
    final subTaskCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽条
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2)),
                ),
                // 标题栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                  child: Row(
                    children: [
                      Text('创建学习任务',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const Spacer(),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('取消',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant))),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty) {
                            return;
                          }
                          final subject = subjects
                              .firstWhere((s) => s.id == selectedSubjectId);
                          final subTasks = subTaskDrafts
                              .where((d) => d.title.trim().isNotEmpty)
                              .map((d) => SubTask(
                                  title: d.title.trim(),
                                  estimatedMinutes:
                                      d.minutes > 0 ? d.minutes : null))
                              .toList();
                          ref.read(plansProvider.notifier).addPlan(StudyPlan(
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                                subjectId: selectedSubjectId,
                                subjectName: subject.name,
                                targetMinutes: subTasks.fold<int>(0,
                                    (s, t) => s + (t.estimatedMinutes ?? 30)),
                                deadline: deadline,
                                priority: priority,
                                subTasks: subTasks,
                              ));
                          Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                        ),
                        child: const Text('创建'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 内容
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 任务标题
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            labelText: '任务名称',
                            hintText: '例：复习线性代数第三章',
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 描述
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: '任务描述（可选）',
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 科目选择
                        const _FieldLabel('所属科目'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: subjects.map((s) {
                            final selected = s.id == selectedSubjectId;
                            return GestureDetector(
                              onTap: () =>
                                  setSheet(() => selectedSubjectId = s.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                  border: selected
                                      ? Border.all(
                                          color: AppColors.primary, width: 1.5)
                                      : null,
                                ),
                                child: Text(s.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // 优先级
                        const _FieldLabel('优先级'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _PriorityChip(
                                label: '低',
                                value: PlanPriority.low,
                                color: const Color(0xFF00B894),
                                selected: priority,
                                onTap: (v) => setSheet(() => priority = v)),
                            const SizedBox(width: 8),
                            _PriorityChip(
                                label: '中',
                                value: PlanPriority.medium,
                                color: const Color(0xFFFF9F43),
                                selected: priority,
                                onTap: (v) => setSheet(() => priority = v)),
                            const SizedBox(width: 8),
                            _PriorityChip(
                                label: '高',
                                value: PlanPriority.high,
                                color: const Color(0xFFFF6B6B),
                                selected: priority,
                                onTap: (v) => setSheet(() => priority = v)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 截止日期
                        Row(
                          children: [
                            const _FieldLabel('截止日期'),
                            const Spacer(),
                            GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: ctx,
                                  initialDate: deadline ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setSheet(() => deadline = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    Text(
                                        deadline != null
                                            ? DateFormat('yyyy/MM/dd')
                                                .format(deadline!)
                                            : '选择日期',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // 子任务列表
                        const _FieldLabel('子任务'),
                        const SizedBox(height: 8),
                        // 已有子任务
                        ...subTaskDrafts.asMap().entries.map((entry) {
                          final i = entry.key;
                          final d = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle_outlined,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(d.title,
                                        style: const TextStyle(fontSize: 14))),
                                if (d.minutes > 0)
                                  Text('~${d.minutes}min',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () =>
                                      setSheet(() => subTaskDrafts.removeAt(i)),
                                  child: Icon(Icons.close,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                ),
                              ],
                            ),
                          );
                        }),
                        // 添加子任务输入
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: subTaskCtrl,
                                decoration: InputDecoration(
                                  hintText: '输入子任务，如：做完习题1-10',
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  isDense: true,
                                ),
                                onSubmitted: (v) {
                                  if (v.trim().isNotEmpty) {
                                    setSheet(() {
                                      subTaskDrafts
                                          .add(_SubTaskDraft(title: v.trim()));
                                      subTaskCtrl.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                if (subTaskCtrl.text.trim().isNotEmpty) {
                                  setSheet(() {
                                    subTaskDrafts.add(_SubTaskDraft(
                                        title: subTaskCtrl.text.trim()));
                                    subTaskCtrl.clear();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: AppColors.primaryGradient),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(ctx).padding.bottom + 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 子任务草稿 ──
class _SubTaskDraft {
  String title;
  int minutes;
  _SubTaskDraft({required this.title}) : minutes = 0;
}

// ── 小标签 ──
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface));
}

// ── 优先级选择器 ──
class _PriorityChip extends StatelessWidget {
  final String label;
  final PlanPriority value;
  final Color color;
  final PlanPriority selected;
  final ValueChanged<PlanPriority> onTap;
  const _PriorityChip(
      {required this.label,
      required this.value,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : const Color(0xFF8E8E93))),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface));
}

// ============================================================
//  计划卡片
// ============================================================
class _PlanCard extends ConsumerStatefulWidget {
  final StudyPlan plan;
  const _PlanCard({required this.plan});
  @override
  ConsumerState<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<_PlanCard> {
  bool _expanded = false;

  Color get _priorityColor {
    switch (widget.plan.priority) {
      case PlanPriority.high:
        return const Color(0xFFFF6B6B);
      case PlanPriority.medium:
        return const Color(0xFFFF9F43);
      case PlanPriority.low:
        return const Color(0xFF00B894);
    }
  }

  String get _priorityLabel {
    switch (widget.plan.priority) {
      case PlanPriority.high:
        return '高';
      case PlanPriority.medium:
        return '中';
      case PlanPriority.low:
        return '低';
    }
  }

  int get _completedCount =>
      widget.plan.subTasks.where((t) => t.isCompleted).length;
  int get _totalCount => widget.plan.subTasks.length;
  bool get _hasSubTasks => _totalCount > 0;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isDone = plan.status == PlanStatus.completed;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _priorityColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  // 完成状态图标
                  GestureDetector(
                    onTap: isDone
                        ? null
                        : () {
                            ref.read(plansProvider.notifier).addProgress(
                                plan.id,
                                plan.targetMinutes - plan.completedMinutes);
                          },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFF00B894) : Colors.white,
                        border: Border.all(
                            color: isDone
                                ? const Color(0xFF00B894)
                                : const Color(0xFFE5E5EA),
                            width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: isDone
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 标题和科目
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? const Color(0xFFC7C7CC)
                                : Theme.of(context).colorScheme.onSurface,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (plan.subjectName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _priorityColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(plan.subjectName!,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _priorityColor)),
                              ),
                            if (plan.subjectName != null)
                              const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _priorityColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_priorityLabel,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _priorityColor)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 截止日期
                  if (plan.deadline != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(DateFormat('MM/dd').format(plan.deadline!),
                            style: TextStyle(
                                fontSize: 12,
                                color: plan.isOverdue
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFF8E8E93),
                                fontWeight: FontWeight.w500)),
                        if (plan.isOverdue && !isDone)
                          const Text('已过期',
                              style: TextStyle(
                                  color: Color(0xFFFF6B6B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFFC7C7CC)),
                ],
              ),
            ),
          ),
          // 子任务进度条
          if (_hasSubTasks) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value:
                          _totalCount > 0 ? _completedCount / _totalCount : 0,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: AppColors.primary,
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$_completedCount / $_totalCount 项任务',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8E8E93))),
                ],
              ),
            ),
          ],
          // 展开内容
          if (_expanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan.description != null) ...[
                    Text(plan.description!,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8E8E93))),
                    const SizedBox(height: 12),
                  ],
                  if (_hasSubTasks) ...[
                    ...plan.subTasks.asMap().entries.map((entry) {
                      final i = entry.key;
                      final t = entry.value;
                      return GestureDetector(
                        onTap: isDone
                            ? null
                            : () {
                                final updated =
                                    List<SubTask>.from(plan.subTasks);
                                updated[i] =
                                    t.copyWith(isCompleted: !t.isCompleted);
                                final completedCount =
                                    updated.where((e) => e.isCompleted).length;
                                final newStatus =
                                    completedCount == updated.length
                                        ? PlanStatus.completed
                                        : completedCount > 0
                                            ? PlanStatus.inProgress
                                            : PlanStatus.pending;
                                ref
                                    .read(plansProvider.notifier)
                                    .updatePlan(plan.copyWith(
                                      subTasks: updated,
                                      status: newStatus,
                                      completedAt:
                                          newStatus == PlanStatus.completed
                                              ? DateTime.now()
                                              : plan.completedAt,
                                    ));
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                t.isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 20,
                                color: t.isCompleted
                                    ? const Color(0xFF00B894)
                                    : const Color(0xFFC7C7CC),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  t.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: t.isCompleted
                                        ? const Color(0xFFC7C7CC)
                                        : Theme.of(context).colorScheme.onSurface,
                                    decoration: t.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              if (t.estimatedMinutes != null)
                                Text('~${t.estimatedMinutes}min',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFC7C7CC))),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                  // 底部操作
                  Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          ref.read(plansProvider.notifier).deletePlan(plan.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 14, color: Color(0xFFFF6B6B)),
                              SizedBox(width: 4),
                              Text('删除',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFFF6B6B),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

