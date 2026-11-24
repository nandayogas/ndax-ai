import 'claude_service.dart';
import 'ollama_service.dart';
import 'openai_compatible_service.dart';

enum AiProvider { anthropic, openrouter, openai, ollama, unknown }

/// Mendeteksi penyedia AI dari awalan API key, lalu meneruskan request ke layanan yang sesuai.
class AiRouter {
  static AiProvider detect(String rawKey) {
    final key = rawKey.trim();
    if (key.isEmpty) return AiProvider.ollama;
    if (key.startsWith('sk-ant-')) return AiProvider.anthropic;
    if (key.startsWith('sk-or-')) return AiProvider.openrouter;
    if (key.startsWith('sk-')) return AiProvider.openai;
    return AiProvider.unknown;
  }

  static String label(AiProvider provider) {
    switch (provider) {
      case AiProvider.anthropic:
        return 'Claude API';
      case AiProvider.openrouter:
        return 'OpenRouter';
      case AiProvider.openai:
        return 'OpenAI';
      case AiProvider.ollama:
        return 'Ollama';
      case AiProvider.unknown:
        return 'Key tidak dikenali';
    }
  }

  /// Daftar model statis. Untuk Ollama, daftar diambil dari server.
  static List<String> modelsFor(AiProvider provider) {
    switch (provider) {
      case AiProvider.anthropic:
        return ClaudeService.models;
      case AiProvider.openrouter:
        return OpenAICompatibleService.openRouterModels;
      case AiProvider.openai:
        return OpenAICompatibleService.openAiModels;
      case AiProvider.ollama:
      case AiProvider.unknown:
        return const [];
    }
  }

  static Future<String> chat({
    required String apiKey,
    required String ollamaUrl,
    required String model,
    required List<Map<String, String>> messages,
    required String systemPrompt,
    required double temperature,
  }) {
    switch (detect(apiKey)) {
      case AiProvider.anthropic:
        return ClaudeService(apiKey).chat(
          model: model,
          messages: messages,
          systemPrompt: systemPrompt,
          temperature: temperature,
        );
      case AiProvider.openrouter:
        return OpenAICompatibleService(
          baseUrl: 'https://openrouter.ai/api/v1',
          apiKey: apiKey,
          name: 'OpenRouter',
        ).chat(model: model, messages: messages, systemPrompt: systemPrompt, temperature: temperature);
      case AiProvider.openai:
        return OpenAICompatibleService(
          baseUrl: 'https://api.openai.com/v1',
          apiKey: apiKey,
          name: 'OpenAI',
        ).chat(model: model, messages: messages, systemPrompt: systemPrompt, temperature: temperature);
      case AiProvider.ollama:
        return OllamaService(ollamaUrl).chat(
          model: model,
          messages: messages,
          systemPrompt: systemPrompt,
          temperature: temperature,
        );
      case AiProvider.unknown:
        throw Exception(
          'Format API key tidak dikenali. Claude diawali sk-ant-, OpenRouter diawali sk-or-, OpenAI diawali sk-. Kosongkan kolom untuk memakai Ollama.',
        );
    }
  }
}
