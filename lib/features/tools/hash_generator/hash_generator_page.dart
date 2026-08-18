import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class HashGeneratorPage extends StatefulWidget {
  const HashGeneratorPage({super.key});

  @override
  State<HashGeneratorPage> createState() => _HashGeneratorPageState();
}

class _HashGeneratorPageState extends State<HashGeneratorPage> {
  final _inputController = TextEditingController();
  Map<String, String>? _hashes;

  void _generate() {
    final text = _inputController.text;
    if (text.isEmpty) {
      setState(() => _hashes = null);
      return;
    }
    final bytes = utf8.encode(text);
    setState(() {
      _hashes = {
        'MD5': md5.convert(bytes).toString(),
        'SHA-1': sha1.convert(bytes).toString(),
        'SHA-256': sha256.convert(bytes).toString(),
        'SHA-512': sha512.convert(bytes).toString(),
      };
    });
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersalin ke clipboard'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Hash', accent: 'Gen', subtitle: 'Generate hash MD5, SHA1, SHA256, SHA512'),
        const SizedBox(height: 18),
        TextField(
          controller: _inputController,
          maxLines: 4,
          style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
          decoration: const InputDecoration(hintText: 'Teks yang mau di-hash...'),
          onChanged: (_) => _generate(),
        ),
        const SizedBox(height: 16),
        if (_hashes != null)
          for (final entry in _hashes!.entries) ...[
            _hashCard(entry.key, entry.value),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _hashCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: AppColors.cyan, fontSize: 10.5, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => _copy(value),
                child: const Icon(Icons.copy, size: 14, color: AppColors.gray),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(color: AppColors.ink, fontSize: 11)),
        ],
      ),
    );
  }
}
