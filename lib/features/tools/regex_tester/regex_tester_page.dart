import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class RegexTesterPage extends StatefulWidget {
  const RegexTesterPage({super.key});

  @override
  State<RegexTesterPage> createState() => _RegexTesterPageState();
}

class _RegexTesterPageState extends State<RegexTesterPage> {
  final _patternController = TextEditingController();
  final _testController = TextEditingController();
  bool _caseInsensitive = false;
  bool _multiline = false;
  bool _dotAll = false;

  List<RegExpMatch>? _matches;
  String? _error;

  void _test() {
    final pattern = _patternController.text;
    final testText = _testController.text;
    if (pattern.isEmpty) {
      setState(() {
        _matches = null;
        _error = null;
      });
      return;
    }
    try {
      final regex = RegExp(pattern,
          caseSensitive: !_caseInsensitive, multiLine: _multiline, dotAll: _dotAll);
      setState(() {
        _matches = regex.allMatches(testText).toList();
        _error = null;
      });
    } catch (e) {
      setState(() {
        _matches = null;
        _error = 'Pattern regex gak valid: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Regex', accent: 'Tester', subtitle: 'Test regex pattern, langsung liat hasil match'),
        const SizedBox(height: 18),
        TextField(
          controller: _patternController,
          style: const TextStyle(color: AppColors.cyan, fontSize: 13, fontFamily: 'monospace'),
          decoration: const InputDecoration(hintText: r'Pattern, misal: \d+'),
          onChanged: (_) => _test(),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            _flagChip('i (case insensitive)', _caseInsensitive, (v) {
              setState(() => _caseInsensitive = v);
              _test();
            }),
            _flagChip('m (multiline)', _multiline, (v) {
              setState(() => _multiline = v);
              _test();
            }),
            _flagChip('s (dotAll)', _dotAll, (v) {
              setState(() => _dotAll = v);
              _test();
            }),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _testController,
          maxLines: 6,
          style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
          decoration: const InputDecoration(hintText: 'Teks yang mau ditest...'),
          onChanged: (_) => _test(),
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
        if (_matches != null) ...[
          const SizedBox(height: 14),
          Text('${_matches!.length} MATCH DITEMUKAN',
              style: const TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          for (var i = 0; i < _matches!.length; i++) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.panel,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Match #${i + 1} (posisi ${_matches![i].start}-${_matches![i].end})',
                      style: const TextStyle(color: AppColors.gray, fontSize: 9.5)),
                  const SizedBox(height: 3),
                  SelectableText(_matches![i].group(0) ?? '',
                      style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _flagChip(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? AppColors.cyan.withValues(alpha: 0.15) : AppColors.panel,
          border: Border.all(color: value ? AppColors.cyan : AppColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(color: value ? AppColors.cyan : AppColors.gray, fontSize: 10.5)),
      ),
    );
  }
}
