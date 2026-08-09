import 'dart:convert';
import 'package:http/http.dart' as http;

class TikTokResult {
  final String username;
  final String avatarUrl;
  final String thumbnail;
  final String videoUrl; // no-watermark, buat preview/play
  final String downloadUrl; // link direct download (ada expiry token)
  final String? audioUrl;
  final int videoDuration;
  final int playCount;

  TikTokResult({
    required this.username,
    required this.avatarUrl,
    required this.thumbnail,
    required this.videoUrl,
    required this.downloadUrl,
    required this.audioUrl,
    required this.videoDuration,
    required this.playCount,
  });

  factory TikTokResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    final postinfo = result['postinfo'];
    final item = (result['items'] as List).first;
    final stats = (result['raw_data']?['data'] as List?)?.isNotEmpty == true
        ? result['raw_data']['data'][0]['stats']
        : null;

    return TikTokResult(
      username: postinfo?['username'] ?? '-',
      avatarUrl: postinfo?['avatar_url'] ?? '',
      thumbnail: item['thumbnail'] ?? '',
      videoUrl: item['videoUrl'] ?? '',
      downloadUrl: item['downloadUrl'] ?? item['videoUrl'] ?? '',
      audioUrl: item['audioUrl'],
      videoDuration: item['videoDuration'] ?? 0,
      playCount: stats?['playCount'] ?? 0,
    );
  }
}

class TikTokService {
  static const _baseUrl = 'https://myputraapi.vercel.app/api/downloader/tiktok/v2';

  static Future<TikTokResult> fetch(String tiktokUrl) async {
    final url = Uri.parse('$_baseUrl?url=${Uri.encodeComponent(tiktokUrl)}');
    final res = await http.get(url).timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('Server error (${res.statusCode})');
    }
    final data = jsonDecode(res.body);
    if (data['status'] != true) {
      throw Exception('Link TikTok tidak valid atau video tidak ditemukan.');
    }
    return TikTokResult.fromJson(data);
  }
}
