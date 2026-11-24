import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/ai_router.dart';
import '../services/database_service.dart';
import '../services/ollama_service.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  String _apiKey = '';
  String _baseUrl = 'http://127.0.0.1:11434';
  String _systemPrompt = 'Kamu adalah NDAX AI. Jawab dalam bahasa Indonesia dengan akurat dan jelas. Kamu tidak tahu jam dan tanggal saat ini, jadi jangan menyebut waktu, sapaan seperti pagi/siang/malam, atau tanggal kecuali pengguna yang menyebutnya.';
  double _temperature = 0.7;
  AiProvider _provider = AiProvider.ollama;
  String _model = '';
  List<String> _models = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _messages.addAll(await DatabaseService.instance.getMessages());
    await _refreshModels();
    if (mounted) setState(() {});
  }

  /// Membaca semua pengaturan terbaru dari penyimpanan.
  Future<SharedPreferences> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key') ?? prefs.getString('claude_api_key') ?? '';
    _baseUrl = prefs.getString('ollama_url') ?? _baseUrl;
    _systemPrompt = prefs.getString('system_prompt') ?? _systemPrompt;
    _temperature = prefs.getDouble('temperature') ?? _temperature;
    return prefs;
  }

  Future<void> _refreshModels() async {
    final prefs = await _loadPrefs();
    final provider = AiRouter.detect(_apiKey);

    if (provider == AiProvider.unknown) {
      if (!mounted) return;
      setState(() {
        _provider = provider;
        _models = [];
        _error = 'Format API key tidak dikenali. Buka Pengaturan dan periksa key Anda.';
      });
      return;
    }

    if (provider == AiProvider.ollama) {
      try {
        final models = await OllamaService(_baseUrl).getModels();
        if (!mounted) return;
        setState(() {
          _provider = provider;
          _models = models;
          _model = _pickModel(prefs, provider, models);
          _error = null;
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _provider = provider;
            _models = [];
            _error = 'Tidak dapat terhubung ke Ollama: $e';
          });
        }
      }
      return;
    }

    final models = AiRouter.modelsFor(provider);
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _models = models;
      _model = _pickModel(prefs, provider, models);
      _error = null;
    });
  }

  /// Memakai model tersimpan untuk penyedia ini, atau model pertama jika belum ada.
  String _pickModel(SharedPreferences prefs, AiProvider provider, List<String> models) {
    final saved = prefs.getString('model_${provider.name}');
    if (saved != null && models.contains(saved)) return saved;
    return models.isNotEmpty ? models.first : '';
  }

  Future<void> _selectModel(String model) async {
    setState(() => _model = model);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('model_${_provider.name}', model);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    final userMessage = ChatMessage(role: 'user', content: text, createdAt: DateTime.now());
    setState(() {
      _messages.add(userMessage);
      _input.clear();
      _busy = true;
      _error = null;
    });
    await DatabaseService.instance.addMessage(userMessage);

    try {
      await _loadPrefs();
      // Hanya kirim 10 pesan terakhir agar muat dan tidak lambat.
      final history = _messages.reversed.take(10).toList().reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final answer = await AiRouter.chat(
        apiKey: _apiKey,
        ollamaUrl: _baseUrl,
        model: _model,
        messages: history,
        systemPrompt: _systemPrompt,
        temperature: _temperature,
      );
      final assistantMessage = ChatMessage(
        role: 'assistant', content: answer, createdAt: DateTime.now(),
      );
      await DatabaseService.instance.addMessage(assistantMessage);
      if (mounted) setState(() => _messages.add(assistantMessage));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _jumpToBottom();
      }
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _clearChat() async {
    await DatabaseService.instance.clearMessages();
    if (mounted) setState(() => _messages.clear());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF19D7E6)),
          const SizedBox(width: 9),
          const Text('NDAX AI', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(
            AiRouter.label(_provider),
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ]),
        actions: [
          IconButton(tooltip: 'Refresh model', onPressed: _refreshModels, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Hapus chat', onPressed: _clearChat, icon: const Icon(Icons.delete_outline)),
          IconButton(tooltip: 'Pengaturan', onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            await _refreshModels();
          }, icon: const Icon(Icons.tune)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(children: [
              const Icon(Icons.memory, color: Color(0xFF19D7E6), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _models.contains(_model) ? _model : null,
                  hint: Text(_models.isEmpty ? 'Tidak ada model - cek pengaturan' : 'Pilih model'),
                  underline: const SizedBox(),
                  items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: _busy ? null : (v) => _selectModel(v ?? _model),
                ),
              ),
              if (_busy) const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ]),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bubble_chart, size: 54, color: Color(0xFF19D7E6)),
                      SizedBox(height: 12),
                      Text('Halo! Saya NDAX AI.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Pilih model lalu mulai bertanya.', style: TextStyle(color: Colors.white60)),
                    ],
                  ))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isUser = m.role == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 340),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFF123B48) : const Color(0xFF121E28),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SelectableText(m.content),
                        ),
                      );
                    },
                  ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('NDAX AI sedang berpikir…', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'Tulis pesan untuk NDAX AI…', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _busy || _models.isEmpty ? null : _send,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF19D7E6), foregroundColor: Colors.black),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
