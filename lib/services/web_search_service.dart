import 'dart:async';
import 'package:dio/dio.dart';

/// 搜索提供商枚举
enum SearchProvider {
  /// Tavily 搜索 API（推荐，专为 AI Agent 设计）
  tavily,

  /// Bing 搜索 API（微软）
  bing,

  /// 自定义搜索提供商
  custom,
}

/// 网络搜索结果数据模型
class WebSearchResult {
  /// 搜索结果标题
  final String title;

  /// 搜索结果链接
  final String url;

  /// 搜索结果摘要/内容
  final String snippet;

  /// 结果来源（可选，用于标注数据来源）
  final String? source;

  const WebSearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.source,
  });

  @override
  String toString() =>
      'WebSearchResult(title: $title, url: $url, snippet: ${snippet.length > 50 ? '${snippet.substring(0, 50)}...' : snippet})';
}

/// 网络搜索服务
///
/// 为 AI 助手提供互联网搜索能力，支持多种搜索提供商。
/// 当搜索失败时不会抛出异常，而是返回空结果，确保 AI 聊天功能不受影响。
class WebSearchService {
  final Dio _dio = Dio();

  /// API 密钥
  String? _apiKey;

  /// 自定义基础 URL（可选，用于 custom 提供商）
  String? _baseUrl;

  /// 当前搜索提供商
  SearchProvider _provider = SearchProvider.tavily;

  /// 自定义请求构建器（用于 custom 提供商）
  Future<List<WebSearchResult>> Function(
    Dio dio,
    String query,
    int maxResults,
  )? _customSearchHandler;

