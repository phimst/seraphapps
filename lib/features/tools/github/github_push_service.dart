import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

enum PushMethod { normal, force, overwriteAll }

class GithubPushException implements Exception {
  final String message;
  GithubPushException(this.message);
  @override
  String toString() => message;
}

class GithubPushService {
  final String token;
  final String owner;
  final String repo;
  final String branch;

  GithubPushService({
    required this.token,
    required this.owner,
    required this.repo,
    required this.branch,
  });

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'Content-Type': 'application/json',
      };

  Uri _api(String path) => Uri.parse('https://api.github.com/repos/$owner/$repo/$path');

  /// Extract isi ZIP jadi Map<path, bytes>. File tersembunyi/folder di-skip.
  Map<String, Uint8List> extractZip(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final files = <String, Uint8List>{};
    for (final file in archive) {
      if (file.isFile) {
        final name = file.name;
        // skip file sistem yang gak perlu ikut ke-push
        if (name.startsWith('__MACOSX/') || name.split('/').last.startsWith('.')) continue;
        files[name] = Uint8List.fromList(file.content as List<int>);
      }
    }
    if (files.isEmpty) {
      throw GithubPushException('ZIP kosong atau gagal dibaca.');
    }
    return files;
  }

  /// Push ke GitHub. [onProgress] optional callback buat update UI progress.
  Future<String> push({
    required Map<String, Uint8List> files,
    required PushMethod method,
    void Function(String status)? onProgress,
  }) async {
    onProgress?.call('Mengecek branch...');
    final refRes = await http.get(_api('git/refs/heads/$branch'), headers: _headers);

    String? baseCommitSha;
    String? baseTreeSha;
    bool branchExists = refRes.statusCode == 200;

    if (branchExists) {
      final refData = jsonDecode(refRes.body);
      baseCommitSha = refData['object']['sha'];
      final commitRes = await http.get(_api('git/commits/$baseCommitSha'), headers: _headers);
      if (commitRes.statusCode == 200) {
        baseTreeSha = jsonDecode(commitRes.body)['tree']['sha'];
      }
    }

    onProgress?.call('Upload ${files.length} file...');
    final treeEntries = <Map<String, dynamic>>[];
    for (final entry in files.entries) {
      final blobRes = await http.post(
        _api('git/blobs'),
        headers: _headers,
        body: jsonEncode({
          'content': base64Encode(entry.value),
          'encoding': 'base64',
        }),
      );
      if (blobRes.statusCode != 201) {
        throw GithubPushException('Gagal upload file ${entry.key}: ${blobRes.body}');
      }
      final blobSha = jsonDecode(blobRes.body)['sha'];
      treeEntries.add({
        'path': entry.key,
        'mode': '100644',
        'type': 'blob',
        'sha': blobSha,
      });
    }

    onProgress?.call('Membuat tree...');
    final treeBody = <String, dynamic>{'tree': treeEntries};
    // method "overwriteAll": tree TANPA base_tree -> replace total isi repo.
    // method "normal"/"force": pake base_tree -> gabung sama file lama.
    if (method != PushMethod.overwriteAll && baseTreeSha != null) {
      treeBody['base_tree'] = baseTreeSha;
    }

    final treeRes =
        await http.post(_api('git/trees'), headers: _headers, body: jsonEncode(treeBody));
    if (treeRes.statusCode != 201) {
      throw GithubPushException('Gagal membuat tree: ${treeRes.body}');
    }
    final newTreeSha = jsonDecode(treeRes.body)['sha'];

    onProgress?.call('Membuat commit...');
    final commitMsg = switch (method) {
      PushMethod.normal => 'Push via SeraphX',
      PushMethod.force => 'Force push via SeraphX',
      PushMethod.overwriteAll => 'Overwrite all via SeraphX',
    };
    final commitBody = <String, dynamic>{
      'message': commitMsg,
      'tree': newTreeSha,
      if (baseCommitSha != null) 'parents': [baseCommitSha],
    };
    final commitRes =
        await http.post(_api('git/commits'), headers: _headers, body: jsonEncode(commitBody));
    if (commitRes.statusCode != 201) {
      throw GithubPushException('Gagal membuat commit: ${commitRes.body}');
    }
    final newCommitSha = jsonDecode(commitRes.body)['sha'];

    onProgress?.call('Update branch...');
    final forceFlag = method != PushMethod.normal;

    if (!branchExists) {
      final createRes = await http.post(
        _api('git/refs'),
        headers: _headers,
        body: jsonEncode({'ref': 'refs/heads/$branch', 'sha': newCommitSha}),
      );
      if (createRes.statusCode != 201) {
        throw GithubPushException('Gagal membuat branch baru: ${createRes.body}');
      }
    } else {
      final updateRes = await http.patch(
        _api('git/refs/heads/$branch'),
        headers: _headers,
        body: jsonEncode({'sha': newCommitSha, 'force': forceFlag}),
      );
      if (updateRes.statusCode != 200) {
        throw GithubPushException(
            'Gagal update branch (${updateRes.statusCode}): ${updateRes.body}');
      }
    }

    onProgress?.call('Selesai!');
    return newCommitSha;
  }
}
