import 'dart:convert';
import 'package:http/http.dart' as http;

class VolcanoStatusException implements Exception {
  final String message;
  VolcanoStatusException(this.message);
  @override
  String toString() => message;
}

class VolcanoInfo {
  final String name;
  final String level;
  final String location;
  VolcanoInfo({required this.name, required this.level, required this.location});
}

class VolcanoService {
  static const String endpoint = 'https://magma.esdm.go.id/v1/gunung-api/tingkat-aktivitas';

  /// MAGMA ESDM gak punya API publik resmi & situsnya ada proteksi anti-bot,
  /// jadi ini best-effort. Kalau gagal (diblokir/format berubah), lempar
  /// exception yang jelas biar UI bisa kasih tau user & tawarin buka manual
  /// lewat Browser (yang render kayak browser asli, biasanya lolos proteksi).
  static Future<List<VolcanoInfo>> fetchStatus() async {
    final res = await http.get(
      Uri.parse(endpoint),
      headers: {'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw VolcanoStatusException('MAGMA API tidak bisa diakses (${res.statusCode}).');
    }

    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      throw VolcanoStatusException(
          'MAGMA tidak mengembalikan data JSON (kemungkinan diblokir sistem mereka).');
    }

    final list = <VolcanoInfo>[];
    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          list.add(VolcanoInfo(
            name: item['nama']?.toString() ?? item['name']?.toString() ?? '-',
            level: item['tingkat_aktivitas']?.toString() ?? item['level']?.toString() ?? '-',
            location: item['lokasi']?.toString() ?? item['location']?.toString() ?? '-',
          ));
        }
      }
    }
    if (list.isEmpty) {
      throw VolcanoStatusException('MAGMA tidak mengembalikan data yang bisa dibaca.');
    }
    return list;
  }
}
