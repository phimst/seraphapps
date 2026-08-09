import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_theme.dart';

class TtsPage extends StatefulWidget {
  const TtsPage({super.key});

  @override
  State<TtsPage> createState() => _TtsPageState();
}

class _TtsPageState extends State<TtsPage> {
  final FlutterTts _tts = FlutterTts();
  final _textController = TextEditingController();

  bool _speaking = false;
  double _rate = 0.5;
  double _pitch = 1.0;
  String _language = 'id-ID';

  final _languages = const {
    'id-ID': 'Indonesia',
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'ja-JP': '日本語',
    'ko-KR': '한국어',
  };

  @override
  void initState() {
    super.initState();
    _tts.setStartHandler(() => setState(() => _speaking = true));
    _tts.setCompletionHandler(() => setState(() => _speaking = false));
    _tts.setCancelHandler(() => setState(() => _speaking = false));
    _tts.setErrorHandler((_) => setState(() => _speaking = false));
  }

  Future<void> _speak() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);
    await _tts.speak(text);
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() => _speaking = false);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: 'Text2',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.ink)),
            TextSpan(
                text: 'Speech',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.cyan)),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text('// ubah teks jadi suara',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 11)),
        const SizedBox(height: 20),

        TextField(
          controller: _textController,
          maxLines: 5,
          style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
          decoration: const InputDecoration(hintText: 'Ketik teks yang mau dibacakan...'),
        ),
        const SizedBox(height: 16),

        _label('BAHASA'),
        DropdownButtonFormField<String>(
          initialValue: _language,
          dropdownColor: AppColors.panel2,
          style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
          decoration: const InputDecoration(),
          items: _languages.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _language = v);
          },
        ),
        const SizedBox(height: 16),

        _label('KECEPATAN (${_rate.toStringAsFixed(1)}x)'),
        Slider(
          value: _rate,
          min: 0.1,
          max: 1.0,
          activeColor: AppColors.cyan,
          onChanged: (v) => setState(() => _rate = v),
        ),
        _label('NADA / PITCH (${_pitch.toStringAsFixed(1)})'),
        Slider(
          value: _pitch,
          min: 0.5,
          max: 2.0,
          activeColor: AppColors.cyan,
          onChanged: (v) => setState(() => _pitch = v),
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _speaking ? null : _speak,
                child: Text(_speaking ? 'MEMBACAKAN...' : 'PUTAR SUARA'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _speaking ? _stop : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.magenta,
                side: const BorderSide(color: AppColors.magenta),
              ),
              child: const Text('STOP'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.gray, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
    );
  }
}
