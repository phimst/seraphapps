import 'dart:convert';
import 'package:http/http.dart' as http;

class EarthquakeInfo {
  final String tanggal;
  final String jam;
  final String wilayah;
  final String magnitude;
  final String kedalaman;
  final String potensi;
  final double? lat;
  final double? lon;

  EarthquakeInfo({
    required this.tanggal,
    required this.jam,
    required this.wilayah,
    required this.magnitude,
    required this.kedalaman,
    required this.potensi,
    this.lat,
    this.lon,
  });

  factory EarthquakeInfo.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lon;
    // BMKG kasih koordinat dalam format string "7.5 LS" / "112.3 BT"
    final lintang = json['Lintang']?.toString();
    final bujur = json['Bujur']?.toString();
    if (lintang != null) lat = _parseCoord(lintang, south: 'LS', north: 'LU');
    if (bujur != null) lon = _parseCoord(bujur, south: 'BB', north: 'BT');

    return EarthquakeInfo(
      tanggal: json['Tanggal']?.toString() ?? '-',
      jam: json['Jam']?.toString() ?? '-',
      wilayah: json['Wilayah']?.toString() ?? '-',
      magnitude: json['Magnitude']?.toString() ?? '-',
      kedalaman: json['Kedalaman']?.toString() ?? '-',
      potensi: json['Potensi']?.toString() ?? '-',
      lat: lat,
      lon: lon,
    );
  }

  static double? _parseCoord(String raw, {required String south, required String north}) {
    final numPart = double.tryParse(raw.replaceAll(RegExp('[^0-9.]'), ''));
    if (numPart == null) return null;
    // LS (Lintang Selatan) & BB (Bujur Barat) -> negatif
    if (raw.contains(south)) return -numPart;
    return numPart;
  }
}

class EarthquakeService {
  /// Gempa terbaru (real-time)
  static Future<EarthquakeInfo> fetchLatest() async {
    final res = await http
        .get(Uri.parse('https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Gagal ambil data BMKG (${res.statusCode})');
    }
    final data = jsonDecode(res.body);
    final gempa = data['Infogempa']?['gempa'];
    if (gempa == null) throw Exception('Format data BMKG tidak sesuai.');
    return EarthquakeInfo.fromJson(gempa as Map<String, dynamic>);
  }

  /// 15 gempa M5.0+ terakhir
  static Future<List<EarthquakeInfo>> fetchRecent() async {
    final res = await http
        .get(Uri.parse('https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Gagal ambil data BMKG (${res.statusCode})');
    }
    final data = jsonDecode(res.body);
    final list = data['Infogempa']?['gempa'];
    if (list is! List) return [];
    return list.map((e) => EarthquakeInfo.fromJson(e as Map<String, dynamic>)).toList();
  }
}
