import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/network/skippable_loading.dart';

class _HeaderRow {
  final keyController = TextEditingController();
  final valueController = TextEditingController();
}

class ApiTesterPage extends StatefulWidget {
  const ApiTesterPage({super.key});

  @override
  State<ApiTesterPage> createState() => _ApiTesterPageState();
}

class _ApiTesterPageState extends State<ApiTesterPage> with SkippableLoading<ApiTesterPage> {
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  String _method = 'GET';
  final List<_HeaderRow> _headers = [];

  bool _sending = false;
  int? _statusCode;
  String? _responseBody;
  Map<String, String>? _responseHeaders;
  String? _error;
  Duration? _duration;

  static const _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];

  void _addHeaderRow() => setState(() => _headers.add(_HeaderRow()));
  void _removeHeaderRow(int i) => setState(() => _headers.removeAt(i));

  Future<void> _send() async {
    final urlText = _urlController.text.trim();
    if (urlText.isEmpty) return;

    final gen = startLoading();
    setState(() {
      _sending = true;
      _error = null;
      _statusCode = null;
      _responseBody = null;
      _responseHeaders = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse(urlText);
      final headersMap = <String, String>{};
      for (final h in _headers) {
        final k = h.keyController.text.trim();
        final v = h.valueController.text.trim();
        if (k.isNotEmpty) headersMap[k] = v;
      }

      http.Response res;
      switch (_method) {
        case 'GET':
          res = await http.get(uri, headers: headersMap);
          break;
        case 'POST':
          res = await http.post(uri, headers: headersMap, body: _bodyController.text);
          break;
        case 'PUT':
          res = await http.put(uri, headers: headersMap, body: _bodyController.text);
          break;
        case 'PATCH':
          res = await http.patch(uri, headers: headersMap, body: _bodyController.text);
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: headersMap, body: _bodyController.text);
          break;
        default:
          res = await http.get(uri, headers: headersMap);
      }

      stopwatch.stop();
      if (!isCurrent(gen)) return;

      String prettyBody = res.body;
      try {
        final decoded = jsonDecode(res.body);
        prettyBody = const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        // Bukan JSON, tampilin apa adanya.
      }

      setState(() {
        _statusCode = res.statusCode;
        _responseBody = prettyBody;
        _responseHeaders = res.headers;
        _duration = stopwatch.elapsed;
      });
    } catch (e) {
      if (!isCurrent(gen)) return;
      setState(() => _error = e.toString());
    } finally {
      if (isCurrent(gen)) setState(() => _sending = false);
      stopLoading();
    }
  }

  void _skip() {
    skipLoading();
    setState(() {
      _sending = false;
      _error = 'Dibatalkan.';
    });
  }

  Color _statusColor(int code) {
    if (code >= 200 && code < 300) return AppColors.cyan;
    if (code >= 400) return AppColors.magenta;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'API', accent: 'Tester', subtitle: 'Mini-Postman, test API langsung dari app'),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _method,
                underline: const SizedBox(),
                dropdownColor: AppColors.panel,
                style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700, fontSize: 12.5),
                items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _method = v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _urlController,
                style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
                decoration: const InputDecoration(hintText: 'https://api.example.com/endpoint'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text('HEADERS', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
            const Spacer(),
            GestureDetector(
              onTap: _addHeaderRow,
              child: const Icon(Icons.add_circle_outline, color: AppColors.cyan, size: 18),
            ),
          ],
        ),
        for (var i = 0; i < _headers.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _headers[i].keyController,
                    style: const TextStyle(color: AppColors.ink, fontSize: 11.5),
                    decoration: const InputDecoration(hintText: 'Key', isDense: true),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _headers[i].valueController,
                    style: const TextStyle(color: AppColors.ink, fontSize: 11.5),
                    decoration: const InputDecoration(hintText: 'Value', isDense: true),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeHeaderRow(i),
                  icon: const Icon(Icons.close, size: 16, color: AppColors.gray),
                ),
              ],
            ),
          ),
        if (_method != 'GET' && _method != 'DELETE') ...[
          const SizedBox(height: 10),
          const Text('BODY', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.ink, fontSize: 12, fontFamily: 'monospace'),
            decoration: const InputDecoration(hintText: '{"key": "value"}'),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _sending ? null : _send,
          child: Text(_sending ? 'MENGIRIM...' : 'KIRIM REQUEST'),
        ),
        SkipButton(visible: showSkipButton, onSkip: _skip),
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
        if (_statusCode != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(_statusCode!).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$_statusCode',
                    style: TextStyle(color: _statusColor(_statusCode!), fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              if (_duration != null)
                Text('${_duration!.inMilliseconds} ms', style: const TextStyle(color: AppColors.gray, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: SelectableText(_responseBody ?? '',
                  style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontFamily: 'monospace')),
            ),
          ),
        ],
      ],
    );
  }
}
