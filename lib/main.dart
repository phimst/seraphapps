import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/settings_controller.dart';
import 'features/home/home_page.dart';
import 'features/settings/settings_page.dart';
import 'features/chat/chat_page.dart';
import 'features/tools/tools_page.dart';
import 'features/tools/browser/browser_page.dart';

void main() {
  runApp(const SeraphXApp());
}

class SeraphXApp extends StatelessWidget {
  const SeraphXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeraphX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  bool _ready = false;

  // Semua page dibuat sekali di sini dan dijaga tetap hidup lewat
  // IndexedStack (bukan diganti-ganti widget) - jadi state kayak history
  // chat AI gak ilang pas pindah tab, cuma reset kalau app di-close total.
  final _pages = const [
    HomePage(),
    ChatPage(),
    ToolsPage(),
    BrowserPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await SettingsController.instance.load();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    return ListenableBuilder(
      listenable: SettingsController.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Seraph Sys.',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.gray)),
            centerTitle: false,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.circle, size: 8, color: AppColors.cyan),
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _index,
              children: _pages,
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: AppColors.bg,
            indicatorColor: AppColors.panel,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.cyan), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.chat_outlined), selectedIcon: Icon(Icons.chat, color: AppColors.cyan), label: 'Chat'),
              NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build, color: AppColors.cyan), label: 'Tools'),
              NavigationDestination(icon: Icon(Icons.public_outlined), selectedIcon: Icon(Icons.public, color: AppColors.cyan), label: 'Web'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: AppColors.cyan), label: 'Setting'),
            ],
          ),
        );
      },
    );
  }
}
