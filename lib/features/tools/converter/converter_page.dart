import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/network/skippable_loading.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

// Faktor konversi ke satuan dasar (meter/gram/celcius base)
class _UnitCategory {
  final String name;
  final Map<String, double> units; // unit -> faktor ke basis
  const _UnitCategory(this.name, this.units);
}

class _ConverterPageState extends State<ConverterPage> with SkippableLoading<ConverterPage> {
  bool _isUnitMode = true;

  // ---- Unit converter state ----
  static const _categories = [
    _UnitCategory('Panjang', {
      'Meter': 1,
      'Kilometer': 1000,
      'Centimeter': 0.01,
      'Milimeter': 0.001,
      'Mil': 1609.34,
      'Yard': 0.9144,
      'Kaki (feet)': 0.3048,
      'Inch': 0.0254,
    }),
    _UnitCategory('Berat', {
      'Kilogram': 1,
      'Gram': 0.001,
      'Miligram': 0.000001,
      'Ton': 1000,
      'Pon (lb)': 0.453592,
      'Ons': 0.1,
    }),
    _UnitCategory('Suhu', {'Celcius': 1, 'Fahrenheit': 2, 'Kelvin': 3}), // spesial, dihandle manual
  ];

  int _categoryIndex = 0;
  String _fromUnit = 'Meter';
  String _toUnit = 'Kilometer';
  final _unitValueController = TextEditingController(text: '1');
  String _unitResult = '';

  // ---- Currency converter state ----
  final List<String> _currencies = ['IDR', 'USD', 'EUR', 'JPY', 'SGD', 'MYR', 'GBP', 'AUD', 'CNY', 'KRW'];
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  final _currencyValueController = TextEditingController(text: '1');
  String? _currencyResult;
  String? _currencyError;

  @override
  void initState() {
    super.initState();
    _fromUnit = _categories[0].units.keys.first;
    _toUnit = _categories[0].units.keys.elementAt(1);
    _convertUnit();
  }

  void _convertUnit() {
    final value = double.tryParse(_unitValueController.text);
    if (value == null) {
      setState(() => _unitResult = '');
      return;
    }
    if (_categoryIndex == 2) {
      // Suhu, konversi manual (bukan linear factor biasa)
      double celsius;
      switch (_fromUnit) {
        case 'Fahrenheit':
          celsius = (value - 32) * 5 / 9;
          break;
        case 'Kelvin':
          celsius = value - 273.15;
          break;
        default:
          celsius = value;
      }
      double result;
      switch (_toUnit) {
        case 'Fahrenheit':
          result = celsius * 9 / 5 + 32;
          break;
        case 'Kelvin':
          result = celsius + 273.15;
          break;
        default:
          result = celsius;
      }
      setState(() => _unitResult = result.toStringAsFixed(2));
    } else {
      final units = _categories[_categoryIndex].units;
      final baseValue = value * units[_fromUnit]!;
      final result = baseValue / units[_toUnit]!;
      setState(() => _unitResult = result.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), ''));
    }
  }

  Future<void> _convertCurrency() async {
    final value = double.tryParse(_currencyValueController.text);
    if (value == null) return;

    final gen = startLoading();
    setState(() {
      _currencyError = null;
      _currencyResult = null;
    });

    try {
      final uri = Uri.parse('https://api.frankfurter.app/latest?from=$_fromCurrency&to=$_toCurrency');
      final res = await http.get(uri);
      if (!isCurrent(gen)) return;
      if (res.statusCode != 200) throw Exception('Server error (${res.statusCode})');
      final data = jsonDecode(res.body);
      final rate = (data['rates'][_toCurrency] as num).toDouble();
      setState(() => _currencyResult = (value * rate).toStringAsFixed(2));
    } catch (e) {
      if (!isCurrent(gen)) return;
      setState(() => _currencyError = 'Gagal ambil kurs: $e');
    } finally {
      if (isCurrent(gen)) setState(() {});
      stopLoading();
    }
  }

  void _skipCurrency() {
    skipLoading();
    setState(() => _currencyError = 'Dibatalkan.');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Convert', accent: 'er', subtitle: 'Konversi satuan & mata uang'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _modeButton('Satuan', _isUnitMode, () => setState(() => _isUnitMode = true))),
            const SizedBox(width: 8),
            Expanded(child: _modeButton('Mata Uang', !_isUnitMode, () => setState(() => _isUnitMode = false))),
          ],
        ),
        const SizedBox(height: 18),
        if (_isUnitMode) _buildUnitUI() else _buildCurrencyUI(),
      ],
    );
  }

  Widget _buildUnitUI() {
    final currentCategory = _categories[_categoryIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < _categories.length; i++)
              _chip(_categories[i].name, _categoryIndex == i, () {
                setState(() {
                  _categoryIndex = i;
                  _fromUnit = _categories[i].units.keys.first;
                  _toUnit = _categories[i].units.keys.elementAt(1);
                });
                _convertUnit();
              }),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _unitValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.ink, fontSize: 14),
          decoration: const InputDecoration(hintText: 'Nilai'),
          onChanged: (_) => _convertUnit(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _unitDropdown(currentCategory, _fromUnit, (v) {
              setState(() => _fromUnit = v!);
              _convertUnit();
            })),
            IconButton(
              onPressed: () {
                setState(() {
                  final tmp = _fromUnit;
                  _fromUnit = _toUnit;
                  _toUnit = tmp;
                });
                _convertUnit();
              },
              icon: const Icon(Icons.swap_horiz, color: AppColors.cyan),
            ),
            Expanded(child: _unitDropdown(currentCategory, _toUnit, (v) {
              setState(() => _toUnit = v!);
              _convertUnit();
            })),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text('$_unitResult $_toUnit',
                style: const TextStyle(color: AppColors.cyan, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _currencyValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.ink, fontSize: 14),
          decoration: const InputDecoration(hintText: 'Nilai'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _currencyDropdown(_fromCurrency, (v) => setState(() => _fromCurrency = v!))),
            IconButton(
              onPressed: () => setState(() {
                final tmp = _fromCurrency;
                _fromCurrency = _toCurrency;
                _toCurrency = tmp;
              }),
              icon: const Icon(Icons.swap_horiz, color: AppColors.cyan),
            ),
            Expanded(child: _currencyDropdown(_toCurrency, (v) => setState(() => _toCurrency = v!))),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _convertCurrency, child: const Text('CEK KURS & KONVERSI')),
        SkipButton(visible: showSkipButton, onSkip: _skipCurrency),
        if (_currencyError != null) ...[
          const SizedBox(height: 12),
          Text(_currencyError!, style: const TextStyle(color: AppColors.magenta, fontSize: 11.5)),
        ],
        if (_currencyResult != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('$_currencyResult $_toCurrency',
                  style: const TextStyle(color: AppColors.cyan, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('Kurs real-time dari frankfurter.app (data ECB)',
                style: TextStyle(color: AppColors.gray, fontSize: 9.5)),
          ),
        ],
      ],
    );
  }

  Widget _unitDropdown(_UnitCategory category, String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.panel,
        style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
        items: category.units.keys.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _currencyDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.panel,
        style: const TextStyle(color: AppColors.ink, fontSize: 12.5),
        items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _modeButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.panel2 : AppColors.panel,
          border: Border.all(color: active ? AppColors.cyan : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? AppColors.ink : AppColors.gray, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.cyan.withValues(alpha: 0.15) : AppColors.panel,
          border: Border.all(color: active ? AppColors.cyan : AppColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: active ? AppColors.cyan : AppColors.gray, fontSize: 11)),
      ),
    );
  }
}
