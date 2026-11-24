import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _url = TextEditingController(text: 'http://127.0.0.1:11434');
  final _apiKey = TextEditingController();
  final _prompt = TextEditingController(
    text: 'Kamu adalah NDAX AI, asisten pribadi yang fleksibel. Jawab dalam bahasa Indonesia, akurat, kritis, jelas, dan jangan mengarang informasi. Bantu pemrograman, analisis, teknologi, dan tugas umum. Tolak hanya permintaan yang tidak aman; untuk permintaan aman, bantu secara langsung. Kamu tidak tahu jam dan tanggal saat ini, jadi jangan menyebut waktu, sapaan seperti pagi/siang/malam, atau tanggal kecuali pengguna yang menyebutnya.',
  );
  bool _showKey = false;
  double _temperature = 0.7;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _url.text = prefs.getString('ollama_url') ?? _url.text;
    // Membaca key lama (claude_api_key) agar tidak hilang saat update.
    _apiKey.text = prefs.getString('api_key') ?? prefs.getString('claude_api_key') ?? '';
    _prompt.text = prefs.getString('system_prompt') ?? _prompt.text;
    _temperature = prefs.getDouble('temperature') ?? 0.7;
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', _apiKey.text.trim());
    await prefs.setString('ollama_url', _url.text.trim());
    await prefs.setString('system_prompt', _prompt.text.trim());
    await prefs.setDouble('temperature', _temperature);
    await prefs.remove('claude_api_key');
    await prefs.remove('provider');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan tersimpan')),
      );
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _apiKey.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final provider = AiRouter.detect(_apiKey.text);
    final String status;
    if (provider == AiProvider.unknown) {
      status = 'Format key tidak dikenali. Claude: sk-ant-, OpenRouter: sk-or-, OpenAI: sk-';
    } else if (provider == AiProvider.ollama) {
      status = 'Kolom kosong, memakai Ollama lokal di alamat di bawah.';
    } else {
      status = 'Terdeteksi: ${AiRouter.label(provider)}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan NDAX AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('API Key', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKey,
            obscureText: !_showKey,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Claude, OpenRouter, atau OpenAI (kosongkan untuk Ollama)',
              suffixIcon: IconButton(
                icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showKey = !_showKey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              color: provider == AiProvider.unknown ? Colors.redAccent : Colors.lightBlueAccent,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Key disimpan di perangkat ini saja. Jangan bagikan APK yang berisi key pribadi Anda.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 18),
          const Text('Alamat Ollama', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _url, decoration: const InputDecoration(hintText: 'http://127.0.0.1:11434')),
          const SizedBox(height: 8),
          const Text(
            'Dipakai hanya jika kolom API key kosong.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 18),
          const Text('System Prompt', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _prompt, minLines: 5, maxLines: 10),
          const SizedBox(height: 18),
          Text('Kreativitas: ${_temperature.toStringAsFixed(1)}'),
          Slider(
            value: _temperature,
            min: 0,
            max: 1.0,
            divisions: 10,
            onChanged: (v) => setState(() => _temperature = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Simpan pengaturan'),
          ),
        ],
      ),
    );
  }
}
