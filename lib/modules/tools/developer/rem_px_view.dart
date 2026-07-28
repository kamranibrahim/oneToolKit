import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class RemPxView extends StatefulWidget {
  const RemPxView({super.key});

  @override
  State<RemPxView> createState() => _RemPxViewState();
}

class _RemPxViewState extends State<RemPxView> {
  final _value = TextEditingController(text: '16');
  final _root = TextEditingController(text: '16');
  int _mode = 0; // 0 px→rem, 1 rem→px

  @override
  void dispose() {
    _value.dispose();
    _root.dispose();
    super.dispose();
  }

  String get _result {
    final v = double.tryParse(_value.text.trim());
    final root = double.tryParse(_root.text.trim());
    if (v == null || root == null || root == 0) return '—';
    if (_mode == 0) {
      final rem = v / root;
      return '${_fmt(rem)} rem';
    }
    final px = v * root;
    return '${_fmt(px)} px';
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(4);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'rem_px',
      title: 'rem ↔ px',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('px → rem')),
              ButtonSegment(value: 1, label: Text('rem → px')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: _mode == 0 ? 'Pixels' : 'rem',
              suffixText: _mode == 0 ? 'px' : 'rem',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _root,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Root font size',
              suffixText: 'px',
              helperText: 'Usually 16px',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text('Result', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SelectableText(_result, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _result == '—'
                ? null
                : () {
                    ToolScaffold.copy(_result, message: 'Copied');
                    ToolScaffold.logAction(
                      toolId: 'rem_px',
                      toolName: 'rem ↔ px',
                      action: 'Copied',
                      detail: _result,
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
