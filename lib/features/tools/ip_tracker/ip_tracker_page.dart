import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/network/skippable_loading.dart';
import 'ip_tracker_service.dart';

class IpTrackerPage extends StatefulWidget {
  const IpTrackerPage({super.key});

  @override
  State<IpTrackerPage> createState() => _IpTrackerPageState();
}

class _IpTrackerPageState extends State<IpTrackerPage> with SkippableLoading<IpTrackerPage> {
  final _ipController = TextEditingController();
  IpInfo? _info;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMine();
  }

  Future<void> _fetchMine() async {
    final gen = startLoading();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await IpTrackerService.fetchMyIp();
      if (!isCurrent(gen)) return;
      setState(() => _info = info);
    } catch (e) {
      if (!isCurrent(gen)) return;
      setState(() => _error = e.toString());
    } finally {
      if (isCurrent(gen)) setState(() => _loading = false);
      stopLoading();
    }
  }

  Future<void> _fetchCustom() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;
    final gen = startLoading();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await IpTrackerService.fetchIp(ip);
      if (!isCurrent(gen)) return;
      setState(() => _info = info);
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'IP', accent: 'Tracker', subtitle: 'Lacak info lengkap IP address'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ipController,
                style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
                decoration:
                    const InputDecoration(hintText: 'Cek IP lain (kosongin buat IP sendiri)'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _loading ? null : _fetchCustom,
              child: const Text('CEK'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading ? null : _fetchMine,
          child: const Text('↻ Cek IP sendiri', style: TextStyle(color: AppColors.cyan, fontSize: 11)),
        ),
        if (_loading) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan)),
          Center(child: SkipButton(visible: showSkipButton, onSkip: _skip)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 12)),
        ],
        if (_info != null && !_loading) ...[
          const SizedBox(height: 20),
          _section('IDENTITAS', [
            _row('IP Address', _info!.get('ip')),
            _row('Tipe', _info!.get('type')),
            _row('Benua', _info!.get('continent')),
          ]),
          _section('LOKASI', [
            _row('Kota', _info!.get('city')),
            _row('Region', _info!.get('region')),
            _row('Negara', '${_info!.get('country')} (${_info!.get('country_code')})'),
            _row('Ibukota', _info!.get('capital')),
            _row('Kode Pos', _info!.get('postal')),
            _row('Koordinat', '${_info!.get('latitude')}, ${_info!.get('longitude')}'),
          ]),
          _section('JARINGAN', [
            _row('ISP', _info!.nested('connection', 'isp')),
            _row('Organisasi', _info!.nested('connection', 'org')),
            _row('ASN', _info!.nested('connection', 'asn')),
            _row('Domain', _info!.nested('connection', 'domain')),
          ]),
          _section('LAINNYA', [
            _row('Timezone', _info!.nested('timezone', 'id')),
            _row('Waktu Sekarang', _info!.nested('timezone', 'current_time')),
            _row('Mata Uang', '${_info!.nested('currency', 'code')} (${_info!.nested('currency', 'name')})'),
            _row('Kode Telepon', '+${_info!.get('calling_code')}'),
          ]),
        ],
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.magenta,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 11.5)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.ink, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
