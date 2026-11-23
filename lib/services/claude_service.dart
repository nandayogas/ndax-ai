import 'dart:convert';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const String _endpoint = 'https://api.anthropic.com/v1/messages';
  static const String _apiVersion = '2023-06-01';

  /// Daftar model Claude yang ditampilkan di aplikasi.
  static const List<String> models = [
    'claude-haiku-5-5',
    'claude-sonnet-5-5',
    'claude-opus-5-5',
  ];

  final String apiKey;
  ClaudeService(this.apiKey);

  Future<String> chat({
    required String model,
    required List<Map<String, String>> messages,
    required String systemPrompt,
    double temperature = 0.7,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw Exception('API key Claude belum diisi. Buka Pengaturan dan masukkan API key.');
    }

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'x-api-key': key,
            'anthropic-version': _apiVersion,
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': 2048,
            'system': systemPrompt,
            // Claude menerima temperature 0.0 - 1.0.
            'temperature': temperature.clamp(0.0, 1.0),
            'messages': _normalize(messages),
          }),
        )
        .timeout(const Duration(minutes: 3));

    if (response.statusCode != 200) {
      throw Exception('Claude HTTP ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final blocks = data['content'] as List<dynamic>? ?? [];
    return blocks
        .whereType<Map<String, dynamic>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String? ?? '')
        .join();
  }

  /// Claude mewajibkan pesan bergantian user/assistant dan diawali user.
  List<Map<String, String>> _normalize(List<Map<String, String>> input) {
    final out = <Map<String, String>>[];
    for (final m in input) {
      final role = m['role'] == 'assistant' ? 'assistant' : 'user';
      final content = m['content'] ?? '';
      if (content.trim().isEmpty) continue;
      if (out.isEmpty && role == 'assistant') continue;
      if (out.isNotEmpty && out.last['role'] == role) {
        out.last['content'] = '${out.last['content']}\n\n$content';
      } else {
        out.add({'role': role, 'content': content});
      }
    }
    return out;
  }
}
