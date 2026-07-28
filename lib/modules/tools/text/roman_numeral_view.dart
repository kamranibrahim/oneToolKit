import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class RomanNumeralView extends StatefulWidget {
  const RomanNumeralView({super.key});

  @override
  State<RomanNumeralView> createState() => _RomanNumeralViewState();
}

class _RomanNumeralViewState extends State<RomanNumeralView> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  int _mode = 0; // 0 number→roman, 1 roman→number
  String? _error;

  static const _table = [
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  void _convert() {
    try {
      if (_mode == 0) {
        final n = int.parse(_input.text.trim());
        if (n < 1 || n > 3999) {
          throw Exception('Enter a number from 1 to 3999');
        }
        _output.text = _toRoman(n);
      } else {
        final roman = _input.text.trim().toUpperCase();
        if (!RegExp(r'^[IVXLCDM]+$').hasMatch(roman)) {
          throw Exception('Invalid Roman numeral');
        }
        final value = _fromRoman(roman);
        if (_toRoman(value) != roman) {
          throw Exception('Invalid Roman numeral');
        }
        _output.text = value.toString();
      }
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'roman_numeral',
        toolName: 'Roman Numerals',
        action: _mode == 0 ? 'Number → Roman' : 'Roman → number',
      );
    } catch (e) {
      setState(() {
        _error = e is FormatException
            ? 'Enter a whole number'
            : e.toString().replaceFirst('Exception: ', '');
        _output.clear();
      });
    }
  }

  String _toRoman(int n) {
    var remaining = n;
    final buffer = StringBuffer();
    for (final (value, symbol) in _table) {
      while (remaining >= value) {
        buffer.write(symbol);
        remaining -= value;
      }
    }
    return buffer.toString();
  }

  int _fromRoman(String roman) {
    final values = {
      'I': 1,
      'V': 5,
      'X': 10,
      'L': 50,
      'C': 100,
      'D': 500,
      'M': 1000,
    };
    var total = 0;
    for (var i = 0; i < roman.length; i++) {
      final current = values[roman[i]]!;
      final next = i + 1 < roman.length ? values[roman[i + 1]]! : 0;
      if (current < next) {
        total -= current;
      } else {
        total += current;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'roman_numeral',
      title: 'Roman Numerals',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Number → Roman')),
              ButtonSegment(value: 1, label: Text('Roman → Number')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: _mode == 0 ? 'Number (1–3999)' : 'Roman numeral',
              hintText: _mode == 0 ? '2026' : 'MMXXVI',
              errorText: _error,
            ),
            onSubmitted: (_) => _convert(),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _convert, child: const Text('Convert')),
          const SizedBox(height: 16),
          TextField(
            controller: _output,
            readOnly: true,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: const InputDecoration(labelText: 'Output'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _output.text.isEmpty
                ? null
                : () => ToolScaffold.copy(_output.text),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy output'),
          ),
        ],
      ),
    );
  }
}
