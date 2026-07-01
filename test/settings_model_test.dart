import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/models.dart';

void main() {
  test('AppSettings reads legacy openai keys and writes provider-neutral keys',
      () {
    final settings = AppSettings.fromJson({
      'openaiApiKey': 'legacy-key',
      'openaiBaseUrl': 'https://legacy.example',
      'openaiModel': 'legacy-model',
    });

    expect(settings.aiApiKey, 'legacy-key');
    expect(settings.aiBaseUrl, 'https://legacy.example');
    expect(settings.aiModel, 'legacy-model');

    final json = settings.toJson();
    expect(json['aiApiKey'], 'legacy-key');
    expect(json['aiBaseUrl'], 'https://legacy.example');
    expect(json['aiModel'], 'legacy-model');
    expect(json.containsKey('openaiApiKey'), isFalse);
    expect(json.containsKey('openaiBaseUrl'), isFalse);
    expect(json.containsKey('openaiModel'), isFalse);
  });
}
