import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaService {
  String baseUrl;
  OllamaService(this.baseUrl);

  Uri _uri(String path) => Uri.parse('${baseUrl.trim().replaceAll(RegExp(r'/+$'), '')}$path');

  Future<List<String>> getModels() async {
    final response = await http.get(_uri('/api/tags')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Ollama HTTP ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final models = (data['models'] as List<dynamic>? ?? []);
    return models.map((e) => (e as Map<String, dynamic>)['name'] as String).toList();
  }

  Future<String> chat({
    required String model,
    required List<Map<String, String>> messages,
    required String systemPrompt,
    double temperature = 0.7,
  }) async {
    final response = await http.post(
      _uri('/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'stream': false,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages,
        ],
        'options': {'temperature': temperature, 'num_ctx': 2048},
      }),
    ).timeout(const Duration(minutes: 5));

    if (response.statusCode != 200) {
      throw Exception('Ollama HTTP ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['message'] as Map<String, dynamic>)['content'] as String? ?? '';
  }
}
