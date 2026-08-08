import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';

class BrowserPage extends StatefulWidget {
  final String initialUrl;
  const BrowserPage({super.key, this.initialUrl = 'https://www.google.com'});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final WebViewController _controller;
  late final TextEditingController _urlController;
  bool _loading = true;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _loading = true;
              _urlController.text = url;
            });
          },
          onPageFinished: (url) async {
            final canBack = await _controller.canGoBack();
            setState(() {
              _loading = false;
              _canGoBack = canBack;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _go(String input) {
    var target = input.trim();
    if (target.isEmpty) return;
    final looksLikeUrl = target.startsWith('http://') ||
        target.startsWith('https://') ||
        (target.contains('.') && !target.contains(' '));
    if (!looksLikeUrl) {
      // bukan URL -> perlakukan sebagai pencarian Google
      target = 'https://www.google.com/search?q=${Uri.encodeComponent(target)}';
    } else if (!target.startsWith('http')) {
      target = 'https://$target';
    }
    _controller.loadRequest(Uri.parse(target));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: AppColors.panel,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _canGoBack ? () => _controller.goBack() : null,
                icon: const Icon(Icons.arrow_back, size: 20),
                color: _canGoBack ? AppColors.ink : AppColors.gray,
              ),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(color: AppColors.ink, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Cari atau ketik URL...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: _go,
                ),
              ),
              IconButton(
                onPressed: () => _controller.reload(),
                icon: const Icon(Icons.refresh, size: 20, color: AppColors.cyan),
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(color: AppColors.cyan, minHeight: 2),
        Expanded(child: WebViewWidget(controller: _controller)),
      ],
    );
  }
}
