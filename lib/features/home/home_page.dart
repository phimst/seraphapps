import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/storage/storage_service.dart';
import 'quote_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _model = '-';
  String _androidVersion = '-';
  String _battery = '-';
  String _network = 'Mengecek...';
  String _appStorage = '-';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadBattery();
    _loadNetwork();
    _loadAppStorage();
  }

  Future<void> _loadDeviceInfo() async {
    if (!Platform.isAndroid) return;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      if (!mounted) return;
      setState(() {
        _model = info.model;
        _androidVersion = 'Android ${info.version.release}';
      });
    } catch (_) {
      // gagal ambil info device -> biarin default "-", jangan crash
    }
  }

  Future<void> _loadBattery() async {
    try {
      final level = await Battery().batteryLevel;
      if (!mounted) return;
      setState(() => _battery = '$level%');
    } catch (_) {
      if (mounted) setState(() => _battery = 'N/A');
    }
  }

  Future<void> _loadNetwork() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (!mounted) return;
      setState(() => _network = _networkLabel(result));
      Connectivity().onConnectivityChanged.listen((r) {
        if (mounted) setState(() => _network = _networkLabel(r));
      });
    } catch (_) {
      if (mounted) setState(() => _network = 'N/A');
    }
  }

  String _networkLabel(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.wifi)) return 'WiFi Terhubung';
    if (result.contains(ConnectivityResult.mobile)) return 'Data Seluler';
    if (result.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    if (result.contains(ConnectivityResult.none) || result.isEmpty) return 'Offline';
    return 'Terhubung';
  }

  Future<void> _loadAppStorage() async {
    try {
      final root = await StorageService.rootPath;
      final dir = Directory(root);
      int totalBytes = 0;
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalBytes += await entity.length();
          }
        }
      }
      final mb = totalBytes / (1024 * 1024);
      if (!mounted) return;
      setState(() {
        _appStorage = mb < 1 ? '${totalBytes ~/ 1024} KB' : '${mb.toStringAsFixed(1)} MB';
      });
    } catch (_) {
      if (mounted) setState(() => _appStorage = 'N/A');
    }
  }

  bool get _networkConnected => _network != 'Offline' && _network != 'Mengecek...' && _network != 'N/A';

  @override
  Widget build(BuildContext context) {
    final imageUrl = SettingsController.instance.settings.dashboardImageUrl;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbFallback(),
                  )
                else
                  _thumbFallback(),
                const Positioned(
                  top: 16,
                  left: 20,
                  child: Text('01 / DASH',
                      style: TextStyle(color: AppColors.cyan, fontSize: 11, letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: Column(
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'Seraph',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 32, color: AppColors.ink)),
                  TextSpan(
                      text: 'Apps',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 32, color: AppColors.cyan)),
                ]),
              ),
              SizedBox(height: 8),
              Text('// system online',
                  style: TextStyle(color: AppColors.gray, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const QuoteCard(),
        Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 22), height: 1, color: AppColors.line),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('DEVICE INFO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.magenta,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.1,
                children: [
                  _cell('PERANGKAT', _model),
                  _cell('SISTEM', _androidVersion),
                  _cell('BATERAI', _battery),
                  _cell('DATA APP', _appStorage),
                ],
              ),
              const SizedBox(height: 10),
              _wideCell(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _thumbFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.panel2, AppColors.bg],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.gray, size: 32),
      ),
    );
  }

  Widget _cell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.gray, fontSize: 9.5, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _wideCell() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('JARINGAN', style: TextStyle(color: AppColors.gray, fontSize: 9.5)),
              const SizedBox(height: 4),
              Row(children: [
                _Led(active: _networkConnected),
                const SizedBox(width: 6),
                Text(_network,
                    style: const TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _Led extends StatelessWidget {
  final bool active;
  const _Led({this.active = true});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.cyan : AppColors.magenta,
        shape: BoxShape.circle,
      ),
    );
  }
}
