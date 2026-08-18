import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/seraph_header.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/models/app_settings.dart';
import '../../core/network/skippable_loading.dart';
import 'ai_chat_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SkippableLoading<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _sending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final settings = SettingsController.instance.settings;
    final gen = startLoading();

    setState(() {
      _messages.add(ChatMessage(text, true));
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => m != _messages.last)
          .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
          .toList();

      final reply = await AiChatService.sendMessage(
        settings: settings,
        message: text,
        history: history,
      );
      if (!isCurrent(gen)) return; // udah di-skip user
      setState(() => _messages.add(ChatMessage(reply, false)));
    } catch (e) {
      if (!isCurrent(gen)) return;
      setState(() => _messages.add(ChatMessage('⚠ Error: $e', false)));
    } finally {
      if (isCurrent(gen)) setState(() => _sending = false);
      stopLoading();
      _scrollToBottom();
    }
  }

  void _skip() {
    skipLoading();
    setState(() {
      _sending = false;
      _messages.add(ChatMessage('⏭ Dibatalkan.', false));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final providerLabel = SettingsController.instance.settings.aiProvider.label;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: SeraphHeader(
            title: 'Seraph',
            accent: 'Chat',
            subtitle: 'Provider aktif: $providerLabel',
            padding: const EdgeInsets.only(bottom: 6),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text('Mulai chat sama AI...',
                      style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _Bubble(msg: _messages[i]),
                ),
        ),
        if (_sending) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
            ),
          ),
          SkipButton(visible: showSkipButton, onSkip: _skip),
          const SizedBox(height: 4),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppColors.ink),
                  decoration: const InputDecoration(hintText: 'Tulis pesan...'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.arrow_upward),
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.cyan, foregroundColor: const Color(0xFF06110E)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.panel2 : AppColors.panel,
          border: Border.all(
              color: msg.isUser ? AppColors.cyan.withValues(alpha: 0.4) : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(msg.text, style: const TextStyle(color: AppColors.ink, fontSize: 13)),
      ),
    );
  }
}
