import 'dart:convert';
import 'package:http/http.dart' as http;

/// Layanan untuk API yang mengikuti format OpenAI (OpenRouter, OpenAI).
class OpenAICompatibleService {
  static const List<String> openRouterModels = [
    'anthropic/claude-opus-4',
    'anthropic/claude-sonnet-4',
    'openai/gpt-4o-mini',
    'google/gemini-2.5-flash',
  ];

  static const List<String> openAiModels = [
    'gpt-4o-mini',
    'gpt-4o',
  ];

  final String baseUrl;
  final String apiKey;
  final String name;

  OpenAICompatibleService({
    required this.baseUrl,
    required this.apiKey,
    required this.name,
  });

  Future<String> chat({
    required String model,
    required List<Map<String, String>> messages,
    required String systemPrompt,
    double temperature = 0.7,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${apiKey.trim()}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': 2048,
            'temperature': temperature.clamp(0.0, 1.0),
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              ...messages,
            ],
          }),
        )
        .timeout(const Duration(minutes: 3));

    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      throw Exception('$name HTTP ${response.statusCode}: $body');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw Exception('$name: respons kosong');
    }
    final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
    return (message?['content'] as String?) ?? '';
  }
}
