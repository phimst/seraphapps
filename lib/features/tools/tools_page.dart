import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'tiktok/tiktok_downloader_page.dart';
import 'github/github_push_page.dart';
import 'browser/browser_page.dart';
import 'ip_tracker/ip_tracker_page.dart';
import 'base64/base64_tool_page.dart';
import 'tts/tts_page.dart';
import 'disaster/disaster_page.dart';
import 'encryptor/encryptor_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: 'Seraph',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.ink)),
            TextSpan(
                text: 'Tools',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.cyan)),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text('// pilih tool yang mau dipakai',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 11)),
        const SizedBox(height: 18),
        _toolCard(
          context,
          icon: Icons.music_note_outlined,
          name: 'TikTok Downloader',
          desc: 'Download video/audio TikTok tanpa watermark',
          page: const TikTokDownloaderPage(),
        ),
        const SizedBox(height: 10),
        _toolCard(
          context,
          icon: Icons.upload_file_outlined,
          name: 'GitHub Push',
          desc: 'Upload ZIP dan push langsung ke repository',
          page: const GithubPushPage(),
        ),
        const SizedBox(height: 10),
        _toolCard(
          context,
          icon: Icons.public,
          name: 'Browser',
          desc: 'Browsing langsung dari Google, tanpa login',
          page: const BrowserPage(),
        ),
        const SizedBox(height: 10),
        _toolCard(
          context,
          icon: Icons.wifi_tethering,
          name: 'IP Tracker',
          desc: 'Lacak info lengkap IP address (lokasi, ISP, dll)',
          page: const IpTrackerPage(),
        ),
        const SizedBox(height: 10),
        _toolCard(
          context,
          icon: Icons.code,
          name: 'Base64 Encoder/Decoder',
          desc: 'Convert teks ke Base64 dan sebaliknya',
          page: const Base64ToolPage(),
        ),
        const SizedBox(height: 10),
        _toolCard(
          context,
          icon: Icons.record_voice_over_outlined,
          name: 'Text to Speech',
          desc: 'Ubah teks jadi suara',
          page: const TtsPage(),
        ),
        const SizedBox(height: 10),
        _toolCard(
          context,
          icon: Icons.warning_amber_rounded,
          name: 'Disaster Watch',
          desc: 'Pantau gempa (BMKG) & gunung api (MAGMA) di sekitar lokasimu',
          page: const DisasterPage(),
        ),
        const SizedBox(height: 10),
        _toolCard(
          context,
          icon: Icons.enhanced_encryption_outlined,
          name: 'Code Encryptor',
          desc: 'Obfuscate HTML, PHP, CSS, JS (JS pakai js-confuser)',
          page: const EncryptorPage(),
        ),
      ],
    );
  }

  Widget _toolCard(BuildContext context,
      {required IconData icon, required String name, required String desc, required Widget page}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => Scaffold(body: SafeArea(child: page))),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.panel2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.cyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(color: AppColors.gray, fontSize: 10.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}