  /// 配置搜索服务
  ///
  /// [apiKey] 搜索 API 密钥
  /// [baseUrl] 自定义基础 URL（仅对 custom 提供商生效）
  /// [provider] 搜索提供商，默认为 Tavily
  /// [customSearchHandler] 自定义搜索处理函数（仅对 custom 提供商需要）
  void configure({
    String? apiKey,
    String? baseUrl,
    SearchProvider? provider,
    Future<List<WebSearchResult>> Function(
      Dio dio,
      String query,
      int maxResults,
    )? customSearchHandler,
  }) {
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      _apiKey = apiKey;
    }
    _baseUrl = baseUrl;
    if (provider != null) _provider = provider;
    if (customSearchHandler != null) _customSearchHandler = customSearchHandler;
  }

  /// 搜索服务是否已配置（至少设置了 API 密钥）
  bool get isConfigured => _apiKey != null && _apiKey!.trim().isNotEmpty;

  /// 当前使用的搜索提供商
  SearchProvider get provider => _provider;

  // ---------------------------------------------------------------------------
  //  核心搜索方法
  // ---------------------------------------------------------------------------

  /// 执行网络搜索，返回搜索结果列表
  ///
  /// [query] 搜索关键词
  /// [maxResults] 最大返回结果数，默认 5
  ///
  /// 搜索失败时返回空列表，不会抛出异常
  Future<List<WebSearchResult>> search(
    String query, {
    int maxResults = 5,
  }) async {
    if (!isConfigured || query.trim().isEmpty) {
      return [];
    }

    try {
      switch (_provider) {
        case SearchProvider.tavily:
          return await _searchWithTavily(query, maxResults);
        case SearchProvider.bing:
          return await _searchWithBing(query, maxResults);
        case SearchProvider.custom:
          return await _searchWithCustom(query, maxResults);
      }
    } on DioException catch (e) {
      // 网络错误、超时、HTTP 状态码异常等
      _logError('网络请求失败', e.message ?? e.type.toString());
      return [];
    } catch (e) {
      // 其他未知异常
      _logError('搜索发生未知错误', e.toString());
      return [];
    }
  }

  /// 执行搜索并将结果格式化为适合注入 AI 提示词的文本
  ///
  /// 输出格式示例：
  /// ```
  /// 以下是从网络搜索到的相关信息（请基于这些信息回答，并在回答中引用来源）：
  ///
  /// [1] 标题
  /// 来源: URL
  /// 内容: snippet
  ///
  /// [2] ...
  /// ```
  ///
  /// 如果没有搜索结果，返回空字符串
  Future<String> searchAndFormat(
    String query, {
    int maxResults = 5,
  }) async {
    final results = await search(query, maxResults: maxResults);

    if (results.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('以下是从网络搜索到的相关信息（请基于这些信息回答，并在回答中引用来源）：');
    buffer.writeln();

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('[${i + 1}] ${result.title}');
      buffer.writeln('来源: ${result.url}');
      buffer.writeln('内容: ${result.snippet}');
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  /// 构建完整的搜索上下文，用于注入 AI 提示词
  ///
  /// 在搜索结果外层包装标题头 "🔍 网络搜索结果"，
  /// 便于用户和 AI 区分搜索内容与对话内容。
  ///
  /// 如果没有搜索结果，返回空字符串
  Future<String> buildSearchContext(String query) async {
    final formatted = await searchAndFormat(query);
    if (formatted.isEmpty) return '';

    return '🔍 网络搜索结果\n$formatted';
  }

  // ---------------------------------------------------------------------------
  //  Tavily 搜索实现
  // ---------------------------------------------------------------------------

  /// 使用 Tavily API 执行搜索
  ///
  /// Tavily 是专为 AI Agent 设计的搜索 API，
  /// 请求方式：POST https://api.tavily.com/search
  Future<List<WebSearchResult>> _searchWithTavily(
    String query,
    int maxResults,
  ) async {
    final url = _baseUrl?.isNotEmpty == true
        ? _baseUrl!
        : 'https://api.tavily.com/search';

    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: <String, dynamic>{
        'api_key': _apiKey,
        'query': query,
        'search_depth': 'basic',
        'include_answer': false,
        'max_results': maxResults,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    final data = response.data;
    if (data == null) return [];

    final results = data['results'];
    if (results is! List) return [];

    return results
        .whereType<Map<String, dynamic>>()
        .map((item) => WebSearchResult(
              title: item['title'] as String? ?? '',
              url: item['url'] as String? ?? '',
              snippet: item['content'] as String? ?? '',
              source: item['url'] as String?,
            ))
        .where((r) => r.title.isNotEmpty && r.url.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  //  Bing 搜索实现
  // ---------------------------------------------------------------------------

  /// 使用 Bing Search API 执行搜索
  ///
  /// 请求方式：GET https://api.bing.microsoft.com/v7.0/search
  /// 需要在请求头中携带 Ocp-Apim-Subscription-Key
  Future<List<WebSearchResult>> _searchWithBing(
    String query,
    int maxResults,
  ) async {
    final url = _baseUrl?.isNotEmpty == true
        ? _baseUrl!
        : 'https://api.bing.microsoft.com/v7.0/search';

    final response = await _dio.get<Map<String, dynamic>>(
      url,
      queryParameters: <String, dynamic>{
        'q': query,
        'count': maxResults,
      },
      options: Options(
        headers: {
          'Ocp-Apim-Subscription-Key': _apiKey,
        },
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    final data = response.data;
    if (data == null) return [];

    final webPages = data['webPages'];
    if (webPages is! Map<String, dynamic>) return [];

    final values = webPages['value'];
    if (values is! List) return [];

    return values
        .whereType<Map<String, dynamic>>()
        .map((item) => WebSearchResult(
              title: item['name'] as String? ?? '',
              url: item['url'] as String? ?? '',
              snippet: item['snippet'] as String? ?? '',
              source: item['url'] as String?,
            ))
        .where((r) => r.title.isNotEmpty && r.url.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  //  自定义搜索实现
  // ---------------------------------------------------------------------------

  /// 使用自定义处理函数执行搜索
  ///
  /// 需要通过 [configure] 设置 [customSearchHandler]，
  /// 否则返回空列表
  Future<List<WebSearchResult>> _searchWithCustom(
    String query,
    int maxResults,
  ) async {
    if (_customSearchHandler == null) {
      _logError('自定义搜索', '未配置 customSearchHandler');
      return [];
    }

    return await _customSearchHandler!(_dio, query, maxResults);
  }

  // ---------------------------------------------------------------------------
  //  工具方法
  // ---------------------------------------------------------------------------

  /// 统一的错误日志输出
  ///
  /// 在生产环境中可替换为正式的日志框架，
  /// 当前使用 print 输出以便调试
  void _logError(String context, String message) {
    // ignore: avoid_print
    print('[WebSearchService] $context: $message');
  }
}
