import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:studyflow/config/api_keys.dart';
import 'package:studyflow/services/memory_service.dart';
import 'package:studyflow/services/web_search_service.dart';
import 'package:uuid/uuid.dart';

class AIService {
  final Dio _dio = Dio();
  String? _apiKey = kBuiltInApiKey.isEmpty ? null : kBuiltInApiKey;
  String? _baseUrl = kBuiltInBaseUrl.isEmpty ? null : kBuiltInBaseUrl;
  String _model = kBuiltInModel;
  final MemoryService _memoryService = MemoryService();
  final WebSearchService _webSearchService = WebSearchService();
  bool _webSearchEnabled = false;

  AIService() {
    // 初始化时同时赋值给记忆服务
    _memoryService.configure(apiKey: _apiKey);
  }

  MemoryService get memoryService => _memoryService;

  WebSearchService get webSearchService => _webSearchService;

  bool get webSearchEnabled => _webSearchEnabled;

  void configure({
    String? apiKey,
    String? baseUrl,
    String? model,
    bool? webSearchEnabled,
    String? searchApiKey,
    String? searchProvider,
  }) {
    // 只有外部传了新的且不为空的 key，才替换掉写死的 key
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      _apiKey = apiKey;
    }
    _baseUrl = baseUrl;
    if (model != null) _model = model;

    // 同步配置记忆服务，保证用的都是同一个 apiKey
    _memoryService.configure(
      apiKey: _apiKey,
      baseUrl: baseUrl,
    );

    // 同步配置联网搜索
    if (webSearchEnabled != null) _webSearchEnabled = webSearchEnabled;
    if (searchApiKey != null && searchApiKey.trim().isNotEmpty) {
      _webSearchService.configure(apiKey: searchApiKey);
    }
    if (searchProvider != null) {
      SearchProvider provider;
      switch (searchProvider) {
        case 'bing':
          provider = SearchProvider.bing;
          break;
        case 'custom':
          provider = SearchProvider.custom;
          break;
        default:
          provider = SearchProvider.tavily;
      }
      _webSearchService.configure(provider: provider);
    }
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  Future<String> sendMessage(String message,
      {List<Map<String, String>>? history,
      bool useMemory = true,
      bool useWebSearch = true}) async {
    if (!isConfigured) {
      throw Exception('API Key 未配置，请在设置中配置 API Key');
    }

    // 构建系统提示
    String systemPrompt = '''你是一个学习助手，帮助用户制定学习计划、解答学习问题、提供学习方法建议。
请用简洁友好的方式回答问题。回答使用中文。

你具有记忆能力，可以记住用户之前告诉你的信息，包括学习偏好、目标、习惯等。''';

    // 如果启用记忆，检索相关记忆并注入上下文
    if (useMemory) {
      try {
        final memoryContext = await _memoryService.buildMemoryContext(message);
        if (memoryContext.isNotEmpty) {
          systemPrompt = '$systemPrompt\n\n$memoryContext';
        }
      } catch (e) {
        // 记忆检索失败不影响主流程
      }
    }

    // 如果启用联网搜索，搜索相关信息并注入上下文
    if (useWebSearch && _webSearchEnabled && _webSearchService.isConfigured) {
      try {
        final searchContext =
            await _webSearchService.buildSearchContext(message);
        if (searchContext.isNotEmpty) {
          systemPrompt = '$systemPrompt\n\n$searchContext';
        }
      } catch (e) {
        // 搜索失败不影响主流程
      }
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': systemPrompt,
      },
      ...(history ?? []),
      {'role': 'user', 'content': message},
    ];

