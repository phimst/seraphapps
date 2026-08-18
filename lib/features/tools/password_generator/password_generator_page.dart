import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  double _length = 16;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _numbers = true;
  bool _symbols = true;
  String _password = '';

  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digits = '0123456789';
  static const _symbolChars = '!@#\$%^&*()_-+=[]{}?';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    var pool = '';
    if (_lowercase) pool += _lower;
    if (_uppercase) pool += _upper;
    if (_numbers) pool += _digits;
    if (_symbols) pool += _symbolChars;

    if (pool.isEmpty) {
      setState(() => _password = 'Pilih minimal 1 jenis karakter');
      return;
    }

    final random = Random.secure();
    final result = List.generate(_length.round(), (_) => pool[random.nextInt(pool.length)]).join();
    setState(() => _password = result);
  }

  double get _strengthScore {
    var pool = 0;
    if (_lowercase) pool += 26;
    if (_uppercase) pool += 26;
    if (_numbers) pool += 10;
    if (_symbols) pool += _symbolChars.length;
    if (pool == 0) return 0;
    // Perkiraan entropy bits, dinormalisasi ke 0-1 (128 bit dianggap sangat kuat)
    final entropyBits = _length * (log(pool) / log(2));
    return (entropyBits / 128).clamp(0, 1);
  }

  String get _strengthLabel {
    final s = _strengthScore;
    if (s < 0.3) return 'Lemah';
    if (s < 0.6) return 'Sedang';
    if (s < 0.85) return 'Kuat';
    return 'Sangat Kuat';
  }

  Color get _strengthColor {
    final s = _strengthScore;
    if (s < 0.3) return AppColors.magenta;
    if (s < 0.6) return Colors.orange;
    return AppColors.cyan;
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _password));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Password tersalin'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Password', accent: 'Gen', subtitle: 'Generate password random yang kuat'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(_password,
                    style: const TextStyle(
                        color: AppColors.cyan, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              ),
              IconButton(onPressed: _copy, icon: const Icon(Icons.copy, color: AppColors.gray, size: 18)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Kekuatan: ', style: const TextStyle(color: AppColors.gray, fontSize: 11)),
            Text(_strengthLabel, style: TextStyle(color: _strengthColor, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('Panjang', style: TextStyle(color: AppColors.ink, fontSize: 12)),
            const Spacer(),
            Text('${_length.round()} karakter', style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
          ],
        ),
        Slider(
          value: _length,
          min: 6,
          max: 64,
          divisions: 58,
          activeColor: AppColors.cyan,
          inactiveColor: AppColors.line,
          onChanged: (v) {
            setState(() => _length = v);
            _generate();
          },
        ),
        const SizedBox(height: 8),
        _toggleRow('Huruf Besar (A-Z)', _uppercase, (v) {
          setState(() => _uppercase = v);
          _generate();
        }),
        _toggleRow('Huruf Kecil (a-z)', _lowercase, (v) {
          setState(() => _lowercase = v);
          _generate();
        }),
        _toggleRow('Angka (0-9)', _numbers, (v) {
          setState(() => _numbers = v);
          _generate();
        }),
        _toggleRow('Simbol (!@#\$...)', _symbols, (v) {
          setState(() => _symbols = v);
          _generate();
        }),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _generate, child: const Text('GENERATE ULANG')),
      ],
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.ink, fontSize: 12.5))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
