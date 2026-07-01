import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:studyflow/main.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});
  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('学习统计'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelColor: Theme.of(context).colorScheme.onSurface,
           unselectedLabelColor: const Color(0xFF8E8E93),
          labelStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '今日'),
            Tab(text: '本周'),
            Tab(text: '本月'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TodayTab(),
          _WeekTab(),
          _MonthTab(),
        ],
      ),
    );
  }
}

// ============================================================
//  颜色
// ============================================================
final _colors = AppColors.subjectColors;

// ============================================================
//  共用 Hero 卡片
// ============================================================
class _StatCard extends StatelessWidget {
  final int totalMin;
  const _StatCard({required this.totalMin});

  @override
  Widget build(BuildContext context) {
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text('学习时长',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                    text: '$h',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                TextSpan(
                    text: ' 小时 ',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7))),
                TextSpan(
                    text: '$m',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                TextSpan(
                    text: ' 分钟',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  今日 Tab
// ============================================================
class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    ref.watch(sessionsProvider); // 建立监听关系
    final totalMin =
        ref.read(sessionsProvider.notifier).getTotalMinutesForDate(today);
    final dist = ref
        .read(sessionsProvider.notifier)
        .getSubjectDistributionForDate(today);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(totalMin: totalMin),
        const SizedBox(height: 20),
        if (dist.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('今天还没有学习记录',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15)),
            ),
          )
        else ...[
          _SectionTitle('科目分布'),
          const SizedBox(height: 12),
          _BarChart(dist: dist),
          const SizedBox(height: 24),
          _SectionTitle('科目详情'),
          const SizedBox(height: 12),
          ...dist.entries.map((e) {
            final idx = dist.keys.toList().indexOf(e.key);
            final pct = totalMin > 0
                ? (e.value / totalMin * 100).toStringAsFixed(0)
                : '0';
            return _SubjectTile(
              name: e.key,
              minutes: e.value,
              percentage: pct,
              color: _colors[idx % _colors.length],
            );
          }),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface));
}

// ============================================================
//  柱状图
// ============================================================
class _BarChart extends StatelessWidget {
  final Map<String, int> dist;
  const _BarChart({required this.dist});

  @override
  Widget build(BuildContext context) {
    final maxVal = dist.values.isEmpty
        ? 60.0
        : dist.values.reduce((a, b) => a > b ? a : b).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.3,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}m',
                    style:
                        const TextStyle(fontSize: 10, color: Color(0xFFC7C7CC)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx >= dist.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(dist.keys.elementAt(idx),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8E8E93)),
                          overflow: TextOverflow.ellipsis),
                    );
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxVal / 4).ceilToDouble().clamp(15, 60),
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Color(0xFFF2F2F7), strokeWidth: 1),
            ),
            barGroups: List.generate(dist.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: dist.values.elementAt(i).toDouble(),
                    color: _colors[i % _colors.length],
                    width: 22,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  科目详情行
// ============================================================
class _SubjectTile extends StatelessWidget {
  final String name;
  final int minutes;
  final String percentage;
  final Color color;
  const _SubjectTile(
      {required this.name,
      required this.minutes,
      required this.percentage,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 15)),
          ),
          Text('$percentage%',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 14),
          Text('${h}h ${m}m',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

// ============================================================
//  本周 Tab
// ============================================================
class _WeekTab extends ConsumerWidget {
  const _WeekTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    ref.watch(sessionsProvider); // 建立监听关系
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int totalMin = 0;
    final dailyMin = <int, int>{};
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final m =
          ref.read(sessionsProvider.notifier).getTotalMinutesForDate(date);
      dailyMin[i] = m;
      totalMin += m;
    }

    final maxVal = dailyMin.values.isEmpty
        ? 60.0
        : dailyMin.values.reduce((a, b) => a > b ? a : b).toDouble();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(totalMin: totalMin),
        const SizedBox(height: 20),
        Text('每日学习',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.3,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}m',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFFC7C7CC))),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = ['一', '二', '三', '四', '五', '六', '日'];
                        final isToday = v.toInt() == now.weekday - 1;
                        return Text(days[v.toInt()],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isToday ? FontWeight.w700 : FontWeight.w400,
                              color: isToday
                                  ? AppColors.primary
                                  : const Color(0xFF8E8E93),
                            ));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFF2F2F7), strokeWidth: 1),
                ),
                barGroups: dailyMin.entries.map((e) {
                  final isToday = e.key == now.weekday - 1;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        color: isToday
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
//  本月 Tab
// ============================================================
class _MonthTab extends ConsumerWidget {
  const _MonthTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    int totalMin = 0;
    final dailyMin = <DateTime, int>{};

    final sessions = ref.read(sessionsProvider);
    for (final s in sessions) {
      if (!s.startTime.isBefore(monthStart)) {
        final date =
            DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
        dailyMin[date] = (dailyMin[date] ?? 0) + s.durationMinutes;
        totalMin += s.durationMinutes;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(totalMin: totalMin),
        const SizedBox(height: 20),
        Text('学习日历',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // 星期标题行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const ['一', '二', '三', '四', '五', '六', '日']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8E8E93))),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              // 日历网格
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1,
                ),
                itemCount:
                    daysInMonth + DateTime(now.year, now.month, 1).weekday - 1,
                itemBuilder: (context, index) {
                  final leadingBlanks =
                      DateTime(now.year, now.month, 1).weekday - 1;
                  if (index < leadingBlanks) {
                    return const SizedBox.shrink();
                  }
                  final dayNumber = index - leadingBlanks + 1;
                  final date = DateTime(now.year, now.month, dayNumber);
                  final minutes = dailyMin[date] ?? 0;
                  final intensity =
                      minutes > 0 ? (minutes / 120).clamp(0.15, 1.0) : 0.0;
                  final isToday = dayNumber == now.day;

                  return Container(
                    decoration: BoxDecoration(
                      color: intensity > 0
                          ? AppColors.primary.withValues(alpha: intensity)
                          : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$dayNumber',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isToday ? FontWeight.w700 : FontWeight.w400,
                              color: intensity > 0.5
                                  ? Colors.white
                                  : const Color(0xFF8E8E93),
                            )),
                        if (minutes > 0)
                          Text('${minutes}m',
                              style: TextStyle(
                                fontSize: 8,
                                color: intensity > 0.5
                                    ? Colors.white
                                    : AppColors.primary,
                              )),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

