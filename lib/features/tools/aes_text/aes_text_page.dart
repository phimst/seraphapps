import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class AesTextPage extends StatefulWidget {
  const AesTextPage({super.key});

  @override
  State<AesTextPage> createState() => _AesTextPageState();
}

class _AesTextPageState extends State<AesTextPage> {
  bool _isEncryptMode = true;
  final _passwordController = TextEditingController();
  final _textController = TextEditingController();
  String? _result;
  String? _error;

  // Password -> key 32 byte (AES-256) pake SHA-256, biar user gak perlu
  // mikirin panjang key sendiri.
  enc.Key _deriveKey(String password) {
    final hash = sha256.convert(utf8.encode(password));
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  void _process() {
    final password = _passwordController.text;
    final text = _textController.text;
    if (password.isEmpty || text.isEmpty) {
      setState(() => _error = 'Isi password dan teks dulu.');
      return;
    }

    try {
      final key = _deriveKey(password);
      if (_isEncryptMode) {
        final iv = enc.IV.fromSecureRandom(16);
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        final encrypted = encrypter.encrypt(text, iv: iv);
        // Gabungin IV + ciphertext jadi 1 string base64, biar user cuma
        // perlu copy 1 blok teks aja (IV gak perlu disimpen terpisah).
        final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
        setState(() {
          _result = base64.encode(combined);
          _error = null;
        });
      } else {
        final combined = base64.decode(text.trim());
        if (combined.length < 17) {
          throw Exception('Teks terenkripsi gak valid/kependekan.');
        }
        final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
        final cipherBytes = combined.sublist(16);
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        final decrypted = encrypter.decrypt(enc.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
        setState(() {
          _result = decrypted;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _result = null;
        _error = _isEncryptMode
            ? 'Gagal enkripsi: $e'
            : 'Gagal dekripsi. Password salah atau teks terenkripsi gak valid.';
      });
    }
  }

  void _copy() {
    if (_result == null) return;
    Clipboard.setData(ClipboardData(text: _result!));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersalin ke clipboard'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'AES', accent: 'Text', subtitle: 'Enkripsi/dekripsi teks pake password'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _modeButton('Encrypt', _isEncryptMode, () => setState(() {
                    _isEncryptMode = true;
                    _result = null;
                    _error = null;
                  })),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _modeButton('Decrypt', !_isEncryptMode, () => setState(() {
                    _isEncryptMode = false;
                    _result = null;
                    _error = null;
                  })),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: AppColors.ink, fontSize: 13),
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          maxLines: 5,
          style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
          decoration: InputDecoration(
              hintText: _isEncryptMode ? 'Teks yang mau dienkripsi...' : 'Teks terenkripsi (base64)...'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _process,
          child: Text(_isEncryptMode ? 'ENKRIPSI' : 'DEKRIPSI'),
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
        if (_result != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('HASIL', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
              const Spacer(),
              GestureDetector(onTap: _copy, child: const Icon(Icons.copy, size: 14, color: AppColors.gray)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(_result!, style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
          ),
        ],
      ],
    );
  }

  Widget _modeButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.panel2 : AppColors.panel,
          border: Border.all(color: active ? AppColors.cyan : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? AppColors.ink : AppColors.gray, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}
