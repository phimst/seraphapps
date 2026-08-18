import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class QrToolPage extends StatefulWidget {
  const QrToolPage({super.key});

  @override
  State<QrToolPage> createState() => _QrToolPageState();
}

class _QrToolPageState extends State<QrToolPage> {
  bool _isGenerateMode = true;
  final _textController = TextEditingController();
  String _qrData = '';
  final _qrKey = GlobalKey();

  String? _scannedResult;
  MobileScannerController? _scannerController;

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _startScanner() {
    _scannerController ??= MobileScannerController();
  }

  Future<void> _saveQrToGallery() async {
    try {
      final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) throw Exception('Izin akses galeri ditolak.');
      }
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Gal.putImage(file.path, album: 'SeraphX');
      await file.delete();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✓ QR tersimpan di Galeri')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
      }
    }
  }

  void _copyScanned() {
    if (_scannedResult == null) return;
    Clipboard.setData(ClipboardData(text: _scannedResult!));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersalin ke clipboard'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              const SeraphHeader(
                title: 'QR',
                accent: 'Tool',
                subtitle: 'Generate & scan QR code',
                padding: EdgeInsets.only(bottom: 14),
              ),
              Row(
                children: [
                  Expanded(
                    child: _modeButton('Generate', _isGenerateMode, () => setState(() => _isGenerateMode = true)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _modeButton('Scan', !_isGenerateMode, () {
                      setState(() => _isGenerateMode = false);
                      _startScanner();
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _isGenerateMode ? _buildGenerateUI() : _buildScanUI()),
      ],
    );
  }

  Widget _buildGenerateUI() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      children: [
        TextField(
          controller: _textController,
          maxLines: 3,
          style: const TextStyle(color: AppColors.ink, fontSize: 13),
          decoration: const InputDecoration(hintText: 'Teks atau link buat dijadiin QR...'),
          onChanged: (v) => setState(() => _qrData = v),
        ),
        const SizedBox(height: 20),
        if (_qrData.isNotEmpty) ...[
          Center(
            child: RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: QrImageView(data: _qrData, size: 220, backgroundColor: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _saveQrToGallery, child: const Text('SIMPAN KE GALERI')),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text('Ketik teks di atas buat generate QR',
                  style: TextStyle(color: AppColors.gray, fontSize: 11)),
            ),
          ),
      ],
    );
  }

  Widget _buildScanUI() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    setState(() => _scannedResult = barcodes.first.rawValue);
                  }
                },
              ),
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cyan, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _scannedResult == null
                ? const Center(
                    child: Text('Arahin kamera ke QR code', style: TextStyle(color: AppColors.gray, fontSize: 11)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('HASIL SCAN', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
                          const Spacer(),
                          GestureDetector(onTap: _copyScanned, child: const Icon(Icons.copy, size: 14, color: AppColors.gray)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.panel,
                          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SelectableText(_scannedResult!,
                            style: const TextStyle(color: AppColors.cyan, fontSize: 12.5)),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _modeButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.panel2 : AppColors.panel,
          border: Border.all(color: active ? AppColors.cyan : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? AppColors.ink : AppColors.gray, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}
