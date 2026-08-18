import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import 'steganography_service.dart';

class SteganographyPage extends StatefulWidget {
  const SteganographyPage({super.key});

  @override
  State<SteganographyPage> createState() => _SteganographyPageState();
}

class _SteganographyPageState extends State<SteganographyPage> {
  bool _isEncodeMode = true;

  // Encode state
  Uint8List? _sourceImageBytes;
  final _secretTextController = TextEditingController();
  Uint8List? _resultImageBytes;

  // Decode state
  Uint8List? _decodeImageBytes;
  String? _decodedText;

  bool _busy = false;
  String? _error;
  String? _successMessage;

  Future<void> _pickImage({required bool forDecode}) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    setState(() {
      _error = null;
      _successMessage = null;
      if (forDecode) {
        _decodeImageBytes = bytes;
        _decodedText = null;
      } else {
        _sourceImageBytes = bytes;
        _resultImageBytes = null;
      }
    });
  }

  Future<void> _encode() async {
    if (_sourceImageBytes == null || _secretTextController.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final result = await Future(
          () => SteganographyService.encode(_sourceImageBytes!, _secretTextController.text));
      setState(() => _resultImageBytes = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _decode() async {
    if (_decodeImageBytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _decodedText = null;
    });
    try {
      final text = await Future(() => SteganographyService.decode(_decodeImageBytes!));
      if (text == null) {
        setState(() => _error =
            'Gak ketemu pesan tersembunyi. Gambar ini bukan hasil steganography SeraphX, atau udah kekompresi (misal disave ulang sebagai JPG).');
      } else {
        setState(() => _decodedText = text);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_resultImageBytes == null) return;
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) throw Exception('Izin akses galeri ditolak.');
      }
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/stego_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(_resultImageBytes!);
      await Gal.putImage(file.path, album: 'SeraphX');
      await file.delete();
      setState(() => _successMessage = '✓ Tersimpan di Galeri (album "SeraphX")');
    } catch (e) {
      setState(() => _error = 'Gagal simpan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Stega', accent: 'nography', subtitle: 'Sembunyiin pesan rahasia di dalam gambar'),
        const SizedBox(height: 18),

        // Toggle mode
        Row(
          children: [
            Expanded(child: _modeButton('Sembunyiin Teks', _isEncodeMode, () => setState(() {
                  _isEncodeMode = true;
                  _error = null;
                })),),
            const SizedBox(width: 8),
            Expanded(child: _modeButton('Baca Pesan', !_isEncodeMode, () => setState(() {
                  _isEncodeMode = false;
                  _error = null;
                })),),
          ],
        ),
        const SizedBox(height: 18),

        if (_isEncodeMode) _buildEncodeUI() else _buildDecodeUI(),

        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.magenta.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 11.5)),
          ),
        ],
        if (_successMessage != null) ...[
          const SizedBox(height: 14),
          Text(_successMessage!, style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildEncodeUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickImage(forDecode: false),
          icon: const Icon(Icons.image_outlined, color: AppColors.cyan),
          label: Text(_sourceImageBytes == null ? 'Pilih Gambar' : 'Ganti Gambar',
              style: const TextStyle(color: AppColors.ink)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        if (_sourceImageBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(_sourceImageBytes!, height: 160, fit: BoxFit.cover),
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _secretTextController,
          maxLines: 4,
          style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
          decoration: const InputDecoration(hintText: 'Pesan rahasia yang mau disembunyiin...'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: (_busy || _sourceImageBytes == null) ? null : _encode,
          child: Text(_busy ? 'MEMPROSES...' : 'SEMBUNYIIN PESAN'),
        ),
        if (_resultImageBytes != null) ...[
          const SizedBox(height: 18),
          const Text('HASIL (PNG - jangan disave sebagai JPG!)',
              style: TextStyle(color: AppColors.gray, fontSize: 10)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(_resultImageBytes!, height: 200, fit: BoxFit.contain),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _saveToGallery, child: const Text('SIMPAN KE GALERI')),
        ],
      ],
    );
  }

  Widget _buildDecodeUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickImage(forDecode: true),
          icon: const Icon(Icons.image_search, color: AppColors.cyan),
          label: Text(_decodeImageBytes == null ? 'Pilih Gambar' : 'Ganti Gambar',
              style: const TextStyle(color: AppColors.ink)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        if (_decodeImageBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(_decodeImageBytes!, height: 160, fit: BoxFit.cover),
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: (_busy || _decodeImageBytes == null) ? null : _decode,
          child: Text(_busy ? 'MEMBACA...' : 'BACA PESAN TERSEMBUNYI'),
        ),
        if (_decodedText != null) ...[
          const SizedBox(height: 16),
          const Text('PESAN DITEMUKAN',
              style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(_decodedText!,
                style: const TextStyle(color: AppColors.cyan, fontSize: 12.5)),
          ),
        ],
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
                color: active ? AppColors.ink : AppColors.gray,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      ),
    );
  }
}
