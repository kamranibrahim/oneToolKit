import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class NumberBaseConverterView extends StatefulWidget {
  const NumberBaseConverterView({super.key});

  @override
  State<NumberBaseConverterView> createState() =>
      _NumberBaseConverterViewState();
}

class _NumberBaseConverterViewState extends State<NumberBaseConverterView> {
  final _bin = TextEditingController();
  final _oct = TextEditingController();
  final _dec = TextEditingController();
  final _hex = TextEditingController();
  String? _error;
  bool _updating = false;

  @override
  void dispose() {
    _bin.dispose();
    _oct.dispose();
    _dec.dispose();
    _hex.dispose();
    super.dispose();
  }

  void _from(int radix, String raw) {
    if (_updating) return;
    final cleaned = raw.trim().replaceAll(' ', '');
    if (cleaned.isEmpty) {
      _updating = true;
      _bin.clear();
      _oct.clear();
      _dec.clear();
      _hex.clear();
      _updating = false;
      setState(() => _error = null);
      return;
    }
    try {
      final value = BigInt.parse(cleaned, radix: radix);
      if (value.isNegative) throw FormatException('negative');
      _updating = true;
      _bin.text = value.toRadixString(2);
      _oct.text = value.toRadixString(8);
      _dec.text = value.toString();
      _hex.text = value.toRadixString(16).toUpperCase();
      _updating = false;
      setState(() => _error = null);
    } catch (_) {
      setState(() => _error = 'Invalid ${switch (radix) {
            2 => 'binary',
            8 => 'octal',
            16 => 'hex',
            _ => 'decimal',
          }} value');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'number_base',
      title: 'Number Base Converter',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Convert between binary, octal, decimal, and hexadecimal.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          _field('Binary (2)', _bin, (v) => _from(2, v)),
          _field('Octal (8)', _oct, (v) => _from(8, v)),
          _field('Decimal (10)', _dec, (v) => _from(10, v)),
          _field('Hexadecimal (16)', _hex, (v) => _from(16, v)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _dec.text.isEmpty
                ? null
                : () {
                    final text =
                        'bin ${_bin.text}\noct ${_oct.text}\ndec ${_dec.text}\nhex ${_hex.text}';
                    Clipboard.setData(ClipboardData(text: text));
                    ToolScaffold.copy(text, message: 'All bases copied');
                    ToolScaffold.logAction(
                      toolId: 'number_base',
                      toolName: 'Number Base Converter',
                      action: 'Converted',
                      detail: _dec.text,
                    );
                  },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy all'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        style: const TextStyle(fontFamily: 'monospace'),
        onChanged: onChanged,
      ),
    );
  }
}
