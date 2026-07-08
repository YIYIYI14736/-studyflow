import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:studyflow/main.dart';
import 'package:studyflow/services/data_backup_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSectionHeader('番茄钟设置'),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.timerGradient),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.timer, color: Colors.white, size: 18),
            ),
            title: const Text('工作时长'),
            subtitle: Text('${settings.pomodoroWorkMinutes} 分钟'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.pomodoroWorkMinutes.toDouble(),
                min: 15,
                max: 60,
                divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setPomodoroWorkMinutes(value.round()),
              ),
            ),
          ),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: AppColors.energyGradient),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.coffee, color: Colors.white, size: 18),
            ),
            title: const Text('休息时长'),
            subtitle: Text('${settings.pomodoroBreakMinutes} 分钟'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.pomodoroBreakMinutes.toDouble(),
                min: 3,
                max: 30,
                divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setPomodoroBreakMinutes(value.round()),
              ),
            ),
          ),
          const Divider(),
          _buildSectionHeader('通知'),
          SwitchListTile(
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications,
                  color: Color(0xFFFF6B35), size: 18),
            ),
            title: const Text('启用通知'),
            subtitle: const Text('计时结束时发送通知'),
            value: settings.notificationsEnabled,
            onChanged: (value) => ref
                .read(settingsProvider.notifier)
                .setNotificationsEnabled(value),
          ),
          const Divider(),
          _buildSectionHeader('外观'),
          SwitchListTile(
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dark_mode,
                  color: Color(0xFFFF6B35), size: 18),
            ),
            title: const Text('深色模式'),
            value: settings.isDarkMode,
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).setDarkMode(value),
          ),
          const Divider(),
          _buildSectionHeader('数据'),
          ListTile(
            leading: const Icon(Icons.backup, color: Color(0xFFA0A0A0)),
            title: const Text('备份数据'),
            subtitle: const Text('导出为本地 JSON 备份文件'),
            onTap: _backupData,
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Color(0xFFA0A0A0)),
            title: const Text('恢复数据'),
            subtitle: const Text('从最近一次本地备份恢复'),
            onTap: _restoreData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
            subtitle: const Text('清除学习记录、计划、错题、设置和 AI 记忆'),
            onTap: _clearAllData,
          ),
          const SizedBox(height: 24),
          const Center(
              child: Text('StudyFlow v1.0.0',
                  style: TextStyle(color: Color(0xFFB09988)))),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(title,
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );

  DataBackupService get _backupService =>
      DataBackupService(ref.read(databaseProvider));

  Future<void> _backupData() async {
    try {
      final file = await _backupService.createBackupFile();
      if (!mounted) return;
      await _showResultDialog(
        title: '备份完成',
        message: '备份文件已保存到：\n${file.path}',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('备份失败：$e');
    }
  }

  Future<void> _restoreData() async {
    final latest = await _backupService.latestBackupFile();
    if (!mounted) return;
    if (latest == null) {
      _showSnackBar('没有找到可恢复的备份文件');
      return;
    }

    final confirmed = await _confirmDangerousAction(
      title: '恢复数据',
      message: '将从最近备份恢复数据，并覆盖当前所有数据。\n\n备份文件：\n${latest.path}',
      confirmLabel: '恢复',
    );
    if (!confirmed || !mounted) return;

    try {
      final file = await _backupService.restoreLatestBackupFile();
      if (!mounted) return;
      _refreshDataProviders();
      await _showResultDialog(
        title: '恢复完成',
        message: '已从备份恢复：\n${file.path}',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('恢复失败：$e');
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await _confirmDangerousAction(
      title: '清除所有数据',
      message: '此操作会清除学习记录、计划、错题、设置和 AI 记忆，无法撤销。建议先备份。',
      confirmLabel: '清除',
    );
    if (!confirmed || !mounted) return;

    try {
      await _backupService.clearAllData();
      if (!mounted) return;
      _refreshDataProviders();
      _showSnackBar('所有数据已清除');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('清除失败：$e');
    }
  }

  Future<bool> _confirmDangerousAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SelectableText(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          )
        ],
      ),
    );
  }

  void _refreshDataProviders() {
    ref.invalidate(settingsProvider);
    ref.invalidate(subjectsProvider);
    ref.invalidate(plansProvider);
    ref.invalidate(wrongQuestionProvider);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
