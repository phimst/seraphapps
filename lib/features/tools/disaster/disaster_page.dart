import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/skippable_loading.dart';
import '../browser/browser_page.dart';
import 'earthquake_service.dart';
import 'volcano_service.dart';
import 'notification_service.dart';

class DisasterPage extends StatefulWidget {
  const DisasterPage({super.key});

  @override
  State<DisasterPage> createState() => _DisasterPageState();
}

class _DisasterPageState extends State<DisasterPage> with SkippableLoading<DisasterPage> {
  bool _checking = false;
  UserLocation? _location;

  EarthquakeInfo? _quake;
  String? _quakeError;
  double? _quakeDistanceKm;

  List<VolcanoInfo>? _volcanoes;
  String? _volcanoError;

  @override
  void initState() {
    super.initState();
    _checkNow();
  }

  Future<void> _checkNow() async {
    final gen = startLoading();
    setState(() => _checking = true);

    final location = await LocationService.getCurrentOrFallback();
    if (!isCurrent(gen)) return;
    setState(() => _location = location);

    // Cek gempa (BMKG - reliable)
    try {
      final quake = await EarthquakeService.fetchLatest();
      if (!isCurrent(gen)) return;
      double? distance;
      if (quake.lat != null && quake.lon != null) {
        distance = LocationService.distanceKm(location.lat, location.lon, quake.lat!, quake.lon!);
      }
      setState(() {
        _quake = quake;
        _quakeError = null;
        _quakeDistanceKm = distance;
      });

      // Trigger notifikasi kalau gempa cukup besar & deket (radius 300km, M>=5)
      final magnitude = double.tryParse(quake.magnitude) ?? 0;
      if (distance != null && distance < 300 && magnitude >= 5.0) {
        await DisasterNotificationService.showAlert(
          title: '⚠️ Peringatan Gempa Bumi',
          body:
              'M${quake.magnitude} - ${quake.wilayah} (±${distance.toStringAsFixed(0)} km dari lokasimu)',
        );
      }
    } catch (e) {
      if (!isCurrent(gen)) return;
      setState(() {
        _quake = null;
        _quakeError = e.toString();
      });
    }

    if (!isCurrent(gen)) return;

    // Cek gunung api (MAGMA - best effort)
    try {
      final volcanoes = await VolcanoService.fetchStatus();
      if (!isCurrent(gen)) return;
      setState(() {
        _volcanoes = volcanoes;
        _volcanoError = null;
      });
      final danger = volcanoes.where((v) =>
          v.level.toLowerCase().contains('awas') || v.level.toLowerCase().contains('siaga'));
      if (danger.isNotEmpty) {
        await DisasterNotificationService.showAlert(
          title: '🌋 Peringatan Aktivitas Gunung Api',
          body: danger.map((v) => '${v.name} (${v.level})').join(', '),
        );
      }
    } catch (e) {
      if (!isCurrent(gen)) return;
      setState(() {
        _volcanoes = null;
        _volcanoError = e.toString();
      });
    }

    if (isCurrent(gen)) setState(() => _checking = false);
    stopLoading();
  }

  void _skip() {
    skipLoading();
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: 'Disaster',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.ink)),
            TextSpan(
                text: 'Watch',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.cyan)),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text('// pemantauan gempa & gunung api',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 11)),
        const SizedBox(height: 16),

        if (_location != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(_location!.isFallback ? Icons.location_off : Icons.my_location,
                    size: 14, color: AppColors.cyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _location!.isFallback
                        ? 'Lokasi gak kedeteksi, pakai default: sekitar Mojokerto'
                        : 'Lokasi: ${_location!.lat.toStringAsFixed(3)}, ${_location!.lon.toStringAsFixed(3)}',
                    style: const TextStyle(color: AppColors.gray, fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),

        ElevatedButton(
          onPressed: _checking ? null : _checkNow,
          child: Text(_checking ? 'MENGECEK...' : 'CEK SEKARANG'),
        ),
        Center(child: SkipButton(visible: showSkipButton, onSkip: _skip)),

        // ---- GEMPA ----
        const SizedBox(height: 20),
        _sectionTitle('GEMPA TERBARU (BMKG)'),
        if (_quakeError != null)
          _errorBox(_quakeError!)
        else if (_quake != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('M${_quake!.magnitude} - ${_quake!.wilayah}',
                    style: const TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                _row('Waktu', '${_quake!.tanggal} ${_quake!.jam}'),
                _row('Kedalaman', _quake!.kedalaman),
                _row('Potensi', _quake!.potensi),
                if (_quakeDistanceKm != null)
                  _row('Jarak dari lokasimu', '±${_quakeDistanceKm!.toStringAsFixed(0)} km'),
              ],
            ),
          ),

        // ---- GUNUNG API ----
        const SizedBox(height: 20),
        _sectionTitle('STATUS GUNUNG API (MAGMA)'),
        if (_volcanoError != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _errorBox(_volcanoError!),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: SafeArea(
                        child: BrowserPage(initialUrl: VolcanoService.endpoint),
                      ),
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: const BorderSide(color: AppColors.cyan),
                ),
                child: const Text('Buka MAGMA di Browser'),
              ),
            ],
          )
        else if (_volcanoes != null)
          ..._volcanoes!.map((v) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name,
                              style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5)),
                          Text(v.location,
                              style: const TextStyle(color: AppColors.gray, fontSize: 10)),
                        ],
                      ),
                    ),
                    Text(v.level,
                        style: const TextStyle(
                            color: AppColors.magenta,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.magenta, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 130,
              child: Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 11))),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.magenta.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.magenta, fontSize: 11.5)),
    );
  }
}
