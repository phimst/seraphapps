import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin buat State yang butuh pattern: fetch API TANPA timeout ketat,
/// tapi setelah 10 detik nongolin tombol "Skip" biar user bisa batalin
/// nunggu kapan aja tanpa dipaksa nunggu (atau ke-cut paksa) di durasi
/// tertentu.
///
/// Cara pakai:
/// ```dart
/// class _MyPageState extends State<MyPage> with SkippableLoading<MyPage> {
///   Future<void> _fetch() async {
///     final gen = startLoading();
///     setState(() => _loading = true);
///     try {
///       final result = await MyService.fetch(); // gak ada .timeout()
///       if (!isCurrent(gen)) return; // user udah skip / fetch baru lain jalan
///       setState(() => _result = result);
///     } catch (e) {
///       if (!isCurrent(gen)) return;
///       setState(() => _error = e.toString());
///     } finally {
///       if (isCurrent(gen)) setState(() => _loading = false);
///       stopLoading();
///     }
///   }
/// }
/// ```
mixin SkippableLoading<T extends StatefulWidget> on State<T> {
  bool showSkipButton = false;
  int _requestGen = 0;
  Timer? _skipTimer;

  /// Panggil di awal proses fetch. Return "generation id" buat dicek pas
  /// hasil fetch udah kelar (biar gak nimpa state kalau user udah skip).
  int startLoading() {
    _requestGen++;
    final myGen = _requestGen;
    showSkipButton = false;
    _skipTimer?.cancel();
    _skipTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && myGen == _requestGen) setState(() => showSkipButton = true);
    });
    return myGen;
  }

  /// Cek apakah generation ini masih yang aktif (belum di-skip / belum
  /// ketiban fetch baru).
  bool isCurrent(int gen) => gen == _requestGen && mounted;

  /// Panggil pas fetch selesai (sukses atau gagal), buat matiin timer skip.
  void stopLoading() {
    _skipTimer?.cancel();
    if (mounted) setState(() => showSkipButton = false);
  }

  /// Panggil pas user tekan tombol Skip - bikin generation lama jadi basi
  /// (hasil fetch yang telat dateng bakal diabaikan).
  void skipLoading() {
    _requestGen++;
    _skipTimer?.cancel();
    if (mounted) setState(() => showSkipButton = false);
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    super.dispose();
  }
}

/// Widget tombol skip yang muncul dengan animasi fade.
class SkipButton extends StatelessWidget {
  final bool visible;
  final VoidCallback onSkip;
  const SkipButton({super.key, required this.visible, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: visible
          ? Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextButton(
                onPressed: onSkip,
                child: const Text(
                  'Kelamaan? Tap buat Skip/Batalkan',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
