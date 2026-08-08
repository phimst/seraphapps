import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Semua data SeraphX (settings + file hasil download) disimpen di folder
/// khusus app: /storage/emulated/0/Android/data/com.seraph.apps/files/seraphapps/
///
/// Ini folder "app-specific external storage" - beda dari folder custom di
/// root storage. Keuntungannya: TIDAK BUTUH permission MANAGE_EXTERNAL_STORAGE
/// (yang sering gagal/rewel di banyak HP, terutama MIUI/Redmi). Akses ke
/// folder ini otomatis diizinkan OS untuk app kita sendiri, jadi gak akan
/// pernah muncul error "Permission denied" lagi.
///
/// Cara buka folder ini manual: pakai file manager yang bisa browse
/// Android/data (misal: MT Manager, Solid Explorer, Termux dengan
/// `termux-setup-storage` lalu akses
/// `~/storage/shared/Android/data/com.seraph.apps/files/seraphapps/`)
class StorageService {
  static const String rootFolderName = 'seraphapps';

  static Future<String> get rootPath async {
    final base = await getExternalStorageDirectory();
    if (base == null) {
      throw Exception('Tidak bisa akses storage device.');
    }
    final dir = Directory('${base.path}/$rootFolderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> subPath(String folder) async {
    final root = await rootPath;
    final dir = Directory('$root/$folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  // ---------- SETTINGS (JSON file) ----------

  static Future<File> get _settingsFile async {
    final root = await rootPath;
    return File('$root/settings.json');
  }

  static Future<Map<String, dynamic>> loadSettings() async {
    try {
      final file = await _settingsFile;
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      if (content.trim().isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      // File korup/gak kebaca -> jangan crash, mulai dari kosong.
      return {};
    }
  }

  static Future<void> saveSettings(Map<String, dynamic> data) async {
    final file = await _settingsFile;
    await file.writeAsString(jsonEncode(data));
  }

  // ---------- GENERIC FILE SAVE (buat tiktok downloader, dll) ----------

  static Future<File> saveBytesToFolder({
    required String folder,
    required String fileName,
    required List<int> bytes,
  }) async {
    final dirPath = await subPath(folder);
    final file = File('$dirPath/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }
}
