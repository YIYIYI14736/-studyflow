import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';

/// 记忆条目
class MemoryItem {
  final String id;
  final String content;
  final String type; // 'chat', 'plan', 'session', 'note'
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
        id: json['id'] as String,
        content: json['content'] as String,
        type: json['type'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        embedding: (json['embedding'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      );
}

/// 记忆服务 - 使用 embedding 模型实现语义记忆
class MemoryService {
  final Dio _dio = Dio();
  String? _apiKey;
  String? _baseUrl;
  String _embeddingModel = 'doubao-embedding-vision';

  // 内存中的记忆存储
  final List<MemoryItem> _memories = [];

  List<MemoryItem> get memories => List.unmodifiable(_memories);

  void configure({
    String? apiKey,
    String? baseUrl,
  }) {
    _apiKey = apiKey;
    _baseUrl = baseUrl;
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// 获取文本的 embedding 向量
  Future<List<double>> getEmbedding(String text) async {
    if (!isConfigured) {
      throw Exception('API Key 未配置');
    }

    String apiUrl;
    if (_baseUrl != null) {
      final base = _baseUrl!.endsWith('/')
          ? _baseUrl!.substring(0, _baseUrl!.length - 1)
          : _baseUrl!;
      apiUrl = '$base/embeddings';
    } else {
      apiUrl = 'https://ark.cn-beijing.volces.com/api/coding/v3/embeddings';
    }

    try {
      final response = await _dio.post(
        apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _embeddingModel,
          'input': text,
        },
      );

      final embedding = response.data['data'][0]['embedding'] as List;
      return embedding.map((e) => (e as num).toDouble()).toList();
    } on DioException catch (e) {
      throw Exception('Embedding 请求失败: ${e.message}');
    }
  }

  /// 添加记忆
  Future<void> addMemory(MemoryItem memory) async {
    try {
      if (isConfigured) {
        final embedding = await getEmbedding(memory.content);
        final memoryWithEmbedding = MemoryItem(
          id: memory.id,
          content: memory.content,
          type: memory.type,
          createdAt: memory.createdAt,
          embedding: embedding,
        );
        _memories.add(memoryWithEmbedding);
      } else {
        _memories.add(memory);
      }
    } catch (e) {
      // 如果 embedding 失败，仍然保存记忆（不带向量）
      _memories.add(memory);
    }
  }

  /// 计算余弦相似度
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// 搜索相关记忆
  Future<List<MemoryItem>> searchMemories(String query, {int limit = 5}) async {
    if (_memories.isEmpty) return [];

    try {
      if (isConfigured) {
        final queryEmbedding = await getEmbedding(query);

        // 计算相似度并排序
        final scoredMemories = _memories
            .where((m) => m.embedding != null)
            .map((m) => MapEntry(
                  m,
                  _cosineSimilarity(queryEmbedding, m.embedding!),
                ))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return scoredMemories.take(limit).map((e) => e.key).toList();
      } else {
        // 如果没有配置 embedding，使用关键词匹配
        final keywords = query.toLowerCase().split(' ');
        return _memories
            .where((m) =>
                keywords.any((k) => m.content.toLowerCase().contains(k)))
            .take(limit)
            .toList();
      }
    } catch (e) {
      // 降级为关键词搜索
      final keywords = query.toLowerCase().split(' ');
      return _memories
          .where((m) => keywords.any((k) => m.content.toLowerCase().contains(k)))
          .take(limit)
          .toList();
    }
  }

  /// 构建记忆上下文
  Future<String> buildMemoryContext(String query) async {
    final relevantMemories = await searchMemories(query, limit: 3);

    if (relevantMemories.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('以下是与当前对话相关的历史记忆：');

    for (final memory in relevantMemories) {
      final typeLabel = _getTypeLabel(memory.type);
      buffer.writeln('[$typeLabel] ${memory.content}');
    }

    buffer.writeln('---');
    return buffer.toString();
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'chat':
        return '对话';
      case 'plan':
        return '计划';
      case 'session':
        return '学习记录';
      case 'note':
        return '笔记';
      default:
        return '记忆';
    }
  }

  /// 清除所有记忆
  void clearMemories() {
    _memories.clear();
  }

  /// 导出记忆（用于持久化）
  List<Map<String, dynamic>> exportMemories() {
    return _memories.map((m) => m.toJson()).toList();
  }

  /// 导入记忆
  void importMemories(List<Map<String, dynamic>> data) {
    _memories.clear();
    _memories.addAll(data.map((m) => MemoryItem.fromJson(m)));
  }
}
