import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class JsonFormatterPage extends StatefulWidget {
  const JsonFormatterPage({super.key});

  @override
  State<JsonFormatterPage> createState() => _JsonFormatterPageState();
}

class _JsonFormatterPageState extends State<JsonFormatterPage> {
  final _inputController = TextEditingController();
  String? _formatted;
  String? _error;

  void _format() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _formatted = null;
        _error = null;
      });
      return;
    }
    try {
      final decoded = jsonDecode(text);
      const encoder = JsonEncoder.withIndent('  ');
      setState(() {
        _formatted = encoder.convert(decoded);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _formatted = null;
        _error = 'JSON gak valid: $e';
      });
    }
  }

  void _minify() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    try {
      final decoded = jsonDecode(text);
      setState(() {
        _formatted = jsonEncode(decoded);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _formatted = null;
        _error = 'JSON gak valid: $e';
      });
    }
  }

  void _copy() {
    if (_formatted == null) return;
    Clipboard.setData(ClipboardData(text: _formatted!));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersalin ke clipboard'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'JSON', accent: 'Formatter', subtitle: 'Rapiin & validasi JSON berantakan'),
        const SizedBox(height: 18),
        TextField(
          controller: _inputController,
          maxLines: 6,
          style: const TextStyle(color: AppColors.ink, fontSize: 12, fontFamily: 'monospace'),
          decoration: const InputDecoration(hintText: 'Paste JSON di sini...'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _format,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.cyan)),
                child: const Text('FORMAT', style: TextStyle(color: AppColors.cyan)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _minify,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line)),
                child: const Text('MINIFY', style: TextStyle(color: AppColors.ink)),
              ),
            ),
          ],
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
            child: Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 12)),
          ),
        ],
        if (_formatted != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('HASIL', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
              const Spacer(),
              GestureDetector(
                onTap: _copy,
                child: const Icon(Icons.copy, size: 14, color: AppColors.gray),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(_formatted!,
                style: const TextStyle(color: AppColors.cyan, fontSize: 11.5, fontFamily: 'monospace')),
          ),
        ],
      ],
    );
  }
}
