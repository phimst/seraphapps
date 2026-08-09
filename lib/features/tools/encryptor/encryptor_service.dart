import 'dart:async';
import 'dart:convert';
import 'package:zikzak_inappwebview/zikzak_inappwebview.dart';

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
  /// dijalankan lewat WebView headless (gak keliatan di UI) karena
  /// js-confuser itu library JavaScript (npm), bukan Dart. Butuh internet
  /// buat load engine-nya dari CDN. Kalau CDN/koneksi gagal, lempar error
  /// yang jelas.
  static Future<String> encryptJs(String source, {Duration timeout = const Duration(seconds: 25)}) async {
    final completer = Completer<String>();
    HeadlessInAppWebView? headlessWebView;

    final escapedSource = jsonEncode(source);
    final html = '''
<!DOCTYPE html>
<html><body>
<script src="https://cdn.jsdelivr.net/npm/js-confuser/dist/index.js"></script>
<script>
  // Defensive: nama JS bridge global bisa beda tergantung versi/fork
  // plugin webview yang dipake, jadi coba beberapa kemungkinan nama.
  function _bridge() {
    return window.flutter_inappwebview || window.zikzak_inappwebview || null;
  }
  function _report(data) {
    var b = _bridge();
    if (b && b.callHandler) {
      b.callHandler('ObfuscateResult', data);
    }
  }
  window.onerror = function(msg) {
    _report({ok:false, error: String(msg)});
  };
  function runObfuscate() {
    try {
      JsConfuser.obfuscate($escapedSource, {
        target: "browser",
        preset: "medium"
      }).then(function(result) {
        _report({ok:true, code: result.code || result});
      }).catch(function(err) {
        _report({ok:false, error: String(err)});
      });
    } catch (e) {
      _report({ok:false, error: String(e)});
    }
  }
  setTimeout(runObfuscate, 800);
</script>
</body></html>
''';

    headlessWebView = HeadlessInAppWebView(
      initialData: InAppWebViewInitialData(data: html),
      initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'ObfuscateResult',
          callback: (args) {
            if (completer.isCompleted) return;
            try {
              final data = args.first as Map;
              if (data['ok'] == true) {
                completer.complete(data['code'] as String);
              } else {
                completer.completeError(
                    EncryptorException('Gagal obfuscate JS: ${data['error'] ?? 'unknown error'}'));
              }
            } catch (_) {
              completer.completeError(EncryptorException('Gagal parse hasil obfuscation.'));
            }
          },
        );
      },
    );

    await headlessWebView.run();

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => throw EncryptorException(
            'Timeout - kemungkinan CDN js-confuser gagal diakses atau koneksi lambat.'),
      );
    } finally {
      await headlessWebView.dispose();
    }
  }
}
