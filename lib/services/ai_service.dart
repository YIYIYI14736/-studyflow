import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:studyflow/config/api_keys.dart';
import 'package:studyflow/services/memory_service.dart';
import 'package:studyflow/services/web_search_service.dart';
import 'package:uuid/uuid.dart';

/// DeepSeek AI 服务
///
/// 基于 DeepSeek OpenAI 兼容接口: https://api.deepseek.com
/// 支持模型: deepseek-chat, deepseek-reasoner
class AIService {
  final Dio _dio = Dio();
  String? _apiKey = kBuiltInApiKey.isEmpty ? null : kBuiltInApiKey;
  String _baseUrl =
      kBuiltInBaseUrl.isEmpty ? 'https://api.deepseek.com' : kBuiltInBaseUrl;
  String _model = kBuiltInModel.isEmpty ? 'deepseek-v4-flash' : kBuiltInModel;
  final MemoryService _memoryService = MemoryService();
  final WebSearchService _webSearchService = WebSearchService();
  bool _webSearchEnabled = false;

  AIService();

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
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      _apiKey = apiKey;
    }
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _baseUrl = baseUrl;
    }
    if (model != null && model.trim().isNotEmpty) {
      _model = model;
    }

    if (webSearchEnabled != null) {
      _webSearchEnabled = webSearchEnabled;
    }
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

  String get _apiUrl => '$_baseUrl/chat/completions';

  Future<String> sendMessage(String message,
      {List<Map<String, String>>? history,
      bool useMemory = true,
      bool useWebSearch = true}) async {
    if (!isConfigured) {
      throw Exception('API Key 未配置，请在设置中配置 DeepSeek API Key');
    }

    final now = DateTime.now();
    final currentDateTime = '''当前时间信息：
- 今天是：${now.year}年${now.month}月${now.day}日（${_getWeekdayName(now.weekday)}）
- 当前时间：${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}''';

    String systemPrompt = '''你是一个专业的学习助手，帮助用户制定学习计划、解答学习问题、提供学习方法建议。
请用简洁友好的方式回答问题。回答使用中文。

$currentDateTime

你具有记忆能力，可以记住用户之前告诉你的信息，包括学习偏好、目标、习惯等。''';

    if (useMemory) {
      try {
        final memoryContext = await _memoryService.buildMemoryContext(message);
        if (memoryContext.isNotEmpty) {
          systemPrompt = '$systemPrompt\n\n$memoryContext';
        }
      } catch (_) {}
    }

    if (useWebSearch && _webSearchEnabled && _webSearchService.isConfigured) {
      try {
        final searchQuery = _extractSearchQuery(message);
        final searchContext =
            await _webSearchService.buildSearchContext(searchQuery);
        if (searchContext.isNotEmpty) {
          systemPrompt =
              '$systemPrompt\n\n${_truncateSearchContext(searchContext, 2000)}';
        }
      } catch (_) {}
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...(history ?? []),
      {'role': 'user', 'content': message},
    ];

    try {
      final response = await _dio.post(
        _apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json'
          },
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
        data: {'model': _model, 'messages': messages, 'max_tokens': 2000},
      );

      final reply = response.data['choices'][0]['message']['content'] as String;

      if (useMemory) {
        await _saveConversationMemory(message, reply);
      }

      return reply;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('请求超时，请检查网络连接或稍后重试');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('API Key 无效，请检查配置');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('API 地址错误或模型不存在');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('请求参数错误，可能是 prompt 过长');
      }
      throw Exception('请求失败: ${e.message}');
    } catch (e) {
      throw Exception('发生未知错误: $e');
    }
  }

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
      controller.addError(Exception('API Key 未配置，请在设置中配置 DeepSeek API Key'));
      await controller.close();
      return;
    }

    final now = DateTime.now();
    final currentDateTime = '''当前时间信息：
- 今天是：${now.year}年${now.month}月${now.day}日（${_getWeekdayName(now.weekday)}）
- 当前时间：${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}''';

    String systemPrompt = '''你是一个专业的学习助手，帮助用户制定学习计划、解答学习问题、提供学习方法建议。
请用简洁友好的方式回答问题。回答使用中文。

$currentDateTime

你具有记忆能力，可以记住用户之前告诉你的信息，包括学习偏好、目标、习惯等。''';

    if (useMemory) {
      try {
        final memoryContext = await _memoryService.buildMemoryContext(message);
        if (memoryContext.isNotEmpty) {
          systemPrompt = '$systemPrompt\n\n$memoryContext';
        }
      } catch (_) {}
    }

    if (useWebSearch && _webSearchEnabled && _webSearchService.isConfigured) {
      try {
        final searchContext = await _webSearchService
            .buildSearchContext(_extractSearchQuery(message));
        if (searchContext.isNotEmpty) {
          systemPrompt = '$systemPrompt\n\n$searchContext';
        }
      } catch (_) {}
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...(history ?? []),
      {'role': 'user', 'content': message},
    ];

    try {
      final response = await _dio.post(
        _apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json'
          },
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 30),
        ),
        data: {
          'model': _model,
          'messages': messages,
          'max_tokens': 2000,
          'stream': true
        },
      );

      final responseBody = response.data as ResponseBody;
      String buffer = '';
      String fullContent = '';
      var streamDone = false;

      await for (final chunk in responseBody.stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty || !line.startsWith('data: ')) {
            continue;
          }
          final data = line.substring(6);
          if (data.trim() == '[DONE]') {
            streamDone = true;
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
          } catch (_) {}
        }
        if (streamDone) {
          break;
        }
      }

      if (!streamDone &&
          buffer.trim().isNotEmpty &&
          buffer.trim().startsWith('data: ')) {
        final data = buffer.trim().substring(6);
        if (data.trim() != '[DONE]') {
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final content = json['choices']?[0]?['delta']?['content'];
            if (content is String && content.isNotEmpty) {
              fullContent += content;
              controller.add(content);
            }
          } catch (_) {}
        }
      }

      if (useMemory && fullContent.isNotEmpty) {
        unawaited(_saveConversationMemory(message, fullContent));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        controller.addError(Exception('API Key 无效，请检查配置'));
      } else if (e.response?.statusCode == 404) {
        controller.addError(Exception('API 地址错误或模型不存在'));
      } else {
        controller.addError(Exception('请求失败: ${e.message}'));
      }
    } catch (e) {
      controller.addError(e);
    } finally {
      await controller.close();
    }
  }

  Future<void> _saveConversationMemory(
      String userMessage, String aiReply) async {
    try {
      await _memoryService.addMemory(MemoryItem(
          id: const Uuid().v4(), content: '用户说: $userMessage', type: 'chat'));
      if (aiReply.length < 2000) {
        await _memoryService.addMemory(MemoryItem(
            id: const Uuid().v4(), content: '助手回复: $aiReply', type: 'chat'));
      }
    } catch (_) {}
  }

  Future<void> addMemory(String content, {String type = 'note'}) async {
    await _memoryService.addMemory(
        MemoryItem(id: const Uuid().v4(), content: content, type: type));
  }

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
    if (!isConfigured) throw Exception('API Key 未配置');

    String? courseSearchContext;
    if (_webSearchEnabled && _webSearchService.isConfigured) {
      try {
        final searchQueries = subjects.map((s) => '$s 课程大纲 知识点章节').toList();
        if (additionalInfo != null && additionalInfo.isNotEmpty) {
          searchQueries.add('$examName 备考计划 学习进度');
        }
        final allResults = <String>[];
        for (final query in searchQueries) {
          final result =
              await _webSearchService.searchAndFormat(query, maxResults: 3);
          if (result.isNotEmpty) {
            allResults.add(result);
          }
        }
        if (allResults.isNotEmpty) {
          courseSearchContext = allResults.join('\n\n');
          if (courseSearchContext.length > 3000) {
            courseSearchContext = courseSearchContext.substring(0, 3000);
          }
        }
      } catch (_) {}
    }

    final daysRemaining = examDate.difference(DateTime.now()).inDays;
    final prompt = '''你是一名专业的备考学习规划师。请根据以下信息，制定一份细化到章节/知识点的可执行学习计划。

## 基本信息
- 目标考试：$examName
- 考试日期：${examDate.toString().split(' ')[0]}（距今还有 $daysRemaining 天）
- 每日可学习时间：$dailyHours 小时
- 需要复习的科目：${subjects.join('、')}
${additionalInfo != null ? '- 当前进度/补充说明：$additionalInfo' : ''}

## 课程参考资料
${courseSearchContext ?? '（未获取到课程参考资料，请根据通用知识制定计划）'}

## 计划要求
1. 必须细化到具体章节或知识板块，严禁只写"复习XX科目"这类宏观计划
2. 若提到了当前学习进度，必须从下一章节开始安排
3. targetMinutes 根据章节难度合理设定：一般 90～150 分钟，重点难点 150～300 分钟
4. deadline 按学习顺序和剩余时间均匀分配，格式 YYYY-MM-DD
5. 重难点/高频考点 priority 设为 high，一般章节 medium，拓展 low
6. 每个科目至少 5 条计划，整体不少于 8 条

## 返回格式
直接输出以下 JSON，不要任何额外说明文字，不要使用代码块围栏：
{"summary":"整体规划说明（2-3句话）","plans":[{"title":"科目-章节名","description":"本阶段具体学习目标","subjectName":"科目","targetMinutes":180,"deadline":"YYYY-MM-DD","priority":"high"}]}''';

    final response = await sendMessage(prompt, useWebSearch: false);
    var result = _parseJsonResponse(response);
    if ((result['plans'] as List).isEmpty) {
      final fixed = await _tryFixJson(response);
      if (fixed != null) result = _parseJsonResponse(fixed);
    }
    return result;
  }

  Map<String, dynamic> _parseJsonResponse(String response) {
    try {
      Map<String, dynamic>? data;
      final jsonBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
      final match = jsonBlockRegex.firstMatch(response);
      if (match != null) {
        try {
          data = jsonDecode(match.group(1)!.trim()) as Map<String, dynamic>;
        } catch (_) {}
      }
      if (data == null) {
        try {
          data = jsonDecode(response.trim()) as Map<String, dynamic>;
        } catch (_) {}
      }
      if (data == null) {
        final jsonStr = _extractJsonBlock(response);
        if (jsonStr != null) {
          try {
            data = jsonDecode(jsonStr) as Map<String, dynamic>;
          } catch (_) {}
        }
      }
      if (data == null) throw FormatException('无法解析 JSON');
      return {
        'summary': data['summary'] as String? ?? '',
        'plans': data['plans'] is List ? data['plans'] : [],
        'rawResponse': response
      };
    } catch (_) {
      return {'summary': '', 'plans': [], 'rawResponse': response};
    }
  }

  Future<Map<String, dynamic>> detectAndExtractPlans(
      {required String userMessage, required String aiResponse}) async {
    if (!isConfigured) {
      return {'isPlan': false, 'summary': '', 'plans': [], 'rawResponse': ''};
    }

    final prompt = '''分析下面的对话，判断用户是否在请求制定学习/复习/备考计划。

【用户消息】
$userMessage

【AI回复】
$aiResponse

---
判断标准：
- 是计划请求：用户要求制定学习计划、复习安排、备考规划、学习路线
- 不是计划请求：用户在问知识点、解题技巧、概念解释

如果是计划请求，提取具体学习计划条目（必须细化到章节/知识点），直接输出以下 JSON（不要代码块围栏）：
{"summary":"整体说明","plans":[{"title":"科目-章节名","description":"具体学习目标","subjectName":"科目","targetMinutes":180,"deadline":"YYYY-MM-DD","priority":"high"}]}

如果不是计划请求，只输出：NO''';

    final response = await sendMessage(prompt, useMemory: false);
    final trimmed = response.trim();
    if (trimmed == 'NO' || trimmed == '"NO"') {
      return {'isPlan': false, 'summary': '', 'plans': [], 'rawResponse': ''};
    }
    var result = _parseJsonResponse(trimmed);
    if ((result['plans'] as List).isEmpty) {
      final fixed = await _tryFixJson(trimmed);
      if (fixed != null) result = _parseJsonResponse(fixed);
    }
    return {...result, 'isPlan': (result['plans'] as List).isNotEmpty};
  }

  String _getWeekdayName(int weekday) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${names[weekday - 1]}';
  }

  String _extractSearchQuery(String message) {
    if (message.length < 80) return message;
    final sentences = message.split(RegExp(r'[，。！？、；：\n]+'));
    final keySentences = <String>[];
    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;
      if (RegExp(r'\d').hasMatch(trimmed) ||
          RegExp(r'(学完|复习|学习|备考|考试|考研|高考|考公|看完|做完|完成)').hasMatch(trimmed) ||
          RegExp(r'第[\d一二三四五六七八九十]+').hasMatch(trimmed)) {
        keySentences.add(trimmed);
      }
    }
    if (keySentences.isNotEmpty) {
      final result = keySentences.toSet().take(3).join(' ');
      return result.length <= 100 ? result : result.substring(0, 100);
    }
    return message.length > 80 ? message.substring(0, 80) : message;
  }

  String _truncateSearchContext(String context, int maxLength) {
    if (context.length <= maxLength) return context;
    final truncated = context.substring(0, maxLength);
    final lastNewline = truncated.lastIndexOf('\n');
    if (lastNewline > maxLength * 0.8) {
      return truncated.substring(0, lastNewline);
    }
    return truncated;
  }

  Future<String?> _tryFixJson(String brokenJson) async {
    if (!isConfigured) return null;
    try {
      final response = await sendMessage(
          '以下 JSON 格式有误，请修复并只输出修正后的 JSON：\n\n$brokenJson',
          useMemory: false);
      final t = response.trim();
      return t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }

  String? _extractJsonBlock(String text) {
    final startIndex = text.indexOf('{');
    if (startIndex == -1) return null;
    final stack = <String>[];
    bool inString = false;
    String? stringChar;
    for (int i = startIndex; i < text.length; i++) {
      final char = text[i];
      if (inString) {
        if (char == '\\') {
          i++;
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
      if (char == '{') {
        stack.add('}');
      } else if (char == '[') {
        stack.add(']');
      } else if (char == '}' || char == ']') {
        if (stack.isEmpty) {
          break;
        }
        final expected = stack.removeLast();
        if (char != expected) {
          break;
        }
        if (stack.isEmpty) {
          String jsonStr = text.substring(startIndex, i + 1);
          jsonStr = jsonStr.replaceAll(RegExp(r',\s*}'), '}');
          jsonStr = jsonStr.replaceAll(RegExp(r',\s*]'), ']');
          return jsonStr;
        }
      }
    }
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
    if (!isConfigured) throw Exception('API Key 未配置');
    final daysRemaining = examDate.difference(DateTime.now()).inDays;
    final prompt = '''请帮我制定一个学习计划：
考试名称：$examName
考试日期：还有 $daysRemaining 天
科目：${subjects.join('、')}
每天：$dailyHours 小时
${additionalInfo != null ? '补充信息：$additionalInfo' : ''}
请生成详细计划（每日安排、重点建议、时间分配），使用中文。''';
    return sendMessage(prompt);
  }

  Future<String> analyzeStudyData({
    required int totalMinutesToday,
    required int totalMinutesWeek,
    required Map<String, int> subjectDistribution,
    required List<int> dailyMinutes,
  }) async {
    if (!isConfigured) throw Exception('API Key 未配置');
    final prompt = '''请分析学习数据：
今日：${totalMinutesToday ~/ 60}h${totalMinutesToday % 60}m
本周：${totalMinutesWeek ~/ 60}h${totalMinutesWeek % 60}m
科目分布：${subjectDistribution.entries.map((e) => '${e.key}: ${e.value ~/ 60}h${e.value % 60}m').join(', ')}
近7天：${dailyMinutes.join(', ')}分钟/天
用中文简洁分析效率、分配和改进建议。''';
    return sendMessage(prompt);
  }

  Future<String> chat(String message) => sendMessage(message);
  Stream<String> chatStream(String message) => sendMessageStream(message);
}
