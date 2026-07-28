import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class TipCalculatorView extends StatefulWidget {
  const TipCalculatorView({super.key});

  @override
  State<TipCalculatorView> createState() => _TipCalculatorViewState();
}

class _TipCalculatorViewState extends State<TipCalculatorView> {
  final _bill = TextEditingController(text: '50');
  double _tipPercent = 15;
  int _people = 2;

  @override
  void dispose() {
    _bill.dispose();
    super.dispose();
  }

  double get _billAmount => double.tryParse(_bill.text.trim()) ?? 0;
  double get _tipAmount => _billAmount * (_tipPercent / 100);
  double get _total => _billAmount + _tipAmount;
  double get _perPerson => _people <= 0 ? _total : _total / _people;

  String _money(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'tip_calculator',
      title: 'Tip Calculator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Split a bill and tip offline — nothing leaves your device.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bill,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Bill amount',
              prefixText: '\$ ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('Tip ${_tipPercent.round()}%'),
          Slider(
            value: _tipPercent,
            min: 0,
            max: 40,
            divisions: 40,
            onChanged: (v) => setState(() => _tipPercent = v),
          ),
          Wrap(
            spacing: 8,
            children: [10, 15, 18, 20, 25]
                .map(
                  (p) => ChoiceChip(
                    label: Text('$p%'),
                    selected: _tipPercent.round() == p,
                    onSelected: (_) => setState(() => _tipPercent = p.toDouble()),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Text('People $_people'),
          Slider(
            value: _people.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: (v) => setState(() => _people = v.round()),
          ),
          const SizedBox(height: 12),
          _Row(label: 'Tip', value: '\$${_money(_tipAmount)}'),
          _Row(label: 'Total', value: '\$${_money(_total)}'),
          _Row(label: 'Per person', value: '\$${_money(_perPerson)}'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final text =
                  'Bill \$${_money(_billAmount)} · Tip ${_tipPercent.round()}% '
                  '(\$${_money(_tipAmount)}) · Total \$${_money(_total)} · '
                  '$_people people · \$${_money(_perPerson)} each';
              Clipboard.setData(ClipboardData(text: text));
              ToolScaffold.copy(text, message: 'Summary copied');
              ToolScaffold.logAction(
                toolId: 'tip_calculator',
                toolName: 'Tip Calculator',
                action: 'Calculated',
                detail: '${_tipPercent.round()}% · $_people ppl',
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy summary'),
          ),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          const Spacer(),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
