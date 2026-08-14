import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'encryptor_service.dart';

class EncryptorPage extends StatefulWidget {
  const EncryptorPage({super.key});

  @override
  State<EncryptorPage> createState() => _EncryptorPageState();
}

class _EncryptorPageState extends State<EncryptorPage> {
  final _inputController = TextEditingController();
  EncryptFileType _type = EncryptFileType.html;
  String _output = '';
  bool _processing = false;
  String? _error;

  Future<void> _run() async {
    final source = _inputController.text;
    if (source.trim().isEmpty) return;

    setState(() {
      _processing = true;
      _error = null;
      _output = '';
    });

    try {
      switch (_type) {
        case EncryptFileType.html:
          setState(() => _output = EncryptorService.encryptHtml(source));
          break;
        case EncryptFileType.php:
          setState(() => _output = EncryptorService.encryptPhp(source));
          break;
        case EncryptFileType.css:
          setState(() => _output = EncryptorService.minifyCss(source));
          break;
        case EncryptFileType.js:
          final result = await EncryptorService.encryptJs(source);
          setState(() => _output = result);
          break;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: 'Code',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.ink)),
            TextSpan(
                text: 'Encryptor',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.cyan)),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text('// obfuscate HTML, PHP, CSS, JS',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 11)),
        const SizedBox(height: 18),

        _typeSelector(),
        const SizedBox(height: 8),
        _typeNote(),
        const SizedBox(height: 14),

        TextField(
          controller: _inputController,
          maxLines: 10,
          style: const TextStyle(color: AppColors.ink, fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(hintText: _hintFor(_type)),
        ),
        const SizedBox(height: 12),

        ElevatedButton(
          onPressed: _processing ? null : _run,
          child: Text(_processing
              ? (_type == EncryptFileType.js ? 'MEMPROSES (BUTUH INTERNET)...' : 'MEMPROSES...')
              : 'PROSES'),
        ),

        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.magenta.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 11.5)),
          ),
        ],

        if (_output.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('HASIL',
              style: TextStyle(
                  color: AppColors.gray, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _output,
              style: const TextStyle(color: AppColors.cyan, fontSize: 10.5, fontFamily: 'monospace'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _typeSelector() {
    return Wrap(
      spacing: 8,
      children: EncryptFileType.values.map((t) {
        final selected = _type == t;
        return ChoiceChip(
          label: Text(t.name.toUpperCase()),
          selected: selected,
          onSelected: (_) => setState(() {
            _type = t;
            _output = '';
            _error = null;
          }),
          selectedColor: AppColors.cyan,
          backgroundColor: AppColors.panel,
          labelStyle: TextStyle(
            color: selected ? const Color(0xFF06110E) : AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          side: const BorderSide(color: AppColors.line),
        );
      }).toList(),
    );
  }

  Widget _typeNote() {
    String note;
    switch (_type) {
      case EncryptFileType.html:
        note = 'Base64 + auto-decode script. Isi asli gak keliatan di "View Source".';
        break;
      case EncryptFileType.php:
        note = 'Base64 + eval(). Teknik obfuscation PHP yang umum dipakai.';
        break;
      case EncryptFileType.css:
        note = '⚠ CSS gak bisa dienkripsi beneran (gak ada eval buat CSS). Ini cuma minify.';
        break;
      case EncryptFileType.js:
        note = '⚠ Pakai js-confuser via CDN, butuh internet. Bisa gagal kalau CDN down.';
        break;
    }
    return Text(note, style: const TextStyle(color: AppColors.gray, fontSize: 10.5));
  }

  String _hintFor(EncryptFileType t) {
    switch (t) {
      case EncryptFileType.html:
        return 'Tempel kode HTML di sini...';
      case EncryptFileType.php:
        return 'Tempel kode PHP di sini...';
      case EncryptFileType.css:
        return 'Tempel kode CSS di sini...';
      case EncryptFileType.js:
        return 'Tempel kode JavaScript di sini...';
    }
  }
}
