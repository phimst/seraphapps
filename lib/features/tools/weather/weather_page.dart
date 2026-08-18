import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/skippable_loading.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with SkippableLoading<WeatherPage> {
  bool _loading = true;
  String? _error;
  double? _temp;
  double? _humidity;
  double? _windSpeed;
  int? _weatherCode;
  bool _isFallbackLocation = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final gen = startLoading();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final location = await LocationService.getCurrentOrFallback();
      if (!isCurrent(gen)) return;

      final uri = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${location.lat}&longitude=${location.lon}&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m');
      final res = await http.get(uri);
      if (!isCurrent(gen)) return;
      if (res.statusCode != 200) throw Exception('Server error (${res.statusCode})');

      final data = jsonDecode(res.body);
      final current = data['current'];
      setState(() {
        _temp = (current['temperature_2m'] as num).toDouble();
        _humidity = (current['relative_humidity_2m'] as num).toDouble();
        _windSpeed = (current['wind_speed_10m'] as num).toDouble();
        _weatherCode = current['weather_code'] as int;
        _isFallbackLocation = location.isFallback;
      });
    } catch (e) {
      if (!isCurrent(gen)) return;
      setState(() => _error = e.toString());
    } finally {
      if (isCurrent(gen)) setState(() => _loading = false);
      stopLoading();
    }
  }

  void _skip() {
    skipLoading();
    setState(() {
      _loading = false;
      _error = 'Dibatalkan.';
    });
  }

  // Kode cuaca WMO standar dipake Open-Meteo, dipetain ke teks & emoji Indonesia.
  (String, IconData) _describeWeather(int code) {
    if (code == 0) return ('Cerah', Icons.wb_sunny);
    if (code <= 2) return ('Cerah Berawan', Icons.wb_cloudy);
    if (code == 3) return ('Berawan', Icons.cloud);
    if (code == 45 || code == 48) return ('Berkabut', Icons.foggy);
    if (code >= 51 && code <= 57) return ('Gerimis', Icons.grain);
    if (code >= 61 && code <= 67) return ('Hujan', Icons.water_drop);
    if (code >= 71 && code <= 77) return ('Salju', Icons.ac_unit);
    if (code >= 80 && code <= 82) return ('Hujan Deras', Icons.thunderstorm);
    if (code >= 95) return ('Badai Petir', Icons.flash_on);
    return ('Gak diketahui', Icons.help_outline);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Weath', accent: 'er', subtitle: 'Cuaca real-time lokasi kamu'),
        const SizedBox(height: 4),
        if (_loading) ...[
          const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
          Center(child: SkipButton(visible: showSkipButton, onSkip: _skip)),
        ] else if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(child: OutlinedButton(onPressed: _fetch, child: const Text('COBA LAGI'))),
        ] else if (_temp != null) ...[
          Builder(builder: (context) {
            final (label, icon) = _describeWeather(_weatherCode!);
            return Column(
              children: [
                Icon(icon, size: 64, color: AppColors.cyan),
                const SizedBox(height: 12),
                Text('${_temp!.toStringAsFixed(1)}°C',
                    style: const TextStyle(color: AppColors.ink, fontSize: 40, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 14)),
                if (_isFallbackLocation) ...[
                  const SizedBox(height: 6),
                  const Text('(lokasi fallback - GPS gak tersedia)',
                      style: TextStyle(color: AppColors.gray, fontSize: 9.5)),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _statCard('Kelembapan', '${_humidity!.toStringAsFixed(0)}%', Icons.water_drop_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('Angin', '${_windSpeed!.toStringAsFixed(1)} km/h', Icons.air)),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _fetch, child: const Text('Refresh')),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.cyan, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 10)),
        ],
      ),
    );
  }
}
