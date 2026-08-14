import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/network/skippable_loading.dart';
import 'tiktok_service.dart';

class TikTokDownloaderPage extends StatefulWidget {
  const TikTokDownloaderPage({super.key});

  @override
  State<TikTokDownloaderPage> createState() => _TikTokDownloaderPageState();
}

class _TikTokDownloaderPageState extends State<TikTokDownloaderPage>
    with SkippableLoading<TikTokDownloaderPage> {
  final _linkController = TextEditingController();
  TikTokResult? _result;
  bool _loading = false;
  bool _downloading = false;
  String? _error;
  String? _savedMessage;

  Future<void> _fetch() async {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;

    final gen = startLoading();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _savedMessage = null;
    });

    try {
      final result = await TikTokService.fetch(link);
      if (!isCurrent(gen)) return;
      setState(() => _result = result);
    } catch (e) {
      if (!isCurrent(gen)) return;
      setState(() => _error = e.toString());
    } finally {
      if (isCurrent(gen)) setState(() => _loading = false);
      stopLoading();
    }
  }

  void _skipFetch() {
    skipLoading();
    setState(() {
      _loading = false;
      _error = 'Dibatalkan.';
    });
  }

  Future<void> _download({required bool audioOnly}) async {
    if (_result == null) return;
    setState(() {
      _downloading = true;
      _savedMessage = null;
      _error = null;
    });

    try {
      final targetUrl = audioOnly ? (_result!.audioUrl ?? '') : _result!.downloadUrl;
      if (targetUrl.isEmpty) throw Exception('Link download tidak tersedia.');

      final res = await http.get(Uri.parse(targetUrl)).timeout(const Duration(minutes: 5));
      if (res.statusCode != 200) throw Exception('Gagal download (${res.statusCode})');

      if (audioOnly) {
        // Audio bukan tipe media galeri -> tetap simpan di folder app SeraphX.
        final file = await StorageService.saveBytesToFolder(
          folder: 'tiktok',
          fileName: 'tiktok_${DateTime.now().millisecondsSinceEpoch}.mp3',
          bytes: res.bodyBytes,
        );
        setState(() => _savedMessage = 'Audio tersimpan di folder app: ${file.path}');
      } else {
        // Video -> simpan ke galeri asli device pakai Gal, biar keliatan
        // di aplikasi Galeri/Google Photos, bukan cuma folder app.
        final hasAccess = await Gal.hasAccess(toAlbum: true);
        if (!hasAccess) {
          final granted = await Gal.requestAccess(toAlbum: true);
          if (!granted) {
            throw Exception('Izin akses galeri ditolak. Aktifkan di Pengaturan HP.');
          }
        }

        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
            '${tempDir.path}/tiktok_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await tempFile.writeAsBytes(res.bodyBytes);

        await Gal.putVideo(tempFile.path, album: 'SeraphX');
        await tempFile.delete();

        setState(() => _savedMessage = '✓ Video tersimpan di Galeri (album "SeraphX")');
      }
    } catch (e) {
      setState(() => _error = 'Gagal download: $e');
    } finally {
      setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: 'TikTok',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.ink)),
            TextSpan(
                text: 'DL',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.cyan)),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text('// tempel link video TikTok',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 11)),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _linkController,
                style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
                decoration: const InputDecoration(hintText: 'https://vm.tiktok.com/...'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _loading ? null : _fetch,
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06110E)))
                  : const Text('CEK'),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 12)),
        ],
        SkipButton(visible: showSkipButton, onSkip: _skipFetch),
        if (_result != null) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_result!.thumbnail.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(_result!.thumbnail, fit: BoxFit.cover),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('@${_result!.username}',
                          style: const TextStyle(
                              color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        'Durasi: ${_result!.videoDuration}s  •  ${_result!.playCount} views',
                        style: const TextStyle(color: AppColors.gray, fontSize: 10.5),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _downloading ? null : () => _download(audioOnly: false),
                              child: const Text('DOWNLOAD VIDEO'),
                            ),
                          ),
                        ],
                      ),
                      if (_result!.audioUrl != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _downloading ? null : () => _download(audioOnly: true),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.magenta,
                              side: const BorderSide(color: AppColors.magenta),
                            ),
                            child: const Text('DOWNLOAD AUDIO'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_downloading) ...[
          const SizedBox(height: 14),
          const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan)),
        ],
        if (_savedMessage != null) ...[
          const SizedBox(height: 14),
          Text(_savedMessage!, style: const TextStyle(color: AppColors.cyan, fontSize: 11)),
        ],
      ],
    );
  }
}
