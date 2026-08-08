import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/models/app_settings.dart';
import '../../core/update/update_banner.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _imgUrl;
  late TextEditingController _webhook;
  late TextEditingController _timeout;
  late TextEditingController _geminiKey;
  late TextEditingController _geminiModel;
  late TextEditingController _deepseekKey;
  late TextEditingController _deepseekModel;
  late TextEditingController _blackboxKey;
  late TextEditingController _blackboxModel;
  late TextEditingController _customUrl;
  late TextEditingController _customKey;
  late TextEditingController _customRequestField;
  late TextEditingController _customResponseField;
  late TextEditingController _githubToken;

  bool _showToast = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = SettingsController.instance.settings;
    _imgUrl = TextEditingController(text: s.dashboardImageUrl);
    _webhook = TextEditingController(text: s.webhookUrl);
    _timeout = TextEditingController(text: s.requestTimeoutMs.toString());
    _geminiKey = TextEditingController(text: s.geminiApiKey);
    _geminiModel = TextEditingController(text: s.geminiModel);
    _deepseekKey = TextEditingController(text: s.deepseekApiKey);
    _deepseekModel = TextEditingController(text: s.deepseekModel);
    _blackboxKey = TextEditingController(text: s.blackboxApiKey);
    _blackboxModel = TextEditingController(text: s.blackboxModel);
    _customUrl = TextEditingController(text: s.customRestUrl);
    _customKey = TextEditingController(text: s.customRestApiKey);
    _customRequestField = TextEditingController(text: s.customRequestField);
    _customResponseField = TextEditingController(text: s.customResponseField);
    _githubToken = TextEditingController(text: s.githubToken);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final c = SettingsController.instance;
    c.settings
      ..dashboardImageUrl = _imgUrl.text.trim()
      ..webhookUrl = _webhook.text.trim()
      ..requestTimeoutMs = int.tryParse(_timeout.text.trim()) ?? 5000
      ..geminiApiKey = _geminiKey.text.trim()
      ..geminiModel = _geminiModel.text.trim()
      ..deepseekApiKey = _deepseekKey.text.trim()
      ..deepseekModel = _deepseekModel.text.trim()
      ..blackboxApiKey = _blackboxKey.text.trim()
      ..blackboxModel = _blackboxModel.text.trim()
      ..customRestUrl = _customUrl.text.trim()
      ..customRestApiKey = _customKey.text.trim()
      ..customRequestField = _customRequestField.text.trim()
      ..customResponseField = _customResponseField.text.trim()
      ..githubToken = _githubToken.text.trim();

    try {
      await c.save();
      setState(() => _showToast = true);
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) setState(() => _showToast = false);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.instance.settings;

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 4),
          child: Column(
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'Seraph',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.ink)),
                  TextSpan(
                      text: 'Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.cyan)),
                ]),
              ),
              SizedBox(height: 6),
              Text('// konfigurasi koneksi & preferensi',
                  style: TextStyle(color: AppColors.gray, fontSize: 11)),
            ],
          ),
        ),

        const UpdateBanner(),

        _block('Gambar Dashboard (URL, support GIF juga)', [
          _field(_imgUrl, hint: 'https://contoh.com/gambar.png atau .gif'),
        ]),

        _block('AI Chat Provider', [
          DropdownButtonFormField<AiProvider>(
            initialValue: settings.aiProvider,
            dropdownColor: AppColors.panel2,
            style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
            decoration: const InputDecoration(),
            items: AiProvider.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => SettingsController.instance.settings.aiProvider = v);
              }
            },
          ),
        ]),

        if (settings.aiProvider == AiProvider.gemini) ...[
          _block('Gemini API Key', [_field(_geminiKey, obscure: true, hint: 'AIza••••••••')]),
          _block('Gemini Model ID', [
            _field(_geminiModel, hint: 'gemini-3.6-flash'),
          ]),
        ],
        if (settings.aiProvider == AiProvider.deepseek) ...[
          _block('DeepSeek API Key', [_field(_deepseekKey, obscure: true, hint: 'sk-••••••••')]),
          _block('DeepSeek Model ID', [
            _field(_deepseekModel, hint: 'deepseek-v4-flash'),
          ]),
        ],
        if (settings.aiProvider == AiProvider.blackbox) ...[
          _block('Blackbox API Key', [_field(_blackboxKey, obscure: true, hint: 'bb-••••••••')]),
          _block('Blackbox Model ID', [
            _field(_blackboxModel, hint: 'blackboxai/openai/gpt-5.5'),
          ]),
        ],
        if (settings.aiProvider == AiProvider.customRest) ...[
          _block('Custom REST API URL', [
            _field(_customUrl, hint: 'https://api-kamu.com/chat'),
          ]),
          _block('Custom REST API Key (opsional)', [
            _field(_customKey, obscure: true, hint: '••••••••'),
          ]),
          _block('Nama Field Pesan (request)', [
            _field(_customRequestField, hint: 'message'),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Body yang dikirim: {"nama_field": "pesan user"}',
                style: TextStyle(color: AppColors.gray, fontSize: 9.5),
              ),
            ),
          ]),
          _block('Path Field Balasan (response)', [
            _field(_customResponseField, hint: 'response'),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Contoh: "response" untuk {"response":"..."}, atau\n'
                '"choices.0.message.content" untuk format ala OpenAI',
                style: TextStyle(color: AppColors.gray, fontSize: 9.5),
              ),
            ),
          ]),
        ],

        _block('GitHub Personal Access Token', [
          _field(_githubToken, obscure: true, hint: 'ghp_••••••••'),
        ]),

        _block('Webhook URL', [_field(_webhook, hint: 'https://hooks.seraphapps.dev/notify')]),
        _block('Request Timeout (ms)', [
          _field(_timeout, hint: '5000', keyboardType: TextInputType.number),
        ]),

        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _toggle('Notifikasi Push', 'Kirim notifikasi saat ada event',
                  settings.notifPush, (v) => setState(() => settings.notifPush = v)),
              _toggle('Mode Debug', 'Tampilkan log detail di console', settings.debugMode,
                  (v) => setState(() => settings.debugMode = v)),
              _toggle('Auto Sync', 'Sinkronkan data tiap 15 menit', settings.autoSync,
                  (v) => setState(() => settings.autoSync = v)),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'MENYIMPAN...' : 'SIMPAN PENGATURAN'),
          ),
        ),
        AnimatedOpacity(
          opacity: _showToast ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('✓ Pengaturan tersimpan',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.cyan, fontSize: 11)),
          ),
        ),
      ],
    );
  }

  Widget _block(String label, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.gray,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController c,
      {String hint = '', bool obscure = false, TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _toggle(String name, String desc, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: AppColors.gray, fontSize: 10)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
