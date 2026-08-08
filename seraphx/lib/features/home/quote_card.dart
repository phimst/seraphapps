import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'quote_service.dart';

class QuoteCard extends StatefulWidget {
  const QuoteCard({super.key});

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  List<String> _quotes = [];
  int _index = 0;
  Timer? _timer;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final quotes = await QuoteService.fetchQuotes();
      if (!mounted) return;
      setState(() {
        _quotes = quotes;
        _loading = false;
      });
      // Cuma jalanin auto-geser kalau quote-nya lebih dari 1.
      if (quotes.length > 1) {
        _timer = Timer.periodic(const Duration(seconds: 10), (_) {
          if (!mounted) return;
          setState(() => _index = (_index + 1) % _quotes.length);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _failed || _quotes.isEmpty) {
      // Gagal ambil quote atau masih loading -> sembunyikan aja,
      // gak ganggu tampilan dashboard.
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Text(
          '"${_quotes[_index]}"',
          key: ValueKey(_index),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
