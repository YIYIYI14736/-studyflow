import 'dart:math';
import 'package:dio/dio.dart';

class MemoryItem {
  final String id;
  final String content;
  final String type;
  final DateTime createdAt;
  final List<double>? embedding;

  MemoryItem({
    required this.id,
    required this.content,
    required this.type,
    DateTime? createdAt,
    this.embedding,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'embedding': embedding,
      };

  factory MemoryItem.fromJson(Map<String, dynamic> json) => MemoryItem(
        id: json['id'] as String? ?? '',
        content: json['content'] as String? ?? '',
        type: json['type'] as String? ?? 'note',
        createdAt: json['createdAt'] is String
            ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
            : DateTime.now(),
        embedding: (json['embedding'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
      );
}

/// 语义记忆服务
///
/// Embedding 需要单独的兼容 API（如 OpenAI text-embedding 系列），
/// DeepSeek 官方 API 不支持 Embedding，所以本服务可独立配置 embedding 端点。
/// 若未配置 Embedding 则自动降级为关键词匹配（Bigram + 全匹配）。
class MemoryService {
  final Dio _dio = Dio();

  String? _embeddingApiKey;
  String? _embeddingBaseUrl;
  String _embeddingModel = 'text-embedding-3-small';

  final List<MemoryItem> _memories = [];

  List<MemoryItem> get memories => List.unmodifiable(_memories);

  void configure({
    String? apiKey,
    String? baseUrl,
    String? embeddingApiKey,
    String? embeddingBaseUrl,
    String? embeddingModel,
  }) {
    // apiKey/baseUrl are kept for source compatibility with older callers.
    // DeepSeek chat credentials are not valid embedding credentials.
    if (embeddingApiKey != null) _embeddingApiKey = embeddingApiKey;
    if (embeddingBaseUrl != null && embeddingBaseUrl.trim().isNotEmpty) {
      _embeddingBaseUrl = embeddingBaseUrl;
    }
    if (embeddingModel != null && embeddingModel.trim().isNotEmpty) {
      _embeddingModel = embeddingModel;
    }
  }

  bool get isConfigured =>
      _embeddingApiKey != null && _embeddingApiKey!.trim().isNotEmpty;

  Future<List<double>> getEmbedding(String text) async {
    if (!isConfigured) throw Exception('Embedding API Key 未配置');

    final baseUrl = (_embeddingBaseUrl ?? 'https://api.openai.com/v1')
        .replaceAll(RegExp(r'/+$'), '');
    final apiUrl = '$baseUrl/embeddings';

    try {
      final response = await _dio.post(
        apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_embeddingApiKey',
            'Content-Type': 'application/json'
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {'model': _embeddingModel, 'input': text},
      );

      final embedding = response.data['data'][0]['embedding'] as List;
      return embedding.map((e) => (e as num).toDouble()).toList();
    } on DioException catch (e) {
      throw Exception('Embedding 请求失败: ${e.message}');
    }
  }

  static const int _maxMemories = 500;

  Future<void> addMemory(MemoryItem memory) async {
    try {
      if (isConfigured) {
        final embedding = await getEmbedding(memory.content);
        _memories.add(MemoryItem(
          id: memory.id,
          content: memory.content,
          type: memory.type,
          createdAt: memory.createdAt,
          embedding: embedding,
        ));
      } else {
        _memories.add(memory);
      }
    } catch (_) {
      _memories.add(memory);
    }
    while (_memories.length > _maxMemories) {
      _memories.removeAt(0);
    }
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    double dot = 0, na = 0, nb = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (sqrt(na) * sqrt(nb));
  }

  Future<List<MemoryItem>> searchMemories(String query, {int limit = 5}) async {
    if (_memories.isEmpty) return [];
    try {
      if (isConfigured) {
        final queryEmbedding = await getEmbedding(query);
        final scored = _memories
            .where((m) => m.embedding != null)
            .map((m) =>
                MapEntry(m, _cosineSimilarity(queryEmbedding, m.embedding!)))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return scored.take(limit).map((e) => e.key).toList();
      } else {
        return _keywordSearch(query, limit);
      }
    } catch (_) {
      return _keywordSearch(query, limit);
    }
  }

  List<MemoryItem> _keywordSearch(String query, int limit) {
    final lq = query.toLowerCase();
    final tokens = <String>{lq};
    for (int i = 0; i < lq.length - 1; i++) {
      final bg = lq.substring(i, i + 2);
      if (bg.trim().isNotEmpty) tokens.add(bg);
    }
    tokens.addAll(lq.split(' ').where((w) => w.length >= 2));
    return _memories
        .where((m) => tokens.any((t) => m.content.toLowerCase().contains(t)))
        .take(limit)
        .toList();
  }

  Future<String> buildMemoryContext(String query) async {
    final memories = await searchMemories(query, limit: 3);
    if (memories.isEmpty) return '';
    final buf = StringBuffer()..writeln('以下是与当前对话相关的历史记忆：');
    for (final m in memories) {
      buf.writeln('[${_typeLabel(m.type)}] ${m.content}');
    }
    buf.writeln('---');
    return buf.toString();
  }

  String _typeLabel(String type) =>
      {'chat': '对话', 'plan': '计划', 'session': '学习记录', 'note': '笔记'}[type] ??
      '记忆';

  void removeMemory(String id) => _memories.removeWhere((m) => m.id == id);
  void clearMemories() => _memories.clear();
  List<Map<String, dynamic>> exportMemories() =>
      _memories.map((m) => m.toJson()).toList();

  void importMemories(List<Map<String, dynamic>> data) {
    _memories.clear();
    for (final m in data) {
      try {
        _memories.add(MemoryItem.fromJson(m));
      } catch (_) {}
    }
  }
}
