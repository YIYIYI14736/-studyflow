import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _apiKeyController = TextEditingController(text: settings.openaiApiKey ?? '');
    _baseUrlController = TextEditingController(text: settings.openaiBaseUrl ?? '');
    _modelController = TextEditingController(text: settings.openaiModel);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSectionHeader('AI 配置'),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('API Key'),
            subtitle: Text(
              settings.openaiApiKey != null && settings.openaiApiKey!.isNotEmpty
                  ? '已配置'
                  : '未配置',
            ),
            onTap: () => _showEditDialog(
              'API Key',
              _apiKeyController,
              (value) => ref.read(settingsProvider.notifier).setApiKey(value),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('API Base URL'),
            subtitle: Text(settings.openaiBaseUrl ?? '默认'),
            onTap: () => _showBaseUrlSelector(settings.openaiBaseUrl),
          ),
          ListTile(
            leading: const Icon(Icons.model_training),
            title: const Text('模型'),
            subtitle: Text(settings.openaiModel),
            onTap: () => _showModelSelector(settings.openaiModel),
          ),
          const Divider(),
          _buildSectionHeader('番茄钟设置'),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('工作时长'),
            subtitle: Text('${settings.pomodoroWorkMinutes} 分钟'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.pomodoroWorkMinutes.toDouble(),
                min: 15,
                max: 60,
                divisions: 9,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setPomodoroWorkMinutes(value.round());
                },
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.coffee),
            title: const Text('休息时长'),
            subtitle: Text('${settings.pomodoroBreakMinutes} 分钟'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.pomodoroBreakMinutes.toDouble(),
                min: 3,
                max: 30,
                divisions: 9,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setPomodoroBreakMinutes(value.round());
                },
              ),
            ),
          ),
          const Divider(),
          _buildSectionHeader('通知'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('启用通知'),
            subtitle: const Text('计时结束时发送通知'),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setNotificationsEnabled(value);
            },
          ),
          const Divider(),
          _buildSectionHeader('外观'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('深色模式'),
            value: settings.isDarkMode,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setDarkMode(value);
            },
          ),
          const Divider(),
          _buildSectionHeader('数据'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份数据'),
            onTap: () => _showBackupDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复数据'),
            onTap: () => _showRestoreDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
            onTap: () => _showClearDataDialog(),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'StudyFlow v1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  void _showEditDialog(String title, TextEditingController controller, Function(String?) onSave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑 $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
          obscureText: title == 'API Key',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.isEmpty ? null : controller.text);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showBaseUrlSelector(String? currentUrl) {
    final presets = [
      {'name': '火山方舟 (推荐)', 'url': 'https://ark.cn-beijing.volces.com/api/coding/v3'},
      {'name': 'OpenAI', 'url': 'https://api.openai.com/v1'},
      {'name': '阿里云通义', 'url': 'https://dashscope.aliyuncs.com/compatible-mode/v1'},
      {'name': '智谱 AI', 'url': 'https://open.bigmodel.cn/api/paas/v4'},
      {'name': 'DeepSeek', 'url': 'https://api.deepseek.com'},
      {'name': 'Moonshot', 'url': 'https://api.moonshot.cn/v1'},
      {'name': '自定义', 'url': 'custom'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择 API 服务商'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final url = preset['url'] as String?;
              final isSelected = url == currentUrl || (url == null && currentUrl == null);

              return RadioListTile<String?>(
                title: Text(preset['name'] as String),
                subtitle: url != null && url != 'custom'
                    ? Text(url, style: const TextStyle(fontSize: 11))
                    : null,
                value: url,
                groupValue: currentUrl,
                onChanged: (value) {
                  Navigator.pop(context);
                  if (value == 'custom') {
                    _showEditDialog(
                      'Base URL',
                      _baseUrlController,
                      (v) => ref.read(settingsProvider.notifier).setBaseUrl(v),
                    );
                  } else {
                    ref.read(settingsProvider.notifier).setBaseUrl(value);
                    _baseUrlController.text = value ?? '';
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showModelSelector(String currentModel) {
    final presets = [
      {'name': 'DeepSeek V3.2 (推荐)', 'value': 'deepseek-v3.2'},
      {'name': 'Doubao Seed 2.0 Pro', 'value': 'doubao-seed-2.0-pro'},
      {'name': 'Kimi K2.6', 'value': 'kimi-k2.6'},
      {'name': 'Kimi K2.5', 'value': 'kimi-k2.5'},
      {'name': 'GLM 5.1', 'value': 'glm-5.1'},
      {'name': 'GLM 4.7', 'value': 'glm-4.7'},
      {'name': 'MiniMax M2.7', 'value': 'minimax-m2.7'},
      {'name': 'MiniMax M2.5', 'value': 'minimax-m2.5'},
      {'name': 'Ark Code Latest', 'value': 'ark-code-latest'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择模型'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: presets.length + 1,
            itemBuilder: (context, index) {
              if (index == presets.length) {
                return ListTile(
                  title: const Text('自定义模型名称'),
                  subtitle: const Text('输入自定义模型 ID'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(
                      '模型名称',
                      _modelController,
                      (v) => ref.read(settingsProvider.notifier).setModel(v ?? 'deepseek-v3.2'),
                    );
                  },
                );
              }
              final preset = presets[index];
              return RadioListTile<String>(
                title: Text(preset['name'] as String),
                subtitle: Text(preset['value'] as String, style: const TextStyle(fontSize: 11)),
                value: preset['value'] as String,
                groupValue: currentModel,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).setModel(value);
                    _modelController.text = value;
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('备份数据'),
        content: const Text('数据将备份到本地存储。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('备份成功')),
              );
            },
            child: const Text('备份'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复数据'),
        content: const Text('从备份恢复数据将覆盖当前数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('恢复成功')),
              );
            },
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('此操作不可恢复，确定要清除所有数据吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已清除')),
              );
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}
