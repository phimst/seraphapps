import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'tool_category.dart';
import 'category_tools_page.dart';
import 'tiktok/tiktok_downloader_page.dart';
import 'github/github_push_page.dart';
import 'encryptor/encryptor_page.dart';
import 'base64/base64_tool_page.dart';
import 'ip_tracker/ip_tracker_page.dart';
import 'tts/tts_page.dart';
import 'disaster/disaster_page.dart';
import 'steganography/steganography_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  static final List<ToolCategory> categories = [
    ToolCategory(
      title: 'Downloader',
      desc: 'download konten dari internet',
      icon: Icons.download_outlined,
      tools: [
        ToolEntry(
          icon: Icons.music_note_outlined,
          name: 'TikTok Downloader',
          desc: 'Download video/audio TikTok tanpa watermark',
          builder: (_) => const TikTokDownloaderPage(),
        ),
      ],
    ),
    ToolCategory(
      title: 'Developer Tools',
      desc: 'buat kebutuhan development',
      icon: Icons.code_outlined,
      tools: [
        ToolEntry(
          icon: Icons.upload_file_outlined,
          name: 'GitHub Push',
          desc: 'Upload ZIP dan push langsung ke repository',
          builder: (_) => const GithubPushPage(),
        ),
        ToolEntry(
          icon: Icons.enhanced_encryption_outlined,
          name: 'Code Encryptor',
          desc: 'Obfuscate HTML, PHP, CSS, JS',
          builder: (_) => const EncryptorPage(),
        ),
        ToolEntry(
          icon: Icons.code,
          name: 'Base64 Encoder/Decoder',
          desc: 'Convert teks ke Base64 dan sebaliknya',
          builder: (_) => const Base64ToolPage(),
        ),
      ],
    ),
    ToolCategory(
      title: 'Utilities',
      desc: 'tools serbaguna sehari-hari',
      icon: Icons.build_outlined,
      tools: [
        ToolEntry(
          icon: Icons.record_voice_over_outlined,
          name: 'Text to Speech',
          desc: 'Ubah teks jadi suara',
          builder: (_) => const TtsPage(),
        ),
        ToolEntry(
          icon: Icons.wifi_tethering,
          name: 'IP Tracker',
          desc: 'Lacak info lengkap IP address (lokasi, ISP, dll)',
          builder: (_) => const IpTrackerPage(),
        ),
        ToolEntry(
          icon: Icons.warning_amber_rounded,
          name: 'Disaster Watch',
          desc: 'Pantau gempa (BMKG) & gunung api (MAGMA)',
          builder: (_) => const DisasterPage(),
        ),
      ],
    ),
    ToolCategory(
      title: 'Security',
      desc: 'privasi & kerahasiaan data',
      icon: Icons.shield_outlined,
      tools: [
        ToolEntry(
          icon: Icons.image_outlined,
          name: 'Steganography',
          desc: 'Sembunyiin/baca pesan rahasia di dalam gambar',
          builder: (_) => const SteganographyPage(),
        ),
      ],
    ),
  ];

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
        const Text('// pilih kategori tools',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 11)),
        const SizedBox(height: 18),
        for (final category in categories) ...[
          _categoryCard(context, category),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _categoryCard(BuildContext context, ToolCategory category) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CategoryToolsPage(category: category)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.panel2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, color: AppColors.cyan, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.title,
                      style: const TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('${category.tools.length} tools • ${category.desc}',
                      style: const TextStyle(color: AppColors.gray, fontSize: 10.5)),
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
