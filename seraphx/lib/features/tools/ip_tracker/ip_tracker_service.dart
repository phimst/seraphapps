import 'dart:convert';
import 'package:http/http.dart' as http;

class IpInfo {
  final Map<String, dynamic> raw;
  IpInfo(this.raw);

  String get(String key) => raw[key]?.toString() ?? '-';

  String nested(String parentKey, String childKey) {
    final parent = raw[parentKey];
    if (parent is Map) return parent[childKey]?.toString() ?? '-';
    return '-';
  }
}

class IpTrackerService {
  /// ipwho.is: HTTPS, gratis, gak perlu API key, gak ada limit ketat
  /// buat pemakaian personal. Datanya lengkap (geolokasi, ISP, ASN,
  /// timezone, currency, dll).
  static Future<IpInfo> fetchMyIp() async {
    final res = await http
        .get(Uri.parse('https://ipwho.is/'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Gagal ambil data IP (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == false) {
      throw Exception(data['message'] ?? 'Gagal ambil data IP');
    }
    return IpInfo(data);
  }

  /// Cek IP address tertentu (bukan IP sendiri)
  static Future<IpInfo> fetchIp(String ip) async {
    final res = await http
        .get(Uri.parse('https://ipwho.is/$ip'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Gagal ambil data IP (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == false) {
      throw Exception(data['message'] ?? 'IP tidak valid / gagal dicek');
    }
    return IpInfo(data);
  }
}
