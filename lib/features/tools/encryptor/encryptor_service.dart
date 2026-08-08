import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

enum EncryptFileType { html, php, css, js }

class EncryptorException implements Exception {
  final String message;
  EncryptorException(this.message);
  @override
  String toString() => message;
}

class EncryptorService {
  /// HTML: bungkus isi <body> jadi base64, di-decode otomatis pakai
  /// document.write(atob(...)) pas halaman dibuka. Teknik umum buat
  /// nyembunyiin source HTML dari "View Source" biasa.
  static String encryptHtml(String source) {
    final encoded = base64Encode(utf8.encode(source));
    return '''<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body>
<script>
document.write(atob("$encoded"));
</script>
</body>
</html>''';
  }

  /// PHP: teknik obfuscation klasik & umum dipakai -> eval(base64_decode(...))
  /// Kode aslinya gak kebaca langsung kalau file-nya dibuka teks biasa.
  static String encryptPhp(String source) {
    final encoded = base64Encode(utf8.encode(source));
    return '<?php eval(base64_decode(\'$encoded\')); ?>';
  }

  /// CSS: TIDAK ADA cara nyata buat "enkripsi" CSS yang tetep valid sebagai
  /// file .css biasa, karena CSS itu deklaratif (gak ada eval/decode).
  /// Jadi ini cuma MINIFY (hapus komentar & spasi berlebih) - bukan
  /// enkripsi beneran, cuma bikin agak susah dibaca.
  static String minifyCss(String source) {
    var result = source;
    result = result.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ''); // hapus komentar
    result = result.replaceAll(RegExp(r'\s+'), ' '); // rapihin whitespace
    result = result.replaceAll(RegExp(r'\s*([{}:;,])\s*'), r'$1'); // hapus spasi sekitar simbol
    result = result.replaceAll(';}', '}');
    return result.trim();
  }

  /// JS: pakai js-confuser (library JS asli, bukan buatan sendiri) yang
  /// dijalankan lewat WebView tersembunyi karena js-confuser itu library
  /// JavaScript (npm), bukan Dart. Butuh internet buat load engine-nya
  /// dari CDN. Kalau CDN/koneksi gagal, lempar error yang jelas.
  static Future<String> encryptJs(String source, {Duration timeout = const Duration(seconds: 25)}) async {
    final controller = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);

    final completer = Completer<String>();

    controller.addJavaScriptChannel(
      'ObfuscateChannel',
      onMessageReceived: (message) {
        if (!completer.isCompleted) {
          try {
            final data = jsonDecode(message.message);
            if (data['ok'] == true) {
              completer.complete(data['code'] as String);
            } else {
              completer.completeError(EncryptorException(
                  'Gagal obfuscate JS: ${data['error'] ?? 'unknown error'}'));
            }
          } catch (e) {
            completer.completeError(EncryptorException('Gagal parse hasil obfuscation.'));
          }
        }
      },
    );

    final escapedSource = jsonEncode(source);
    final html = '''
<!DOCTYPE html>
<html><body>
<script src="https://cdn.jsdelivr.net/npm/js-confuser/dist/index.js"></script>
<script>
  window.onerror = function(msg) {
    ObfuscateChannel.postMessage(JSON.stringify({ok:false, error: String(msg)}));
  };
  function runObfuscate() {
    try {
      JsConfuser.obfuscate($escapedSource, {
        target: "browser",
        preset: "medium"
      }).then(function(result) {
        ObfuscateChannel.postMessage(JSON.stringify({ok:true, code: result.code || result}));
      }).catch(function(err) {
        ObfuscateChannel.postMessage(JSON.stringify({ok:false, error: String(err)}));
      });
    } catch (e) {
      ObfuscateChannel.postMessage(JSON.stringify({ok:false, error: String(e)}));
    }
  }
  // Tunggu sebentar biar script CDN kelar ke-load sebelum dipanggil.
  setTimeout(runObfuscate, 800);
</script>
</body></html>
''';

    await controller.loadHtmlString(html);

    return completer.future.timeout(
      timeout,
      onTimeout: () => throw EncryptorException(
          'Timeout - kemungkinan CDN js-confuser gagal diakses atau koneksi lambat.'),
    );
  }
}
