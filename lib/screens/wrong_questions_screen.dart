import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:studyflow/main.dart';

// ============================================================
//  错题本主页面
// ============================================================
class WrongQuestionsScreen extends ConsumerStatefulWidget {
  const WrongQuestionsScreen({super.key});
  @override
  ConsumerState<WrongQuestionsScreen> createState() =>
      _WrongQuestionsScreenState();
}

class _WrongQuestionsScreenState extends ConsumerState<WrongQuestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题本'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2,
           labelColor: Theme.of(context).colorScheme.onSurface,
           unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          labelStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '错题列表'),
            Tab(text: '统计总览'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _QuestionListTab(),
          _StatsOverviewTab(),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: AppColors.accentGradient),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddDialog(context, ref),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final subjects = ref.read(subjectsProvider);
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加科目')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final maxPage = 500;
    final maxQuestion = 100;
    const itemExtent = 40.0;

    // —— 恢复上次的页码 / 题号 ——
    int pageNum = prefs.getInt('wq_last_page') ?? 1;
    int qNum = prefs.getInt('wq_last_question') ?? 1;
    pageNum = pageNum.clamp(1, maxPage);
    qNum = qNum.clamp(1, maxQuestion);
    final lastSubjectId = prefs.getString('wq_last_subject_id');
    int subjectIdx = 0;
    if (lastSubjectId != null) {
      final idx = subjects.indexWhere((s) => s.id == lastSubjectId);
      if (idx >= 0) subjectIdx = idx;
    }

    if (!context.mounted) return;
    final noteCtrl = TextEditingController();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽条
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 标题栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                  child: Row(
                    children: [
                      Text('添加错题',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消',
                            style: TextStyle(color: Color(0xFF8E8E93))),
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: () async {
                          final subject = subjects[subjectIdx];
                          ref
                              .read(wrongQuestionProvider.notifier)
                              .addQuestion(WrongQuestion(
                                subjectId: subject.id,
                                pageNumber: pageNum,
                                questionNumber: qNum,
                                note: noteCtrl.text.trim().isEmpty
                                    ? null
                                    : noteCtrl.text.trim(),
                              ));
                          // 记住位置，下次添加从这儿开始
                          await prefs.setString(
                              'wq_last_subject_id', subject.id);
                          await prefs.setInt('wq_last_page', pageNum);
                          await prefs.setInt('wq_last_question', qNum);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                        ),
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 三列滚轮选择器
                SizedBox(
                  height: itemExtent * 5,
                  child: Row(
                    children: [
                      // ── 科目列 ──
                      Expanded(
                        flex: 4,
                        child: _PickerColumn<String>(
                          itemExtent: itemExtent,
                          initialIndex: subjectIdx,
                          items: subjects.map((s) => s.name).toList(),
                          onChanged: (i) => setSheet(() => subjectIdx = i),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      // ── 页码列 ──
                      Expanded(
                        flex: 3,
                        child: _PickerColumn<int>(
                          itemExtent: itemExtent,
                          initialIndex: pageNum - 1,
                          items: List.generate(maxPage, (i) => i + 1),
                          labelSuffix: '页',
                          onChanged: (i) => setSheet(() => pageNum = i + 1),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      // ── 题号列 ──
                      Expanded(
                        flex: 3,
                        child: _PickerColumn<int>(
                          itemExtent: itemExtent,
                          initialIndex: qNum - 1,
                          items: List.generate(maxQuestion, (i) => i + 1),
                          labelSuffix: '题',
                          onChanged: (i) => setSheet(() => qNum = i + 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 备注输入
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      hintText: '备注（可选）',
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  滚轮选择器列
// ============================================================
class _PickerColumn<T> extends StatefulWidget {
  final double itemExtent;
  final int initialIndex;
  final List<T> items;
  final String? labelSuffix;
  final ValueChanged<int> onChanged;

  const _PickerColumn({
    required this.itemExtent,
    required this.initialIndex,
    required this.items,
    required this.onChanged,
    this.labelSuffix,
  });

  @override
  State<_PickerColumn<T>> createState() => _PickerColumnState<T>();
}

class _PickerColumnState<T> extends State<_PickerColumn<T>> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _label(T item) {
    final base = item.toString();
    return widget.labelSuffix != null ? '$base${widget.labelSuffix}' : base;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: widget.itemExtent,
          perspective: 0.005,
          diameterRatio: 1.8,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: widget.onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.items.length,
            builder: (ctx, index) {
              return Center(
                child: Text(
                  _label(widget.items[index]),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
        // 选中行高亮
        IgnorePointer(
          child: Column(
            children: [
              const Spacer(),
              Container(
                height: widget.itemExtent,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.06),
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
                    bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
//  添加轮次对话框
// ============================================================
void _showAddRoundDialog(BuildContext context, WidgetRef ref,
    WrongQuestion question, int currentRound) {
  WQStatus selectedStatus = WQStatus.wrong;
  final noteCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('第${currentRound + 1}轮复习',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('复习结果', style: TextStyle(color: Color(0xFF8E8E93))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatusOption(
                    label: '还是错',
                    status: WQStatus.wrong,
                    color: const Color(0xFFFF6B6B),
                    selected: selectedStatus,
                    onTap: () => setDlg(() => selectedStatus = WQStatus.wrong)),
                _StatusOption(
                    label: '做对了',
                    status: WQStatus.corrected,
                    color: const Color(0xFFFF9F43),
                    selected: selectedStatus,
                    onTap: () =>
                        setDlg(() => selectedStatus = WQStatus.corrected)),
                _StatusOption(
                    label: '掌握了',
                    status: WQStatus.mastered,
                    color: const Color(0xFF00B894),
                    selected: selectedStatus,
                    onTap: () =>
                        setDlg(() => selectedStatus = WQStatus.mastered)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: '备注（可选）',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('取消', style: TextStyle(color: Color(0xFF8E8E93)))),
          FilledButton(
            onPressed: () {
              ref
                  .read(wrongQuestionProvider.notifier)
                  .addRound(WrongQuestionRound(
                    questionId: question.id,
                    round: currentRound + 1,
                    status: selectedStatus,
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                  ));
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    ),
  );
}

class _StatusOption extends StatelessWidget {
  final String label;
  final WQStatus status;
  final Color color;
  final WQStatus selected;
  final VoidCallback onTap;
  const _StatusOption(
      {required this.label,
      required this.status,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == status;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
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

class _QuestionListTab extends ConsumerStatefulWidget {
  const _QuestionListTab();

  @override
  ConsumerState<_QuestionListTab> createState() => _QuestionListTabState();
}

class _QuestionListTabState extends ConsumerState<_QuestionListTab> {
  /// 已展开的页码 key = "$subjectId::$page"
  final Set<String> _expandedPages = {};

  void _toggle(String key) {
    setState(() {
      if (!_expandedPages.add(key)) {
        _expandedPages.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final wqState = ref.watch(wrongQuestionProvider);
    final subjects = ref.watch(subjectsProvider);
    final wqNotifier = ref.read(wrongQuestionProvider.notifier);

    final subjectNames = <String, String>{};
    final subjectColorIdx = <String, int>{};
    final allSubjects = subjects.toList();
    for (int i = 0; i < allSubjects.length; i++) {
      subjectNames[allSubjects[i].id] = allSubjects[i].name;
      subjectColorIdx[allSubjects[i].id] = i;
    }
    final questions = wqState.questions;

    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 56,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            const Text('还没有错题记录',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16)),
            const SizedBox(height: 8),
            const Text('点击右下角 + 添加第一道错题',
                style: TextStyle(color: Color(0xFFC7C7CC), fontSize: 13)),
          ],
        ),
      );
    }

    // —— 按创建时间倒序，再按 学科 → 页码 分组 ——
    final sortedQuestions = List<WrongQuestion>.from(questions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // subjectId → SubjectGroup
    final subjectOrder = <String>[];
    final subjectGroupMap = <String, _SubjectGroup>{};

    // 用于保持页码出现顺序
    final pageOrderBySubject = <String, List<int>>{};

    for (final q in sortedQuestions) {
      final sid = q.subjectId;
      final name = subjectNames[sid] ?? '未知科目';
      final group = subjectGroupMap.putIfAbsent(
        sid,
        () {
          subjectOrder.add(sid);
          return _SubjectGroup(
            subjectId: sid,
            subjectName: name,
            colorIdx: subjectColorIdx[sid] ?? 0,
          );
        },
      );
      final pageList = pageOrderBySubject.putIfAbsent(sid, () => []);
      final page = q.pageNumber;
      group.pages.putIfAbsent(
        page,
        () {
          pageList.add(page);
          return <_QuestionItem>[];
        },
      );

      final currentRound = wqNotifier.latestRound(q.id);
      final status = wqNotifier.currentStatus(q.id);
      final rounds = wqNotifier.roundsFor(q.id);

      group
        ..pages[page]!.add(_QuestionItem(
          question: q,
          currentRound: currentRound,
          status: status,
          rounds: rounds,
        ))
        ..recalc();
    }

    final subjectGroups =
        subjectOrder.map((sid) => subjectGroupMap[sid]!).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final sg in subjectGroups) ...[
          _SubjectGroupHeader(group: sg),
          const SizedBox(height: 12),
          for (final page in pageOrderBySubject[sg.subjectId]!)
            _PageSection(
              key: ValueKey('${sg.subjectId}:$page'),
              subjectGroup: sg,
              page: page,
              questions: sg.pages[page]!,
              expanded: _expandedPages.contains('${sg.subjectId}:$page'),
              onToggle: () => _toggle('${sg.subjectId}:$page'),
              onAddRound: (q, round) =>
                  _showAddRoundDialog(context, ref, q, round),
              onDelete: (q) async {
                await wqNotifier.deleteQuestion(q.id);
              },
            ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

// ============================================================
//  分组模型
// ============================================================

class _SubjectGroup {
  final String subjectId;
  final String subjectName;
  final int colorIdx;
  /// pageNumber → 该页的错题（按创建时间倒序）
  final Map<int, List<_QuestionItem>> pages = {};
  int total = 0;
  final Map<WQStatus, int> statusCounts = {
    WQStatus.wrong: 0,
    WQStatus.corrected: 0,
    WQStatus.mastered: 0,
  };

  _SubjectGroup({
    required this.subjectId,
    required this.subjectName,
    required this.colorIdx,
  });

  void recalc() {
    total = 0;
    for (final s in statusCounts.keys) {
      statusCounts[s] = 0;
    }
    for (final list in pages.values) {
      for (final item in list) {
        total++;
        statusCounts[item.status] = (statusCounts[item.status] ?? 0) + 1;
      }
    }
  }

  Color get color =>
      AppColors.subjectColors[colorIdx % AppColors.subjectColors.length];
}

class _QuestionItem {
  final WrongQuestion question;
  final int currentRound;
  final WQStatus status;
  final List<WrongQuestionRound> rounds;

  _QuestionItem({
    required this.question,
    required this.currentRound,
    required this.status,
    required this.rounds,
  });
}

// ============================================================
//  学科分组 Header
// ============================================================

class _SubjectGroupHeader extends StatelessWidget {
  final _SubjectGroup group;

  const _SubjectGroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final c = group.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: c, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.withValues(alpha: 0.18), c.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(group.subjectName.isNotEmpty ? group.subjectName[0] : '?',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: c)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              group.subjectName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text('${group.total} 道',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 10),
          _Dots(statusCounts: group.statusCounts, mini: true),
        ],
      ),
    );
  }
}

// ============================================================
//  状态小圆点
// ============================================================

const _statusColorFor = {
  WQStatus.wrong: Color(0xFFFF6B6B),
  WQStatus.corrected: Color(0xFFFF9F43),
  WQStatus.mastered: Color(0xFF00B894),
};

class _Dots extends StatelessWidget {
  final Map<WQStatus, int> statusCounts;
  final bool mini;
  const _Dots({required this.statusCounts, this.mini = false});

  @override
  Widget build(BuildContext context) {
    final size = mini ? 7.0 : 9.0;
    final spacing = mini ? 3.0 : 5.0;
    final showCount = !mini;
    final entries = WQStatus.values
        .where((s) => (statusCounts[s] ?? 0) > 0)
        .toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in entries) ...[
          if (showCount)
            Text('${statusCounts[s]}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColorFor[s])),
          Container(
            width: size,
            height: size,
            margin: EdgeInsets.symmetric(horizontal: spacing / 2),
            decoration: BoxDecoration(
              color: _statusColorFor[s],
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
//  页码分区（题号折叠的核心）
// ============================================================

class _PageSection extends StatelessWidget {
  final _SubjectGroup subjectGroup;
  final int page;
  final List<_QuestionItem> questions;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(WrongQuestion q, int currentRound) onAddRound;
  final Future<void> Function(WrongQuestion q) onDelete;

  const _PageSection({
    super.key,
    required this.subjectGroup,
    required this.page,
    required this.questions,
    required this.expanded,
    required this.onToggle,
    required this.onAddRound,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = subjectGroup.color;
    final statusCounts = <WQStatus, int>{
      WQStatus.wrong: 0,
      WQStatus.corrected: 0,
      WQStatus.mastered: 0,
    };
    for (final q in questions) {
      statusCounts[q.status] = (statusCounts[q.status] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // —— 页码行（点击展开/收起） ——
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.chevron_right,
                          size: 22,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('P$page',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c)),
                    ),
                    const SizedBox(width: 10),
                    Text('${questions.length} 题',
                        style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                    const Spacer(),
                    _Dots(statusCounts: statusCounts, mini: true),
                  ],
                ),
              ),
            ),
          ),
          // —— 折叠展开区域：每道题的具体信息 ——
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(height: 1, thickness: 1),
                for (final item in questions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: _CollapsedQuestionCard(
                      item: item,
                      subjectName: subjectGroup.subjectName,
                      accentColor: c,
                      onAddRound: () =>
                          onAddRound(item.question, item.currentRound),
                      onDelete: () => onDelete(item.question),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  折叠状态下的单道错题卡片（题号 + 状态 + 操作）
// ============================================================

class _CollapsedQuestionCard extends StatelessWidget {
  final _QuestionItem item;
  final String subjectName;
  final Color accentColor;
  final VoidCallback onAddRound;
  final VoidCallback onDelete;

  const _CollapsedQuestionCard({
    required this.item,
    required this.subjectName,
    required this.accentColor,
    required this.onAddRound,
    required this.onDelete,
  });

  Color get _statusColor => _statusColorFor[item.status]!;

  String get _statusLabel {
    switch (item.status) {
      case WQStatus.wrong:
        return '未掌握';
      case WQStatus.corrected:
        return '已纠正';
      case WQStatus.mastered:
        return '已掌握';
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = item.question;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: _statusColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：题号 + 状态
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                    Text('#${q.questionNumber}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _statusColor)),
              ),
              const SizedBox(width: 8),
              Text('P${q.pageNumber}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor)),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz,
                    size: 18, color: Color(0xFFC7C7CC)),
                padding: EdgeInsets.zero,
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('删除',
                          style: TextStyle(color: Color(0xFFFF6B6B)))),
                ],
              ),
            ],
          ),
          // 备注
          if (q.note != null && q.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(q.note!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          // 轮次时间线
          if (item.rounds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _RoundTimeline(rounds: item.rounds),
          ],
          // 复习按钮 + 日期
          const SizedBox(height: 6),
          Row(
            children: [
              if (item.status != WQStatus.mastered)
                TextButton.icon(
                  onPressed: onAddRound,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text('第${item.currentRound + 1}轮复习'),
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              const Spacer(),
              Text(DateFormat('MM/dd').format(q.createdAt),
                  style: const TextStyle(fontSize: 11, color: Color(0xFFC7C7CC))),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  轮

// ============================================================
//  统计总览 Tab
// ============================================================
class _StatsOverviewTab extends ConsumerWidget {
  const _StatsOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wqState = ref.watch(wrongQuestionProvider);
    final subjects = ref.watch(subjectsProvider);
    final wqNotifier = ref.read(wrongQuestionProvider.notifier);

    final subjectNames = <String, String>{};
    for (final s in subjects) {
      subjectNames[s.id] = s.name;
    }

    final questions = wqState.questions;
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            const Text('还没有错题数据',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16)),
          ],
        ),
      );
    }

    final statusCount = wqNotifier.countByStatus();
    final subjectCount = wqNotifier.countBySubject(subjectNames);
    final roundCount = wqNotifier.countByRound();
    final passRates = wqNotifier.passRateByRound();
    final mastery = wqNotifier.masteryRate;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 掌握率圆环
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.energyGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 42,
                        sections: [
                          PieChartSectionData(
                              value: mastery * 100,
                              color: Colors.white,
                              radius: 14,
                              showTitle: false),
                          PieChartSectionData(
                              value: (1 - mastery) * 100,
                              color: Colors.white.withValues(alpha: 0.25),
                              radius: 14,
                              showTitle: false),
                        ],
                      ),
                    ),
                    Text('${(mastery * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('掌握率',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 4),
                    Text(
                        '${statusCount[WQStatus.mastered] ?? 0} / ${questions.length} 道已掌握',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                          value: mastery,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          color: Colors.white,
                          minHeight: 6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 状态分布饼图
        const _WQSectionTitle('状态分布'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections:
                        _buildStatusPieSections(statusCount, questions.length),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PieLegendDot(
                        color: const Color(0xFFFF6B35),
                        label: '未掌握',
                        count: statusCount[WQStatus.wrong] ?? 0,
                        total: questions.length),
                    const SizedBox(height: 10),
                    _PieLegendDot(
                        color: const Color(0xFFFFA726),
                        label: '已纠正',
                        count: statusCount[WQStatus.corrected] ?? 0,
                        total: questions.length),
                    const SizedBox(height: 10),
                    _PieLegendDot(
                        color: const Color(0xFF66BB6A),
                        label: '已掌握',
                        count: statusCount[WQStatus.mastered] ?? 0,
                        total: questions.length),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (roundCount.isNotEmpty) ...[
          const _WQSectionTitle('各轮次题目数'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (roundCount.values.fold<int>(0, (a, b) => a > b ? a : b) *
                              1.3)
                          .ceilToDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('R${value.toInt()}',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF8E8E93))),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: (roundCount.entries.toList()
                        ..sort((a, b) => a.key.compareTo(b.key)))
                      .map((e) {
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 28,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (subjectCount.isNotEmpty) ...[
          const _WQSectionTitle('科目分布'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 28,
                      sections: _buildSubjectPieSections(subjectCount),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subjectCount.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final idx = entry.key;
                      final e = entry.value;
                      final color = AppColors
                          .subjectColors[idx % AppColors.subjectColors.length];
                      final pct = questions.isNotEmpty
                          ? (e.value / questions.length * 100)
                              .toStringAsFixed(0)
                          : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(e.key,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis)),
                            Text('${e.value}道',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Text(' $pct%',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF8E8E93))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (passRates.isNotEmpty) ...[
          const _WQSectionTitle('各轮次通过率'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: (passRates.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key)))
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          SizedBox(
                              width: 50,
                              child: Text('第${e.key}轮',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                          Expanded(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                      value: e.value,
                                      backgroundColor: const Color(0xFFF2F2F7),
                                      color: e.value >= 0.8
                                          ? AppColors.success
                                          : const Color(0xFFFF9F43),
                                      minHeight: 8))),
                          const SizedBox(width: 12),
                          Text('${(e.value * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: e.value >= 0.8
                                      ? AppColors.success
                                      : const Color(0xFFFF9F43))),
                        ]),
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

class _WQSectionTitle extends StatelessWidget {
  final String title;
  const _WQSectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface));
}

List<PieChartSectionData> _buildStatusPieSections(
    Map<WQStatus, int> statusCount, int total) {
  final wrong = statusCount[WQStatus.wrong] ?? 0;
  final corrected = statusCount[WQStatus.corrected] ?? 0;
  final mastered = statusCount[WQStatus.mastered] ?? 0;
  if (total == 0) return [];
  return [
    PieChartSectionData(
        value: wrong.toDouble(),
        title: '',
        radius: 28,
        color: const Color(0xFFFF6B35),
        badgePositionPercentageOffset: 0.4,
        badgeWidget:
            wrong > 0 ? _ChartBadge('$wrong', const Color(0xFFFF6B35)) : null),
    PieChartSectionData(
        value: corrected.toDouble(),
        title: '',
        radius: 28,
        color: const Color(0xFFFFA726),
        badgePositionPercentageOffset: 0.4,
        badgeWidget: corrected > 0
            ? _ChartBadge('$corrected', const Color(0xFFFFA726))
            : null),
    PieChartSectionData(
        value: mastered.toDouble(),
        title: '',
        radius: 28,
        color: const Color(0xFF66BB6A),
        badgePositionPercentageOffset: 0.4,
        badgeWidget: mastered > 0
            ? _ChartBadge('$mastered', const Color(0xFF66BB6A))
            : null),
  ];
}

List<PieChartSectionData> _buildSubjectPieSections(
    Map<String, int> subjectCount) {
  final total = subjectCount.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return [];
  final entries = subjectCount.entries.toList();
  return List.generate(entries.length, (i) {
    final e = entries[i];
    final color = AppColors.subjectColors[i % AppColors.subjectColors.length];
    return PieChartSectionData(
        value: e.value.toDouble(), title: '', radius: 28, color: color);
  });
}

// ============================================================
//  复习轮次时间线（折叠卡片内）
// ============================================================

class _RoundTimeline extends StatelessWidget {
  final List<WrongQuestionRound> rounds;

  const _RoundTimeline({required this.rounds});

  @override
  Widget build(BuildContext context) {
    final sorted = List<WrongQuestionRound>.from(rounds)
      ..sort((a, b) => a.round.compareTo(b.round));
    return Row(
      children: [
        for (int i = 0; i < sorted.length; i++) ...[
          Builder(builder: (_) {
            final r = sorted[i];
            final isLast = i == sorted.length - 1;
            final dotColor =
                r.isCorrect ? const Color(0xFF00B894) : const Color(0xFFFF6B6B);
            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: dotColor, shape: BoxShape.circle),
                      ),
                      Text('R${r.round}',
                          style: TextStyle(
                              fontSize: 9,
                              color: isLast
                                  ? dotColor
                                  : const Color(0xFFC7C7CC))),
                    ],
                  ),
                  if (!isLast)
                    Expanded(
                        child: Container(
                            height: 1, color: const Color(0xFFE5E5EA))),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _ChartBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _ChartBadge(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _PieLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  const _PieLegendDot(
      {required this.color,
      required this.label,
      required this.count,
      required this.total});
  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('$count',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Text(' ($pct%)',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
      ],
    );
  }
}

