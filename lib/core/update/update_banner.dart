import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import 'update_service.dart';

class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  String _currentVersion = '-';
  UpdateInfo? _update;
  bool _checking = true;
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() => _currentVersion = '${info.version} (build ${info.buildNumber})');

      final update = await UpdateService.check();
      setState(() => _update = update);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _checking = false);
    }
  }

  Future<void> _downloadUpdate() async {
    if (_update == null) return;
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });
    try {
      await UpdateService.downloadAndInstall(
        _update!.downloadUrl,
        onProgress: (p) => setState(() => _progress = p),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(
          color: (_update?.hasUpdate ?? false) ? AppColors.cyan : AppColors.line,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('VERSI APLIKASI',
                  style: TextStyle(
                      color: AppColors.gray,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_checking)
                const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan))
              else
                GestureDetector(
                  onTap: _check,
                  child: const Icon(Icons.refresh, size: 16, color: AppColors.cyan),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_currentVersion,
              style: const TextStyle(color: AppColors.ink, fontSize: 12.5, fontWeight: FontWeight.w600)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.gray, fontSize: 10.5)),
          ],
          if (_update != null && _update!.hasUpdate) ...[
            const SizedBox(height: 10),
            Text('✓ Update tersedia: ${_update!.releaseName}',
                style: const TextStyle(color: AppColors.cyan, fontSize: 11.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
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
                  onPressed: _downloadUpdate,
                  child: const Text('DOWNLOAD & INSTALL UPDATE'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
