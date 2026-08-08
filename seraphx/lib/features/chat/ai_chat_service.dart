import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/app_settings.dart';

class AiChatException implements Exception {
  final String message;
  AiChatException(this.message);
  @override
  String toString() => message;
}

class AiChatService {
  /// Kirim satu pesan (single-turn) ke provider yang lagi aktif di settings.
  /// [history] opsional: list of {"role": "user"/"model", "text": "..."}
  static Future<String> sendMessage({
    required AppSettings settings,
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    final timeout = Duration(
      milliseconds: settings.requestTimeoutMs > 0 ? settings.requestTimeoutMs : 15000,
    );

    switch (settings.aiProvider) {
      case AiProvider.gemini:
        return _callGemini(settings.geminiApiKey, settings.geminiModel, message, history, timeout);
      case AiProvider.deepseek:
        return _callOpenAiCompatible(
          apiUrl: 'https://api.deepseek.com/chat/completions',
          apiKey: settings.deepseekApiKey,
          model: settings.deepseekModel,
          message: message,
          history: history,
          timeout: timeout,
        );
      case AiProvider.blackbox:
        return _callOpenAiCompatible(
          apiUrl: 'https://api.blackbox.ai/chat/completions',
          apiKey: settings.blackboxApiKey,
          model: settings.blackboxModel,
          message: message,
          history: history,
          timeout: timeout,
        );
      case AiProvider.customRest:
        return _callCustomRest(
          apiUrl: settings.customRestUrl,
          apiKey: settings.customRestApiKey,
          requestField: settings.customRequestField,
          responseField: settings.customResponseField,
          message: message,
          timeout: timeout,
        );
    }
  }

  static Future<String> _callGemini(
    String apiKey,
    String model,
    String message,
    List<Map<String, String>> history,
    Duration timeout,
  ) async {
    if (apiKey.isEmpty) {
      throw AiChatException('API Key Gemini belum diisi di Settings.');
    }
    final modelId = model.trim().isNotEmpty ? model.trim() : 'gemini-3.6-flash';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey',
    );

    final contents = [
      ...history.map((h) => {
            'role': h['role'] == 'model' ? 'model' : 'user',
            'parts': [
              {'text': h['text']}
            ],
          }),
      {
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      },
    ];

    final res = await http
        .post(url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'contents': contents}))
        .timeout(timeout);

    if (res.statusCode != 200) {
      throw AiChatException('Gemini error (${res.statusCode}): ${res.body}');
    }
    final data = jsonDecode(res.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text == null) throw AiChatException('Gemini tidak mengembalikan jawaban.');
    return text as String;
  }

  /// Dipakai buat DeepSeek & Blackbox, karena keduanya OpenAI-compatible
  /// (format /chat/completions dengan array `messages`).
  static Future<String> _callOpenAiCompatible({
    required String apiUrl,
    required String apiKey,
    required String model,
    required String message,
    required List<Map<String, String>> history,
    required Duration timeout,
  }) async {
    if (apiKey.isEmpty) {
      throw AiChatException('API Key belum diisi di Settings.');
    }
    final url = Uri.parse(apiUrl);

    final messages = [
      ...history.map((h) => {
            'role': h['role'] == 'model' ? 'assistant' : 'user',
            'content': h['text'],
          }),
      {'role': 'user', 'content': message},
    ];

    final res = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({'model': model, 'messages': messages}),
        )
        .timeout(timeout);

    if (res.statusCode != 200) {
      throw AiChatException('API error (${res.statusCode}): ${res.body}');
    }
    final data = jsonDecode(res.body);
    final text = data['choices']?[0]?['message']?['content'];
    if (text == null) throw AiChatException('Provider tidak mengembalikan jawaban.');
    return text as String;
  }

  /// Custom REST API - fleksibel karena tiap API beda-beda formatnya.
  /// - [requestField]: nama field JSON buat kirim pesan user (default "message")
  /// - [responseField]: path field JSON buat ambil balasan dari response,
  ///   support nested path pakai titik & index array, contoh:
  ///     "response"                    -> {"response": "..."}
  ///     "data.reply"                  -> {"data": {"reply": "..."}}
  ///     "choices.0.message.content"   -> format ala OpenAI
  static Future<String> _callCustomRest({
    required String apiUrl,
    required String apiKey,
    required String requestField,
    required String responseField,
    required String message,
    required Duration timeout,
  }) async {
    if (apiUrl.isEmpty) {
      throw AiChatException('URL Custom REST API belum diisi di Settings.');
    }
    final headers = <String, String>{};
    if (apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $apiKey';

    http.Response res;

    if (apiUrl.contains('{message}')) {
      // Mode GET: placeholder {message} di URL diganti pesan user (URL-encoded).
      // Contoh: https://api-kamu.com/ai?question={message}
      final finalUrl = apiUrl.replaceAll('{message}', Uri.encodeComponent(message));
      res = await http.get(Uri.parse(finalUrl), headers: headers).timeout(timeout);
    } else {
      // Mode POST: body JSON {"field": "pesan user"}
      headers['Content-Type'] = 'application/json';
      final field = requestField.trim().isNotEmpty ? requestField.trim() : 'message';
      res = await http
          .post(Uri.parse(apiUrl), headers: headers, body: jsonEncode({field: message}))
          .timeout(timeout);
    }

    if (res.statusCode != 200) {
      throw AiChatException('API error (${res.statusCode}): ${res.body}');
    }

    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      return res.body; // bukan JSON, tampilin apa adanya
    }

    final path = responseField.trim().isNotEmpty ? responseField.trim() : 'response';
    final resolved = _resolvePath(data, path);
    if (resolved != null) return resolved.toString();

    // Path custom gak ketemu -> coba tebak field umum sebagai fallback,
    // biar tetep ada jawaban daripada error total.
    for (final fallback in ['response', 'result', 'message', 'reply', 'text', 'answer']) {
      final v = _resolvePath(data, fallback);
      if (v != null) return v.toString();
    }
    return res.body; // gak ketemu sama sekali -> tampilin raw JSON
  }

  /// Resolve path kayak "choices.0.message.content" dari struktur JSON
  /// (Map/List bersarang). Return null kalau path gak valid/gak ketemu.
  static dynamic _resolvePath(dynamic data, String path) {
    dynamic current = data;
    for (final part in path.split('.')) {
      if (current is Map) {
        if (!current.containsKey(part)) return null;
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index == null || index < 0 || index >= current.length) return null;
        current = current[index];
      } else {
        return null;
      }
    }
    return current;
  }
}
