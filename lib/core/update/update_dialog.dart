import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'update_service.dart';

/// Cek update diam-diam (gak nampilin apapun kalau masih versi terbaru).
/// Kalau ada versi baru, baru muncul dialog - dengan tombol "Update
/// Sekarang" dan tombol X buat nutup/skip.
Future<void> checkAndShowUpdateDialog(BuildContext context) async {
  UpdateInfo update;
  try {
    update = await UpdateService.check();
  } catch (_) {
    return; // gagal cek (misal gak ada internet) -> diem aja, jangan ganggu user
  }

  if (!update.hasUpdate) return; // udah versi terbaru -> gak perlu nampilin apapun
  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => _UpdateDialog(update: update),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo update;
  const _UpdateDialog({required this.update});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });
    try {
      await UpdateService.downloadAndInstall(
        widget.update.downloadUrl,
        onProgress: (p) => setState(() => _progress = p),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cyan),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update, color: AppColors.cyan, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Update Tersedia',
                      style: TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: AppColors.gray, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Ada versi baru SeraphX: ${widget.update.releaseName}',
              style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
            ),
            const SizedBox(height: 4),
            const Text(
              'Update sekarang biar dapet fitur & perbaikan terbaru.',
              style: TextStyle(color: AppColors.gray, fontSize: 11),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 11)),
            ],
            const SizedBox(height: 16),
            if (_downloading) ...[
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                color: AppColors.cyan,
                backgroundColor: AppColors.line,
              ),
              const SizedBox(height: 6),
              Text('${(_progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.gray, fontSize: 10)),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _download,
                  child: const Text('UPDATE SEKARANG'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