    try {
      // 构建完整的 API URL
      String apiUrl;
      if (_baseUrl != null && _baseUrl!.trim().isNotEmpty) {
        final base = _baseUrl!.endsWith('/')
            ? _baseUrl!.substring(0, _baseUrl!.length - 1)
            : _baseUrl!;
        if (base.contains('/v3') ||
            base.contains('/v4') ||
            base.contains('/v1')) {
          apiUrl = '$base/chat/completions';
        } else {
          apiUrl = '$base/v1/chat/completions';
        }
      } else {
        // 强制使用指定的 coding 大模型地址
        apiUrl =
            'https://ark.cn-beijing.volces.com/api/coding/v3/chat/completions';
      }

      final response = await _dio.post(
        apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'messages': messages,
          'max_tokens': 2000,
        },
      );

      final reply = response.data['choices'][0]['message']['content'] as String;

      // 保存对话记忆
      if (useMemory) {
        await _saveConversationMemory(message, reply);
      }

      return reply;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('API Key 无效，请检查配置');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('API 地址错误或模型不存在，请检查 URL 和模型名称');
      }
      throw Exception('请求失败: ${e.message}');
    }
  }

  /// 流式发送消息，逐 token 返回
  Stream<String> sendMessageStream(String message,
      {List<Map<String, String>>? history,
      bool useMemory = true,
      bool useWebSearch = true}) {
    final controller = StreamController<String>();
    _doSendMessageStream(controller, message,
        history: history, useMemory: useMemory, useWebSearch: useWebSearch);
    return controller.stream;
  }

  Future<void> _doSendMessageStream(
    StreamController<String> controller,
    String message, {
    List<Map<String, String>>? history,
    bool useMemory = true,
    bool useWebSearch = true,
  }) async {
    if (!isConfigured) {
      controller.addError(Exception('API Key 未配置，请在设置中配置 API Key'));
      await controller.close();
      return;
    }

    // 构建系统提示
    String systemPrompt = '''你是一个学习助手，帮助用户制定学习计划、解答学习问题、提供学习方法建议。
请用简洁友好的方式回答问题。回答使用中文。

你具有记忆能力，可以记住用户之前告诉你的信息，包括学习偏好、目标、习惯等。''';

    // 如果启用记忆，检索相关记忆并注入上下文
    if (useMemory) {
      try {
        final memoryContext = await _memoryService.buildMemoryContext(message);
        if (memoryContext.isNotEmpty) {
          systemPrompt = '$systemPrompt\n\n$memoryContext';
        }
      } catch (e) {
        // 记忆检索失败不影响主流程
      }
    }

    // 如果启用联网搜索，搜索相关信息并注入上下文
    if (useWebSearch && _webSearchEnabled && _webSearchService.isConfigured) {
      try {
        final searchContext =
            await _webSearchService.buildSearchContext(message);
        if (searchContext.isNotEmpty) {
          systemPrompt = '$systemPrompt\n\n$searchContext';
        }
      } catch (e) {
        // 搜索失败不影响主流程
      }
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...(history ?? []),
      {'role': 'user', 'content': message},
    ];

    try {
      // 构建完整的 API URL
      String apiUrl;
      if (_baseUrl != null && _baseUrl!.trim().isNotEmpty) {
        final base = _baseUrl!.endsWith('/')
            ? _baseUrl!.substring(0, _baseUrl!.length - 1)
            : _baseUrl!;
        if (base.contains('/v3') ||
            base.contains('/v4') ||
            base.contains('/v1')) {
          apiUrl = '$base/chat/completions';
        } else {
          apiUrl = '$base/v1/chat/completions';
        }
      } else {
        apiUrl =
            'https://ark.cn-beijing.volces.com/api/coding/v3/chat/completions';
      }

      final response = await _dio.post(
        apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'model': _model,
          'messages': messages,
          'max_tokens': 2000,
          'stream': true,
        },
      );

      final responseBody = response.data as ResponseBody;
      String buffer = '';
      String fullContent = '';

      await for (final chunk in responseBody.stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);

        // 处理完整的 SSE 行
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.isEmpty || !line.startsWith('data: ')) continue;

          final data = line.substring(6); // 去掉 "data: " 前缀

          if (data.trim() == '[DONE]') {
            buffer = '';
            break;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final content = json['choices']?[0]?['delta']?['content'];
            if (content is String && content.isNotEmpty) {
              fullContent += content;
              controller.add(content);
            }
          } catch (_) {
            // 跳过格式错误的数据块
          }
        }
      }

      // 流式输出结束后保存对话记忆
      if (useMemory && fullContent.isNotEmpty) {
        await _saveConversationMemory(message, fullContent);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        controller.addError(Exception('API Key 无效，请检查配置'));
      } else if (e.response?.statusCode == 404) {
        controller.addError(Exception('API 地址错误或模型不存在，请检查 URL 和模型名称'));
      } else {
        controller.addError(Exception('请求失败: ${e.message}'));
      }
    } catch (e) {
      controller.addError(e);
    } finally {
      await controller.close();
    }
  }

  /// 保存对话记忆
  Future<void> _saveConversationMemory(
      String userMessage, String aiReply) async {
    try {
      // 保存用户消息
      await _memoryService.addMemory(MemoryItem(
        id: const Uuid().v4(),
        content: '用户说: $userMessage',
        type: 'chat',
      ));

      // 保存 AI 回复（只保存关键信息）
      if (aiReply.length < 500) {
        await _memoryService.addMemory(MemoryItem(
          id: const Uuid().v4(),
          content: '助手回复: $aiReply',
          type: 'chat',
        ));
      }
    } catch (e) {
      // 保存记忆失败不影响主流程
    }
  }

  /// 手动添加记忆
  Future<void> addMemory(String content, {String type = 'note'}) async {
    await _memoryService.addMemory(MemoryItem(
      id: const Uuid().v4(),
      content: content,
      type: type,
    ));
  }

  /// 搜索记忆
  Future<List<MemoryItem>> searchMemories(String query, {int limit = 5}) async {
    return _memoryService.searchMemories(query, limit: limit);
  }

  Future<Map<String, dynamic>> generateStudyPlanWithStructure({
    required String examName,
    required DateTime examDate,
    required List<String> subjects,
    required int dailyHours,
    String? additionalInfo,
  }) async {
    if (!isConfigured) {
      throw Exception('API Key 未配置');
    }

    final daysRemaining = examDate.difference(DateTime.now()).inDays;
    final prompt = '''你是一名专业的备考学习规划师。请根据以下信息，制定一份细化到章节/知识点的可执行学习计划。

## 基本信息
- 目标考试：$examName
- 考试日期：${examDate.toString().split(' ')[0]}（距今还有 $daysRemaining 天）
- 每日可学习时间：$dailyHours 小时
- 需要复习的科目：${subjects.join('、')}
${additionalInfo != null ? '- 当前进度/补充说明：$additionalInfo' : ''}

## 计划要求
1. 必须细化到具体章节或知识板块，严禁只写"复习XX科目"这类宏观计划
2. 若提到了当前学习进度（如"已学完第X章/第X讲"），必须从下一章节开始安排，不重复已完成内容
3. targetMinutes 根据章节难度合理设定：一般章节 90～150 分钟，重点难点章节 150～300 分钟
4. deadline 按学习顺序和剩余时间均匀分配，格式 YYYY-MM-DD
5. 重难点/高频考点 priority 设为 high，一般章节设为 medium，拓展内容设为 low
6. 每个科目至少拆分 5 条计划，整体不少于 8 条，宁多勿少

## 返回格式
直接输出以下 JSON，不要任何额外说明文字，不要使用代码块围栏：
{"summary":"整体规划说明（2-3句话）","plans":[{"title":"科目-章节名（示例：高数-第九讲 多元函数微分学）","description":"本阶段具体学习目标（1-2句话）","subjectName":"科目","targetMinutes":180,"deadline":"YYYY-MM-DD","priority":"high"}]}''';

    final response = await sendMessage(prompt);
    var result = _parseJsonResponse(response);
    // 若 JSON 解析失败，把原始响应发回模型让其修复，再解析一次
    if ((result['plans'] as List).isEmpty) {
      final fixed = await _tryFixJson(response);
      if (fixed != null) result = _parseJsonResponse(fixed);
    }
    return result;
  }

  /// 三策略 JSON 解析：适配 AI 各种输出格式（代码块 / 纯 JSON / 混杂文本）
  Map<String, dynamic> _parseJsonResponse(String response) {
    try {
      Map<String, dynamic>? data;

      // 策略1：从 markdown 代码块 ```json ... ``` 中提取
      final jsonBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
      final match = jsonBlockRegex.firstMatch(response);
      if (match != null) {
        try {
          data = jsonDecode(match.group(1)!.trim()) as Map<String, dynamic>;
        } catch (_) {}
      }

      // 策略2：直接解析整个响应
      if (data == null) {
        try {
          data = jsonDecode(response.trim()) as Map<String, dynamic>;
        } catch (_) {}
      }

      // 策略3：括号匹配提取最外层 {}
      if (data == null) {
        final jsonStr = _extractJsonBlock(response);
        if (jsonStr != null) {
          try {
            data = jsonDecode(jsonStr) as Map<String, dynamic>;
          } catch (_) {}
        }
      }

      if (data == null) throw FormatException('无法解析 JSON');

      final plans = data['plans'];
      return {
        'summary': data['summary'] as String? ?? '',
        'plans': plans is List ? plans : <dynamic>[],
        'rawResponse': response,
      };
    } catch (_) {
      return {'summary': '', 'plans': <dynamic>[], 'rawResponse': response};
    }
  }

  /// 让模型自行判断对话是否为计划请求：是则提取结构化 JSON，否则返回 isPlan=false
  Future<Map<String, dynamic>> detectAndExtractPlans({
    required String userMessage,
    required String aiResponse,
  }) async {
    if (!isConfigured) {
      return {
        'isPlan': false,
        'summary': '',
        'plans': <dynamic>[],
        'rawResponse': ''
      };
    }

    final prompt = '''分析下面的对话，判断用户是否在请求制定学习/复习/备考计划。

【用户消息】
$userMessage

【AI回复】
$aiResponse

---
判断标准：
- 是计划请求：用户要求制定学习计划、复习安排、备考规划、学习路线等
- 不是计划请求：用户在问知识点、解题技巧、概念解释或其他非规划类问题

如果是计划请求，提取具体学习计划条目（必须细化到章节/知识点，若提到当前进度则从下一章开始），直接输出以下 JSON（不要代码块围栏，不要任何额外文字）：
{"summary":"整体说明","plans":[{"title":"科目-章节名","description":"具体学习目标","subjectName":"科目","targetMinutes":180,"deadline":"YYYY-MM-DD","priority":"high"}]}

如果不是计划请求，只输出：NO''';

    final response = await sendMessage(prompt, useMemory: false);
    final trimmed = response.trim();

    // 模型判断为非计划请求
    if (trimmed.toUpperCase() == 'NO' || trimmed == '"NO"') {
      return {
        'isPlan': false,
        'summary': '',
        'plans': <dynamic>[],
        'rawResponse': ''
      };
    }

    // 尝试解析 JSON
    var result = _parseJsonResponse(trimmed);

    // 解析仍失败：把模型原始输出发回去让它自己修复
    if ((result['plans'] as List).isEmpty) {
      final fixed = await _tryFixJson(trimmed);
      if (fixed != null) result = _parseJsonResponse(fixed);
    }

    return {...result, 'isPlan': true};
  }

  /// 将格式错误的 JSON 发回模型修复，返回修复后的字符串（失败返回 null）
  Future<String?> _tryFixJson(String brokenJson) async {
    if (!isConfigured) return null;
    try {
      final prompt =
          '以下 JSON 格式有误，请修复并只输出修正后的 JSON，不要其他任何内容，不要代码块围栏：\n\n$brokenJson';
      final response = await sendMessage(prompt, useMemory: false);
      final t = response.trim();
      return t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }

  /// 从文本中提取 JSON 块，使用大括号匹配确保提取完整
  String? _extractJsonBlock(String text) {
    final startIndex = text.indexOf('{');
    if (startIndex == -1) return null;

    // 使用括号匹配找到与第一个 { 对应的 }
    int depth = 0;
    bool inString = false;
    String? stringChar;

    for (int i = startIndex; i < text.length; i++) {
      final char = text[i];

      if (inString) {
        if (char == '\\') {
          i++; // 跳过转义字符
          continue;
        }
        if (char == stringChar) {
          inString = false;
          stringChar = null;
        }
        continue;
      }

      if (char == '"' || char == "'") {
        inString = true;
        stringChar = char;
        continue;
      }

      if (char == '{' || char == '[') {
        depth++;
      } else if (char == '}' || char == ']') {
        depth--;
        if (depth == 0) {
          // 找到匹配的闭合括号
          String jsonStr = text.substring(startIndex, i + 1);
          // 清理：修复尾部逗号
          jsonStr = jsonStr.replaceAll(RegExp(r',\s*}'), '}');
          jsonStr = jsonStr.replaceAll(RegExp(r',\s*]'), ']');
          return jsonStr;
        }
      }
    }

    // 未找到匹配的闭合括号，回退到简单提取
    final endIndex = text.lastIndexOf('}');
    if (endIndex > startIndex) {
      String jsonStr = text.substring(startIndex, endIndex + 1);
      jsonStr = jsonStr.replaceAll(RegExp(r',\s*}'), '}');
      jsonStr = jsonStr.replaceAll(RegExp(r',\s*]'), ']');
      return jsonStr;
    }

    return null;
  }

  Future<String> generateStudyPlan({
    required String examName,
    required DateTime examDate,
    required List<String> subjects,
    required int dailyHours,
    String? additionalInfo,
  }) async {
    if (!isConfigured) {
      throw Exception('API Key 未配置');
    }

    final daysRemaining = examDate.difference(DateTime.now()).inDays;
    final prompt = '''请帮我制定一个学习计划：

考试名称：$examName
考试日期：${examDate.toString().split(' ')[0]}（还有 $daysRemaining 天）
需要复习的科目：${subjects.join('、')}
每天可用学习时间：$dailyHours 小时
${additionalInfo != null ? '补充信息：$additionalInfo' : ''}

请生成详细的学习计划，包括：
1. 每日学习安排（科目、时长）
2. 复习重点建议
3. 时间分配建议

请用清晰的格式输出，使用中文。''';

    return sendMessage(prompt);
  }

  Future<String> analyzeStudyData({
    required int totalMinutesToday,
    required int totalMinutesWeek,
    required Map<String, int> subjectDistribution,
    required List<int> dailyMinutes,
  }) async {
    if (!isConfigured) {
      throw Exception('API Key 未配置');
    }

    final prompt = '''请分析我的学习数据并给出建议：

今日学习时长：${totalMinutesToday ~/ 60} 小时 ${totalMinutesToday % 60} 分钟
本周学习时长：${totalMinutesWeek ~/ 60} 小时 ${totalMinutesWeek % 60} 分钟

科目时间分布：
${subjectDistribution.entries.map((e) => '- ${e.key}: ${e.value ~/ 60}小时${e.value % 60}分钟').join('\n')}

最近7天每日学习时长（分钟）：${dailyMinutes.join(', ')}

请分析：
1. 学习效率评估
2. 时间分配是否合理
3. 改进建议

用简洁友好的方式回答，使用中文。''';

    return sendMessage(prompt);
  }

  Future<String> chat(String message) => sendMessage(message);

  /// 流式对话简写
  Stream<String> chatStream(String message) => sendMessageStream(message);
}
