import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:studyflow/services/ai_service.dart';
import 'package:studyflow/services/memory_service.dart';
import 'package:studyflow/screens/settings_screen.dart';
import 'package:studyflow/screens/plans_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final settings = ref.watch(settingsProvider);
  final service = AIService();
  service.configure(
    apiKey: settings.openaiApiKey,
    baseUrl: settings.openaiBaseUrl,
    model: settings.openaiModel,
    webSearchEnabled: settings.webSearchEnabled,
    searchApiKey: settings.searchApiKey,
    searchProvider: settings.searchProvider,
  );
  return service;
});

final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);

class AIScreen extends ConsumerStatefulWidget {
  const AIScreen({super.key});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final memoriesJson = prefs.getString('ai_memories');
    if (memoriesJson != null) {
      final aiService = ref.read(aiServiceProvider);
      final memories = jsonDecode(memoriesJson) as List;
      aiService.memoryService.importMemories(
        memories.map((e) => e as Map<String, dynamic>).toList(),
      );
    }
  }

  Future<void> _saveMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final aiService = ref.read(aiServiceProvider);
    final memories = aiService.memoryService.exportMemories();
    await prefs.setString('ai_memories', jsonEncode(memories));
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 助手'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.travel_explore,
              color: settings.webSearchEnabled
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: settings.webSearchEnabled ? '联网搜索已开启' : '联网搜索已关闭',
            onPressed: () {
              final willEnable = !settings.webSearchEnabled;
              ref
                  .read(settingsProvider.notifier)
                  .setWebSearchEnabled(willEnable);
              if (willEnable &&
                  (settings.searchApiKey == null ||
                      settings.searchApiKey!.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('联网搜索需要配置搜索 API Key，请在设置→联网搜索中填写'),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: '记忆管理',
            onPressed: () => _showMemoryPanel(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).state = [];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty)
            _buildApiKeyWarning()
          else
            Expanded(
              child: messages.isEmpty
                  ? _buildQuickActions()
                  : _buildChatList(messages),
            ),
          if (settings.webSearchEnabled &&
              settings.openaiApiKey != null &&
              settings.openaiApiKey!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: (settings.searchApiKey != null &&
                      settings.searchApiKey!.isNotEmpty)
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3)
                  : Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.3),
              child: Row(
                children: [
                  Icon(Icons.travel_explore,
                      size: 14,
                      color: (settings.searchApiKey != null &&
                              settings.searchApiKey!.isNotEmpty)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error),
                  const SizedBox(width: 4),
                  (settings.searchApiKey != null &&
                          settings.searchApiKey!.isNotEmpty)
                      ? Text('联网搜索已开启 · AI 将先搜索网络再回答',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary))
                      : Text('联网搜索未生效 · 请先在设置中配置搜索 API Key',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error)),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildApiKeyWarning() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('请先在设置中配置 OpenAI API Key'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: const Text('前往设置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('AI 学习助手',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickActionChip(
                  icon: Icons.calendar_month,
                  label: '生成学习计划',
                  onTap: () => _showPlanGenerator(),
                ),
                _QuickActionChip(
                  icon: Icons.analytics,
                  label: '学习分析',
                  onTap: () => _analyzeStudyData(),
                ),
                _QuickActionChip(
                  icon: Icons.lightbulb,
                  label: '学习方法建议',
                  onTap: () => _sendMessage('请给我一些高效学习的方法建议'),
                ),
                _QuickActionChip(
                  icon: Icons.psychology,
                  label: '记忆技巧',
                  onTap: () => _sendMessage('请介绍一些有效的记忆技巧'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<ChatMessage> messages) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _ChatBubble(message: message);
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '输入问题...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isLoading ? null : _send,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    await _streamChatResponse(userDisplayText: text, aiPrompt: text);
  }

  /// 流式发送 AI 请求并实时更新聊天气泡
  Future<void> _streamChatResponse({
    required String userDisplayText,
    required String aiPrompt,
  }) async {
    final aiService = ref.read(aiServiceProvider);
    if (!aiService.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先配置 API Key')),
        );
      }
      return;
    }

    // 添加用户消息
    ref.read(chatMessagesProvider.notifier).update((state) => [
          ...state,
          ChatMessage(content: userDisplayText, isUser: true),
        ]);

    // 创建占位 AI 消息并记录其 ID，后续用 ID 定位更新，避免多消息并发时用 state.last 串位
    // 如果联网搜索已开启且已配置，在占位消息中显示搜索状态
    final searchSettings = ref.read(settingsProvider);
    final isSearchActive = searchSettings.webSearchEnabled &&
        aiService.webSearchService.isConfigured;
    final placeholder = ChatMessage(
      content: isSearchActive ? '🔍 正在搜索网络...' : '',
      isUser: false,
    );
    ref
        .read(chatMessagesProvider.notifier)
        .update((state) => [...state, placeholder]);

    setState(() => _isLoading = true);

    String fullContent = '';
    try {
      await for (final token in aiService.chatStream(aiPrompt)) {
        fullContent += token;
        // 按 ID 更新 AI 消息，比 state.last 更安全
        ref.read(chatMessagesProvider.notifier).update((state) => state
            .map((m) => m.id == placeholder.id
                ? ChatMessage(
                    id: placeholder.id, content: fullContent, isUser: false)
                : m)
            .toList());
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
      await _saveMemories();

      // 每条回复都交由模型自行判断是否为计划请求，比关键词匹配更准确
      if (fullContent.isNotEmpty) {
        _tryExtractAndAttachPlans(
          userMessage: userDisplayText,
          aiResponse: fullContent,
          messageId: placeholder.id,
        );
      }
    } catch (e) {
      ref.read(chatMessagesProvider.notifier).update((state) => state.map((m) {
            if (m.id == placeholder.id) {
              return ChatMessage(
                id: placeholder.id,
                content: fullContent.isEmpty
                    ? '错误: $e'
                    : '$fullContent\n\n---\n⚠️ 请求中断: $e',
                isUser: false,
              );
            }
            return m;
          }).toList());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 在后台让模型判断是否为计划请求，并提取结构化计划附加到指定消息（静默执行，不阻塞 UI）
  Future<void> _tryExtractAndAttachPlans({
    required String userMessage,
    required String aiResponse,
    required String messageId,
  }) async {
    try {
      final aiService = ref.read(aiServiceProvider);
      // 把用户消息 + AI 回复一起发给模型，让它判断是否为计划请求并提取 JSON
      final result = await aiService.detectAndExtractPlans(
        userMessage: userMessage,
        aiResponse: aiResponse,
      );

      // 模型判断不是计划请求，静默退出
      final isPlan = result['isPlan'] as bool? ?? false;
      if (!isPlan || !mounted) return;

      final plansList = result['plans'] as List<dynamic>? ?? [];
      if (plansList.isEmpty || !mounted) return;

      final suggestions = plansList.map((p) {
        final map = p as Map<String, dynamic>;
        int targetMinutes = 120;
        final tv = map['targetMinutes'];
        if (tv is int)
          targetMinutes = tv;
        else if (tv is String)
          targetMinutes = int.tryParse(tv) ?? 120;
        else if (tv is double) targetMinutes = tv.toInt();

        DateTime? deadline;
        final dv = map['deadline'];
        if (dv is String) deadline = DateTime.tryParse(dv);

        return AIPlanSuggestion(
          title: map['title'] as String? ?? '未命名计划',
          description: map['description'] as String?,
          subjectName: map['subjectName'] as String? ?? '未分类',
          targetMinutes: targetMinutes,
          deadline: deadline,
          priority: map['priority'] as String? ?? 'medium',
        );
      }).toList();

      if (suggestions.isEmpty || !mounted) return;

      // 按 ID 找到对应 AI 消息，追加提示文字和计划建议
      ref.read(chatMessagesProvider.notifier).update((state) => state.map((m) {
            if (m.id == messageId && !m.isUser) {
              return ChatMessage(
                id: m.id,
                content:
                    '${m.content.trimRight()}\n\n---\n💡 已为你生成 ${suggestions.length} 个学习计划，点击下方按钮可一键导入。',
                isUser: false,
                planSuggestions: suggestions,
              );
            }
            return m;
          }).toList());

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } catch (_) {
      // 静默失败，不影响用户体验
    }
  }

  void _showPlanGenerator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PlanGeneratorSheet(
        onGenerate: _handleGeneratePlan,
      ),
    );
  }

  /// 在父组件中执行 AI 计划生成（ref 始终有效，因为 AIScreen 始终挂载）
  Future<void> _handleGeneratePlan({
    required String examName,
    required DateTime examDate,
    required List<String> subjects,
    required int dailyHours,
    String? additionalInfo,
  }) async {
    final aiService = ref.read(aiServiceProvider);
    if (!aiService.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先配置 API Key')),
        );
      }
      return;
    }

    // 构建完整的用户消息显示
    final daysRemaining = examDate.difference(DateTime.now()).inDays;
    final userContent = '''📅 生成学习计划
• 目标：$examName
• 截止日期：${examDate.toString().split(' ')[0]}（还有 $daysRemaining 天）
• 科目：${subjects.join('、')}
• 每日学习时间：$dailyHours 小时
${additionalInfo != null && additionalInfo.isNotEmpty ? '• 补充：$additionalInfo' : ''}''';

    final userMessage = ChatMessage(
      content: userContent,
      isUser: true,
    );
    ref
        .read(chatMessagesProvider.notifier)
        .update((state) => [...state, userMessage]);

    // 添加加载占位消息
    final loadingMessage = ChatMessage(
      content: '⏳ 正在搜索课程信息并生成学习计划，请稍候...',
      isUser: false,
    );
    ref
        .read(chatMessagesProvider.notifier)
        .update((state) => [...state, loadingMessage]);

    setState(() => _isLoading = true);

    try {
      final response = await aiService.generateStudyPlanWithStructure(
        examName: examName,
        examDate: examDate,
        subjects: subjects,
        dailyHours: dailyHours,
        additionalInfo: additionalInfo,
      );

      // 解析计划建议
      final plans = (response['plans'] as List?)?.map((p) {
        final map = p as Map<String, dynamic>;
        int targetMinutes = 60;
        final targetMinutesValue = map['targetMinutes'];
        if (targetMinutesValue is int) {
          targetMinutes = targetMinutesValue;
        } else if (targetMinutesValue is String) {
          targetMinutes = int.tryParse(targetMinutesValue) ?? 60;
        } else if (targetMinutesValue is double) {
          targetMinutes = targetMinutesValue.toInt();
        }

        DateTime? deadline;
        final deadlineValue = map['deadline'];
        if (deadlineValue is String) {
          deadline = DateTime.tryParse(deadlineValue);
        }

        return AIPlanSuggestion(
          title: map['title'] as String? ?? '未命名计划',
          description: map['description'] as String?,
          subjectName: map['subjectName'] as String? ?? '未分类',
          targetMinutes: targetMinutes,
          deadline: deadline,
          priority: map['priority'] as String? ?? 'medium',
        );
      }).toList();

      final summary = response['summary'] as String? ?? '';
      final rawResponse = response['rawResponse'] as String? ?? '';

      // 构建显示内容
      String displayContent = '';
      if (summary.isNotEmpty) {
        displayContent = summary;
        if (plans != null && plans.isNotEmpty) {
          displayContent += '\n\n已生成 ${plans.length} 个学习计划，点击下方按钮导入。';
        }
      } else {
        displayContent = rawResponse;
      }

      final aiMessage = ChatMessage(
        id: loadingMessage.id, // 复用加载消息的 ID，替换它
        content: displayContent,
        isUser: false,
        planSuggestions: plans,
      );
      ref.read(chatMessagesProvider.notifier).update((state) =>
          state.map((m) => m.id == loadingMessage.id ? aiMessage : m).toList());
      await _saveMemories();
    } catch (e) {
      print('[AIScreen] _handleGeneratePlan 错误: $e');
      // 显示更详细的错误信息，替换加载消息
      String errorText = '生成计划时发生错误';
      if (e.toString().contains('超时')) {
        errorText = '⏱️ 请求超时，请检查网络连接后重试';
      } else if (e.toString().contains('API Key')) {
        errorText = '🔑 API Key 配置有误，请检查设置';
      } else if (e.toString().contains('参数错误')) {
        errorText = '📝 请求参数错误，可能是内容过长，请简化后重试';
      } else {
        errorText = '❌ 错误: $e';
      }
      final errorMessage = ChatMessage(content: errorText, isUser: false);
      ref.read(chatMessagesProvider.notifier).update((state) => state
          .map((m) => m.id == loadingMessage.id ? errorMessage : m)
          .toList());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _analyzeStudyData() async {
    final now = DateTime.now();
    final todayMinutes =
        ref.read(sessionsProvider.notifier).getTotalMinutesForDate(now);

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int weekMinutes = 0;
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      weekMinutes +=
          ref.read(sessionsProvider.notifier).getTotalMinutesForDate(date);
    }

    final distribution =
        ref.read(sessionsProvider.notifier).getSubjectDistributionForDate(now);
    final dailyMinutes = <int>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dailyMinutes.add(
          ref.read(sessionsProvider.notifier).getTotalMinutesForDate(date));
    }

    final prompt = '请分析我的学习数据并给出建议：\n\n'
        '今日学习时长：${todayMinutes ~/ 60} 小时 ${todayMinutes % 60} 分钟\n'
        '本周学习时长：${weekMinutes ~/ 60} 小时 ${weekMinutes % 60} 分钟\n\n'
        '科目时间分布：\n'
        '${distribution.entries.map((e) => '- ${e.key}: ${e.value ~/ 60}小时${e.value % 60}分钟').join('\n')}\n\n'
        '最近7天每日学习时长（分钟）：${dailyMinutes.join(', ')}\n\n'
        '请分析：\n1. 学习效率评估\n2. 时间分配是否合理\n3. 改进建议\n\n用简洁友好的方式回答，使用中文。';

    await _streamChatResponse(
      userDisplayText: '请分析我的学习数据',
      aiPrompt: prompt,
    );
  }

  void _showMemoryPanel() {
    final aiService = ref.read(aiServiceProvider);
    final memories = aiService.memoryService.memories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('记忆管理', style: Theme.of(context).textTheme.titleLarge),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('添加笔记'),
                        onPressed: () => _showAddNoteDialog(() {
                          setModalState(() {});
                        }),
                      ),
                      TextButton(
                        onPressed: () {
                          aiService.memoryService.clearMemories();
                          _saveMemories();
                          setModalState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('记忆已清除')),
                          );
                        },
                        child: const Text('清除全部',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              Text('共 ${memories.length} 条记忆',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Expanded(
                child: memories.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.psychology_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('还没有记忆', style: TextStyle(color: Colors.grey)),
                            SizedBox(height: 8),
                            Text('AI 会自动记住对话中的重要信息',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: memories.length,
                        itemBuilder: (context, index) {
                          final memory = memories[memories.length - 1 - index];
                          return _MemoryCard(
                            memory: memory,
                            onDelete: () {
                              // 由于 MemoryService 没有删除单个的方法，暂时跳过
                              setModalState(() {});
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog(VoidCallback onAdded) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加记忆笔记'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入想要 AI 记住的信息...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final aiService = ref.read(aiServiceProvider);
                await aiService.addMemory(controller.text, type: 'note');
                await _saveMemories();
                Navigator.pop(context);
                onAdded();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('记忆已添加')),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      // 使用 ElevatedButton 或 OutlinedButton 更大更容易点击且有明显反馈
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ChatBubble extends ConsumerWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            message.isUser
                ? Text(
                    message.content,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : MarkdownBody(
                    data: message.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                      p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
            // 如果有计划建议，显示导入按钮
            if (message.planSuggestions != null &&
                message.planSuggestions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.assignment_add,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'AI 生成了 ${message.planSuggestions!.length} 个计划',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _importPlans(context, ref),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('导入全部计划'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _importPlans(BuildContext context, WidgetRef ref) {
    final subjects = ref.read(subjectsProvider);
    final plans = message.planSuggestions!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入计划'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return ListTile(
                leading: const Icon(Icons.assignment),
                title: Text(plan.title),
                subtitle: Text('${plan.subjectName} · ${plan.targetMinutes}分钟'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doImport(context, ref, subjects, plans);
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _doImport(BuildContext context, WidgetRef ref, List<Subject> subjects,
      List<AIPlanSuggestion> plans) async {
    int imported = 0;
    int createdSubjects = 0;
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    int colorIndex = 0;

    // 获取最新的科目列表
    List<Subject> currentSubjects = List.from(ref.read(subjectsProvider));

    for (final plan in plans) {
      // 查找匹配的科目（精确匹配或模糊匹配）
      Subject? subject;

      // 1. 先尝试精确匹配
      subject =
          currentSubjects.where((s) => s.name == plan.subjectName).firstOrNull;

      // 2. 如果没有精确匹配，尝试模糊匹配（包含关系）
      if (subject == null) {
        subject = currentSubjects
            .where((s) =>
                s.name.contains(plan.subjectName) ||
                plan.subjectName.contains(s.name))
            .firstOrNull;
      }

      // 3. 如果还是没有，创建新科目
      if (subject == null) {
        final newSubject = Subject(
          name: plan.subjectName,
          color: colors[colorIndex % colors.length].value.toString(),
        );
        colorIndex++;
        await ref.read(subjectsProvider.notifier).addSubject(newSubject);
        // 重新获取科目列表以获取新添加的科目
        currentSubjects = ref.read(subjectsProvider);
        subject = currentSubjects
                .where((s) => s.name == plan.subjectName)
                .firstOrNull ??
            newSubject;
        createdSubjects++;
      }

      // 创建计划
      final priority = plan.priority == 'high'
          ? PlanPriority.high
          : plan.priority == 'low'
              ? PlanPriority.low
              : PlanPriority.medium;

      await ref.read(plansProvider.notifier).addPlan(
            StudyPlan(
              title: plan.title,
              description: plan.description,
              subjectId: subject.id,
              subjectName: subject.name,
              targetMinutes: plan.targetMinutes,
              deadline: plan.deadline,
              priority: priority,
            ),
          );
      imported++;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '成功导入 $imported 个计划${createdSubjects > 0 ? "，创建了 $createdSubjects 个新科目" : ""}'),
          action: SnackBarAction(
            label: '查看',
            onPressed: () {
              // 跳转到计划页面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlansScreen()),
              );
            },
          ),
        ),
      );
    }
  }
}

class _PlanGeneratorSheet extends ConsumerStatefulWidget {
  final Future<void> Function({
    required String examName,
    required DateTime examDate,
    required List<String> subjects,
    required int dailyHours,
    String? additionalInfo,
  }) onGenerate;

  const _PlanGeneratorSheet({required this.onGenerate});

  @override
  ConsumerState<_PlanGeneratorSheet> createState() =>
      _PlanGeneratorSheetState();
}

class _PlanGeneratorSheetState extends ConsumerState<_PlanGeneratorSheet> {
  final _examController = TextEditingController();
  final _subjectsController = TextEditingController();
  final _infoController = TextEditingController();
  DateTime _examDate = DateTime.now().add(const Duration(days: 30));
  int _dailyHours = 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('生成学习计划', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _examController,
              decoration: const InputDecoration(
                labelText: '考试名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('考试日期'),
              subtitle: Text(
                '${_examDate.year}/${_examDate.month}/${_examDate.day}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _examDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _examDate = date);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectsController,
              decoration: const InputDecoration(
                labelText: '需要复习的科目（用逗号分隔）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('每天可用学习时间: '),
                Expanded(
                  child: Slider(
                    value: _dailyHours.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: '$_dailyHours 小时',
                    onChanged: (value) {
                      setState(() => _dailyHours = value.round());
                    },
                  ),
                ),
                Text('$_dailyHours 小时'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _infoController,
              decoration: const InputDecoration(
                labelText: '补充信息（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generate,
                child: const Text('生成计划'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    // 表单验证（此时 BottomSheet 仍然挂载，ref 和 context 均有效）
    if (_examController.text.isEmpty || _subjectsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写考试名称和科目')),
      );
      return;
    }

    final aiService = ref.read(aiServiceProvider);
    if (!aiService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置 API Key')),
      );
      return;
    }

    // ★ 关键：在关闭 BottomSheet 前捕获所有表单值
    // （关闭后 TextEditingController 和 State 均被 dispose，不可再访问）
    final examName = _examController.text;
    final examDate = _examDate;
    final subjectsList = _subjectsController.text
        .split(RegExp(r'[，,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final dailyHours = _dailyHours;
    final additionalInfo =
        _infoController.text.isEmpty ? null : _infoController.text;

    // 捕获回调引用（避免 dispose 后访问 widget）
    final onGenerate = widget.onGenerate;

    // 关闭 BottomSheet —— 此后 _PlanGeneratorSheet 被 dispose，ref 失效
    Navigator.pop(context);

    // ★ 通过父组件回调执行 AI 调用，使用父组件 AIScreen 的 ref（始终有效）
    await onGenerate(
      examName: examName,
      examDate: examDate,
      subjects: subjectsList,
      dailyHours: dailyHours,
      additionalInfo: additionalInfo,
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final MemoryItem memory;
  final VoidCallback onDelete;

  const _MemoryCard({
    required this.memory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          _getTypeIcon(memory.type),
          color: _getTypeColor(memory.type),
        ),
        title: Text(
          memory.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(memory.createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'plan':
        return Icons.assignment_outlined;
      case 'session':
        return Icons.timer_outlined;
      case 'note':
        return Icons.note_outlined;
      default:
        return Icons.memory;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'chat':
        return Colors.blue;
      case 'plan':
        return Colors.orange;
      case 'session':
        return Colors.green;
      case 'note':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';

    return '${date.month}/${date.day}';
  }
}
