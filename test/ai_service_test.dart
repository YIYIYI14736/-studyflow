import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/services/ai_service.dart';
import 'package:studyflow/services/memory_service.dart';

void main() {
  test('chatStream completes when DONE arrives even if upstream stays open',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    server.listen((request) async {
      request.response.bufferOutput = false;
      request.response.headers.contentType =
          ContentType('text', 'event-stream', charset: 'utf-8');

      final chunk = jsonEncode({
        'choices': [
          {
            'delta': {'content': '回答完成'},
          }
        ],
      });
      request.response.write('data: $chunk\n\n');
      request.response.write('data: [DONE]\n\n');
      await request.response.flush();
    });

    final service = AIService()
      ..configure(
        apiKey: 'test-key',
        baseUrl: 'http://127.0.0.1:${server.port}',
        model: 'test-model',
      );

    try {
      await expectLater(
        service
            .chatStream('hello')
            .toList()
            .timeout(const Duration(seconds: 2)),
        completion(['回答完成']),
      );
    } finally {
      await server.close(force: true);
    }
  });

  test('memory service does not treat chat API key as embedding config',
      () async {
    final service = MemoryService()
      ..configure(
        apiKey: 'deepseek-chat-key',
        baseUrl: 'https://api.deepseek.com',
      );

    expect(service.isConfigured, isFalse);

    await service.addMemory(
      MemoryItem(id: 'memory-1', content: '代数错题需要复习', type: 'note'),
    );

    final results = await service.searchMemories('代数');
    expect(results, hasLength(1));
    expect(results.single.id, 'memory-1');
  });
}
