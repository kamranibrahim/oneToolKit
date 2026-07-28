import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class PercentageCalculatorView extends StatefulWidget {
  const PercentageCalculatorView({super.key});

  @override
  State<PercentageCalculatorView> createState() =>
      _PercentageCalculatorViewState();
}

class _PercentageCalculatorViewState extends State<PercentageCalculatorView> {
  final _a = TextEditingController(text: '25');
  final _b = TextEditingController(text: '200');
  int _mode = 0; // 0: % of, 1: is what % of, 2: change %

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  String get _result {
    final x = double.tryParse(_a.text.trim());
    final y = double.tryParse(_b.text.trim());
    if (x == null || y == null) return '—';
    switch (_mode) {
      case 0:
        return _fmt(y * (x / 100));
      case 1:
        if (y == 0) return '—';
        return '${_fmt((x / y) * 100)}%';
      case 2:
        if (x == 0) return '—';
        final change = ((y - x) / x) * 100;
        final sign = change > 0 ? '+' : '';
        return '$sign${_fmt(change)}%';
      default:
        return '—';
    }
  }

  String get _labelA => switch (_mode) {
        0 => 'Percentage',
        1 => 'Part',
        _ => 'From',
      };

  String get _labelB => switch (_mode) {
        0 => 'Of value',
        1 => 'Whole',
        _ => 'To',
      };

  String get _prompt => switch (_mode) {
        0 => 'What is X% of Y?',
        1 => 'X is what % of Y?',
        _ => 'Percent change from X to Y',
      };

  String _fmt(double v) =>
      v.toStringAsFixed(v == v.roundToDouble() ? 0 : 4).replaceFirst(
            RegExp(r'\.?0+$'),
            '',
          );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'percentage_calculator',
      title: 'Percentage Calculator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _prompt,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('% of')),
              ButtonSegment(value: 1, label: Text('is %')),
              ButtonSegment(value: 2, label: Text('change')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _a,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: _labelA),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _b,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: _labelB),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('Result', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SelectableText(_result, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _result == '—'
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _result));
                    ToolScaffold.copy(_result, message: 'Result copied');
                    ToolScaffold.logAction(
                      toolId: 'percentage_calculator',
                      toolName: 'Percentage Calculator',
                      action: 'Calculated',
                      detail: _prompt,
                    );
                  },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
