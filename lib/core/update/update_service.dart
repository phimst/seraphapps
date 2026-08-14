import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class UpdateInfo {
  final int latestBuild;
  final int currentBuild;
  final String downloadUrl;
  final String releaseName;
  bool get hasUpdate => latestBuild > currentBuild;

  UpdateInfo({
    required this.latestBuild,
    required this.currentBuild,
    required this.downloadUrl,
    required this.releaseName,
  });
}

class UpdateException implements Exception {
  final String message;
  UpdateException(this.message);
  @override
  String toString() => message;
}

class UpdateService {
  static const String repoApi = 'https://api.github.com/repos/phimst/seraphapps/releases/latest';

  static Future<UpdateInfo> check() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    final res = await http
        .get(Uri.parse(repoApi), headers: {'Accept': 'application/vnd.github+json'});

    if (res.statusCode != 200) {
      throw UpdateException('Gagal cek update (${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    final tag = data['tag_name']?.toString() ?? 'v0'; // format "v123"
    final latestBuild = int.tryParse(tag.replaceAll('v', '')) ?? 0;

    final assets = data['assets'] as List?;
    String? apkUrl;
    if (assets != null) {
      for (final a in assets) {
        if (a['name']?.toString().endsWith('.apk') == true) {
          apkUrl = a['browser_download_url']?.toString();
          break;
        }
      }
    }
    if (apkUrl == null) {
      throw UpdateException('Release ketemu, tapi gak ada file APK-nya.');
    }

    return UpdateInfo(
      latestBuild: latestBuild,
      currentBuild: currentBuild,
      downloadUrl: apkUrl,
      releaseName: data['name']?.toString() ?? tag,
    );
  }

  /// Download APK terbaru & buka installer Android.
  /// [onProgress]: 0.0 - 1.0
  static Future<void> downloadAndInstall(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw UpdateException('Gagal download update (${response.statusCode})');
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final bytes = <int>[];

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      received += chunk.length;
      if (total > 0) onProgress?.call(received / total);
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/seraphx_update.apk');
    await file.writeAsBytes(bytes);

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw UpdateException('Gagal buka installer: ${result.message}');
    }
  }
}
