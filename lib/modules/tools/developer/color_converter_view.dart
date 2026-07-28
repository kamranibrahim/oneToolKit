import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class ColorConverterView extends StatefulWidget {
  const ColorConverterView({super.key});

  @override
  State<ColorConverterView> createState() => _ColorConverterViewState();
}

class _ColorConverterViewState extends State<ColorConverterView> {
  final _hex = TextEditingController(text: '#0D9488');
  Color _color = const Color(0xFF0D9488);
  String? _error;

  void _fromHex(String value) {
    var v = value.trim();
    if (v.startsWith('#')) v = v.substring(1);
    if (v.length == 3) {
      v = v.split('').map((c) => '$c$c').join();
    }
    if (v.length != 6) {
      setState(() => _error = 'Use #RGB or #RRGGBB');
      return;
    }
    final parsed = int.tryParse(v, radix: 16);
    if (parsed == null) {
      setState(() => _error = 'Invalid hex');
      return;
    }
    setState(() {
      _color = Color(0xFF000000 | parsed);
      _error = null;
    });
  }

  String get _hexOut {
    final r = (_color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (_color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (_color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  String get _rgb {
    final r = (_color.r * 255).round();
    final g = (_color.g * 255).round();
    final b = (_color.b * 255).round();
    return 'rgb($r, $g, $b)';
  }

  String get _hsl {
    final r = _color.r;
    final g = _color.g;
    final b = _color.b;
    final max = [r, g, b].reduce((a, c) => a > c ? a : c);
    final min = [r, g, b].reduce((a, c) => a < c ? a : c);
    final l = (max + min) / 2;
    double h = 0, s = 0;
    if (max != min) {
      final d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      if (max == r) {
        h = (g - b) / d + (g < b ? 6 : 0);
      } else if (max == g) {
        h = (b - r) / d + 2;
      } else {
        h = (r - g) / d + 4;
      }
      h /= 6;
    }
    return 'hsl(${(h * 360).round()}, ${(s * 100).round()}%, ${(l * 100).round()}%)';
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'color_converter',
      title: 'Color Converter',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _hex,
            decoration: InputDecoration(
              labelText: 'HEX',
              errorText: _error,
            ),
            onChanged: _fromHex,
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          _Row(label: 'HEX', value: _hexOut),
          _Row(label: 'RGB', value: _rgb),
          _Row(label: 'HSL', value: _hsl),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: SelectableText(value),
      trailing: IconButton(
        icon: const Icon(Icons.copy_rounded),
        onPressed: () => ToolScaffold.copy(value),
      ),
    );
  }
}
