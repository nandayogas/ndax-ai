import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _provider = 'ollama';
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
    _provider = prefs.getString('provider') ?? 'ollama';
    _url.text = prefs.getString('ollama_url') ?? _url.text;
    _apiKey.text = prefs.getString('claude_api_key') ?? '';
    _prompt.text = prefs.getString('system_prompt') ?? _prompt.text;
    _temperature = prefs.getDouble('temperature') ?? 0.7;
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('provider', _provider);
    await prefs.setString('ollama_url', _url.text.trim());
    await prefs.setString('claude_api_key', _apiKey.text.trim());
    await prefs.setString('system_prompt', _prompt.text.trim());
    await prefs.setDouble('temperature', _temperature);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan NDAX AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Penyedia AI', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ollama', label: Text('Ollama'), icon: Icon(Icons.computer)),
              ButtonSegment(value: 'claude', label: Text('Claude API'), icon: Icon(Icons.cloud_outlined)),
            ],
            selected: {_provider},
            onSelectionChanged: (s) => setState(() => _provider = s.first),
          ),
          const SizedBox(height: 18),
          if (_provider == 'claude') ...[
            const Text('Claude API Key', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKey,
              obscureText: !_showKey,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                suffixIcon: IconButton(
                  icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showKey = !_showKey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'API key disimpan di perangkat ini saja. Jangan bagikan APK yang berisi key pribadi Anda.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ] else ...[
            const Text('Alamat Ollama', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _url, decoration: const InputDecoration(hintText: 'http://127.0.0.1:11434')),
            const SizedBox(height: 8),
            const Text(
              'Catatan: alamat 127.0.0.1 hanya berfungsi jika server Ollama dapat diakses dari lingkungan Android yang sama. Jika Ollama berjalan di perangkat lain, gunakan alamat IP perangkat tersebut.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          const Text('System Prompt', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _prompt, minLines: 5, maxLines: 10),
          const SizedBox(height: 18),
          Text('Kreativitas: ${_temperature.toStringAsFixed(1)}'),
          Slider(
            value: _temperature,
            min: 0,
            max: 1.5,
            divisions: 15,
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
