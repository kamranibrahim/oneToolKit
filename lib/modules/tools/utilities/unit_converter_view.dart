import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class UnitConverterView extends StatefulWidget {
  const UnitConverterView({super.key});

  @override
  State<UnitConverterView> createState() => _UnitConverterViewState();
}

class _UnitConverterViewState extends State<UnitConverterView> {
  static const _categories = <String, Map<String, double>>{
    'Length': {
      'Meter': 1,
      'Kilometer': 1000,
      'Centimeter': 0.01,
      'Millimeter': 0.001,
      'Inch': 0.0254,
      'Foot': 0.3048,
      'Yard': 0.9144,
      'Mile': 1609.344,
    },
    'Weight': {
      'Kilogram': 1,
      'Gram': 0.001,
      'Milligram': 0.000001,
      'Pound': 0.45359237,
      'Ounce': 0.028349523125,
      'Ton': 1000,
    },
    'Temperature': {}, // special-cased
    'Data': {
      'Byte': 1,
      'Kilobyte': 1024,
      'Megabyte': 1024 * 1024,
      'Gigabyte': 1024 * 1024 * 1024,
      'Terabyte': 1024.0 * 1024 * 1024 * 1024,
      'Bit': 0.125,
    },
    'Speed': {
      'm/s': 1,
      'km/h': 1000 / 3600,
      'mph': 1609.344 / 3600,
      'knot': 1852 / 3600,
    },
    'Area': {
      'm²': 1,
      'km²': 1e6,
      'ft²': 0.09290304,
      'acre': 4046.8564224,
      'hectare': 10000,
    },
  };

  static const _temps = ['Celsius', 'Fahrenheit', 'Kelvin'];

  String _category = 'Length';
  late String _from;
  late String _to;
  final _input = TextEditingController(text: '1');
  String _output = '';

  @override
  void initState() {
    super.initState();
    _resetUnits();
    _convert();
    _input.addListener(_convert);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  List<String> get _units {
    if (_category == 'Temperature') return _temps;
    return _categories[_category]!.keys.toList();
  }

  void _resetUnits() {
    final units = _units;
    _from = units.first;
    _to = units.length > 1 ? units[1] : units.first;
  }

  double _tempToC(double value, String unit) {
    return switch (unit) {
      'Fahrenheit' => (value - 32) * 5 / 9,
      'Kelvin' => value - 273.15,
      _ => value,
    };
  }

  double _tempFromC(double celsius, String unit) {
    return switch (unit) {
      'Fahrenheit' => celsius * 9 / 5 + 32,
      'Kelvin' => celsius + 273.15,
      _ => celsius,
    };
  }

  void _convert() {
    final raw = double.tryParse(_input.text.trim());
    if (raw == null) {
      setState(() => _output = '');
      return;
    }
    double result;
    if (_category == 'Temperature') {
      result = _tempFromC(_tempToC(raw, _from), _to);
    } else {
      final map = _categories[_category]!;
      final base = raw * map[_from]!;
      result = base / map[_to]!;
    }
    setState(() {
      _output = result
          .toStringAsFixed(result.abs() >= 1000 || result.abs() < 0.001 ? 6 : 4)
          .replaceFirst(RegExp(r'\.?0+$'), '');
    });
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'unit_converter',
      title: 'Unit Converter',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Convert length, weight, temperature, data size, speed, and area offline.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories.keys
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _category = v;
                _resetUnits();
                _convert();
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _input,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Value'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _from,
                  decoration: const InputDecoration(labelText: 'From'),
                  items: _units
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _from = v;
                      _convert();
                    });
                  },
                ),
              ),
              IconButton(
                onPressed: _swap,
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _to,
                  decoration: const InputDecoration(labelText: 'To'),
                  items: _units
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _to = v;
                      _convert();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Result', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SelectableText(
            _output.isEmpty ? '—' : '$_output $_to',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _output.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _output));
                    ToolScaffold.copy(_output, message: 'Result copied');
                    ToolScaffold.logAction(
                      toolId: 'unit_converter',
                      toolName: 'Unit Converter',
                      action: 'Converted',
                      detail: '$_category · $_from → $_to',
                    );
                  },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy result'),
          ),
        ],
      ),
    );
  }
}
