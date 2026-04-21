import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:studyflow/providers/providers.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习统计')),
      body: Column(
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('今日')),
              ButtonSegment(value: 1, label: Text('本周')),
              ButtonSegment(value: 2, label: Text('本月')),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (Set<int> selection) {
              setState(() => _selectedTab = selection.first);
            },
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildTodayStats();
      case 1:
        return _buildWeekStats();
      case 2:
        return _buildMonthStats();
      default:
        return _buildTodayStats();
    }
  }

  Widget _buildTodayStats() {
    final today = DateTime.now();
    final todayMinutes = ref.read(sessionsProvider.notifier).getTotalMinutesForDate(today);
    final distribution = ref.read(sessionsProvider.notifier).getSubjectDistributionForDate(today);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          '今日学习时长',
          '${todayMinutes ~/ 60}小时${todayMinutes % 60}分钟',
          Icons.timer,
          Colors.blue,
        ),
        const SizedBox(height: 24),
        Text('科目分布', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (distribution.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('今天还没有学习记录')))
        else
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: distribution.entries.map((e) {
                  final colors = [
                    Colors.blue, Colors.red, Colors.green, Colors.orange,
                    Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
                  ];
                  final index = distribution.keys.toList().indexOf(e.key);
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    title: '${e.key}\n${e.value}分钟',
                    color: colors[index % colors.length],
                    radius: 80,
                    titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
        const SizedBox(height: 16),
        ...distribution.entries.map((e) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(e.key[0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(e.key),
              trailing: Text('${e.value ~/ 60}小时${e.value % 60}分钟'),
            )),
      ],
    );
  }

  Widget _buildWeekStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int totalMinutes = 0;
    final dailyMinutes = <int, int>{};

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final minutes = ref.read(sessionsProvider.notifier).getTotalMinutesForDate(date);
      dailyMinutes[i] = minutes;
      totalMinutes += minutes;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          '本周学习时长',
          '${totalMinutes ~/ 60}小时${totalMinutes % 60}分钟',
          Icons.calendar_today,
          Colors.green,
        ),
        const SizedBox(height: 24),
        Text('每日学习时长', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}分'),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['一', '二', '三', '四', '五', '六', '日'];
                      return Text(days[value.toInt()]);
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: dailyMinutes.entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(),
                      color: Colors.blue,
                      width: 20,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthStats() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    int totalMinutes = 0;
    final dailyMinutes = <DateTime, int>{};

    final sessions = ref.read(sessionsProvider);
    for (final session in sessions) {
      if (session.startTime.isAfter(monthStart) ||
          session.startTime.isAtSameMomentAs(monthStart)) {
        final date = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
        dailyMinutes[date] = (dailyMinutes[date] ?? 0) + session.durationMinutes;
        totalMinutes += session.durationMinutes;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          '本月学习时长',
          '${totalMinutes ~/ 60}小时${totalMinutes % 60}分钟',
          Icons.bar_chart,
          Colors.purple,
        ),
        const SizedBox(height: 24),
        Text('学习日历', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildHeatmap(dailyMinutes),
      ],
    );
  }

  Widget _buildHeatmap(Map<DateTime, int> dailyMinutes) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final date = DateTime(now.year, now.month, index + 1);
        final minutes = dailyMinutes[date] ?? 0;
        final intensity = minutes > 0 ? (minutes / 120).clamp(0.1, 1.0) : 0.0;

        return Container(
          decoration: BoxDecoration(
            color: intensity > 0
                ? Colors.green.withValues(alpha: intensity)
                : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 10,
                color: intensity > 0.5 ? Colors.white : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
