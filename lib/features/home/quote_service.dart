import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteService {
  static const String quotesUrl =
      'https://raw.githubusercontent.com/phimst/q/refs/heads/main/q.json';

  /// Format JSON yang diharapkan: array string, contoh:
  /// ["Quote pertama", "Quote kedua"]
  /// Kalau isinya cuma 1 quote, otomatis gak akan bergeser (statis).
  static Future<List<String>> fetchQuotes() async {
    final res = await http.get(Uri.parse(quotesUrl)).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Gagal ambil quotes (${res.statusCode})');
    }
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    throw Exception('Format q.json harus berupa array string');
  }
}
