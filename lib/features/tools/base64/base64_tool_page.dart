import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class Base64ToolPage extends StatefulWidget {
  const Base64ToolPage({super.key});

  @override
  State<Base64ToolPage> createState() => _Base64ToolPageState();
}

class _Base64ToolPageState extends State<Base64ToolPage> {
  final _encodeInput = TextEditingController();
  final _decodeInput = TextEditingController();
  String _encodeOutput = '';
  String _decodeOutput = '';
  String? _decodeError;

  void _encode() {
    setState(() {
      _encodeOutput = base64Encode(utf8.encode(_encodeInput.text));
    });
  }

  void _decode() {
    try {
      setState(() {
        _decodeOutput = utf8.decode(base64Decode(_decodeInput.text.trim()));
        _decodeError = null;
      });
    } catch (e) {
      setState(() {
        _decodeOutput = '';
        _decodeError = 'Bukan Base64 yang valid.';
      });
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
                text: 'Base',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.ink)),
            TextSpan(
                text: '64',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.cyan)),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text('// encode & decode Base64',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 11)),
        const SizedBox(height: 20),

        _sectionLabel('TEXT → BASE64'),
        TextField(
          controller: _encodeInput,
          maxLines: 4,
          style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
          decoration: const InputDecoration(hintText: 'Ketik teks di sini...'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _encode, child: const Text('ENCODE')),
        if (_encodeOutput.isNotEmpty) ...[
          const SizedBox(height: 10),
          _outputBox(_encodeOutput),
        ],

        const SizedBox(height: 28),
        _sectionLabel('BASE64 → TEXT'),
        TextField(
          controller: _decodeInput,
          maxLines: 4,
          style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
          decoration: const InputDecoration(hintText: 'Tempel Base64 di sini...'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _decode,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.magenta,
            side: const BorderSide(color: AppColors.magenta),
          ),
          child: const Text('DECODE'),
        ),
        if (_decodeError != null) ...[
          const SizedBox(height: 10),
          Text(_decodeError!, style: const TextStyle(color: AppColors.magenta, fontSize: 12)),
        ],
        if (_decodeOutput.isNotEmpty) ...[
          const SizedBox(height: 10),
          _outputBox(_decodeOutput),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.gray, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _outputBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(color: AppColors.cyan, fontSize: 11.5),
      ),
    );
  }
}
