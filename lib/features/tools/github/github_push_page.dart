import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/storage/settings_controller.dart';
import 'github_push_service.dart';

class GithubPushPage extends StatefulWidget {
  const GithubPushPage({super.key});

  @override
  State<GithubPushPage> createState() => _GithubPushPageState();
}

class _GithubPushPageState extends State<GithubPushPage> {
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _branchController = TextEditingController(text: 'main');

  String? _zipFileName;
  Uint8List? _zipBytes;

  PushMethod _method = PushMethod.normal;
  bool _busy = false;
  String? _status;
  String? _error;
  String? _resultSha;

  Future<void> _pickZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _zipFileName = file.name;
      _zipBytes = file.bytes;
      _error = null;
      _resultSha = null;
    });
  }

  Future<void> _push() async {
    final token = SettingsController.instance.settings.githubToken;
    if (token.isEmpty) {
      setState(() => _error = 'GitHub Token belum diisi di Settings.');
      return;
    }
    if (_zipBytes == null) {
      setState(() => _error = 'Pilih file ZIP dulu.');
      return;
    }
    if (_ownerController.text.trim().isEmpty || _repoController.text.trim().isEmpty) {
      setState(() => _error = 'Isi owner & nama repo dulu.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _resultSha = null;
      _status = 'Mulai...';
    });

    try {
      final service = GithubPushService(
        token: token,
        owner: _ownerController.text.trim(),
        repo: _repoController.text.trim(),
        branch: _branchController.text.trim().isEmpty ? 'main' : _branchController.text.trim(),
      );
      final files = service.extractZip(_zipBytes!);
      final sha = await service.push(
        files: files,
        method: _method,
        onProgress: (s) => setState(() => _status = s),
      );
      setState(() => _resultSha = sha);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'GitHub', accent: 'Push', subtitle: 'Upload ZIP, push langsung ke repo'),
        const SizedBox(height: 18),

        OutlinedButton.icon(
          onPressed: _busy ? null : _pickZip,
          icon: const Icon(Icons.folder_zip_outlined, color: AppColors.cyan),
          label: Text(_zipFileName ?? 'Pilih File ZIP',
              style: const TextStyle(color: AppColors.ink)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.line),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 14),
        _field(_ownerController, 'Owner / Username GitHub', 'contoh: phimst'),
        const SizedBox(height: 10),
        _field(_repoController, 'Nama Repository', 'contoh: seraph-wabot'),
        const SizedBox(height: 10),
        _field(_branchController, 'Branch', 'main'),
        const SizedBox(height: 16),

        const Text('METODE PUSH',
            style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        _methodTile(PushMethod.normal, 'Push Biasa', 'Gabung dengan file yang sudah ada'),
        _methodTile(PushMethod.force, 'Force Push', 'Timpa history, replace paksa'),
        _methodTile(
            PushMethod.overwriteAll, 'Timpa Semua', 'Hapus semua file lama, ganti total isi ZIP'),

        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _busy ? null : _push,
          child: _busy
              ? SizedBox(
                  height: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF06110E))),
                      const SizedBox(width: 8),
                      Text(_status ?? 'Memproses...'),
                    ],
                  ),
                )
              : const Text('PUSH SEKARANG'),
        ),

        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 12)),
        ],
        if (_resultSha != null) ...[
          const SizedBox(height: 14),
          Text('✓ Push berhasil. Commit: ${_resultSha!.substring(0, 7)}',
              style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _field(TextEditingController c, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _methodTile(PushMethod method, String title, String desc) {
    final selected = _method == method;
    return GestureDetector(
      onTap: () => setState(() => _method = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: selected ? AppColors.cyan : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.cyan : AppColors.gray,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  Text(desc, style: const TextStyle(color: AppColors.gray, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
