import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class FuelCostView extends StatefulWidget {
  const FuelCostView({super.key});

  @override
  State<FuelCostView> createState() => _FuelCostViewState();
}

class _FuelCostViewState extends State<FuelCostView> {
  final _distance = TextEditingController(text: '100');
  final _efficiency = TextEditingController(text: '8');
  final _price = TextEditingController(text: '1.50');
  bool _metric = true; // L/100km + km vs MPG + miles

  @override
  void dispose() {
    _distance.dispose();
    _efficiency.dispose();
    _price.dispose();
    super.dispose();
  }

  Map<String, String> get _result {
    final d = double.tryParse(_distance.text.trim());
    final e = double.tryParse(_efficiency.text.trim());
    final p = double.tryParse(_price.text.trim());
    if (d == null || e == null || p == null || d <= 0 || e <= 0 || p < 0) {
      return {};
    }

    late final double fuelUsed;
    if (_metric) {
      fuelUsed = (d / 100) * e; // liters
    } else {
      fuelUsed = d / e; // gallons
    }
    final cost = fuelUsed * p;
    final perUnit = d == 0 ? 0.0 : cost / d;

    return {
      'Fuel needed':
          '${_fmt(fuelUsed)} ${_metric ? 'L' : 'gal'}',
      'Trip cost': _money(cost),
      'Cost per ${_metric ? 'km' : 'mi'}': _money(perUnit),
    };
  }

  String _fmt(double v) =>
      v.toStringAsFixed(v >= 10 ? 1 : 2).replaceFirst(RegExp(r'\.?0+$'), '');

  String _money(double v) {
    final fixed = v.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '\$$whole.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    return ToolScaffold(
      toolId: 'fuel_cost',
      title: 'Fuel Cost',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Metric')),
              ButtonSegment(value: false, label: Text('US')),
            ],
            selected: {_metric},
            onSelectionChanged: (s) => setState(() => _metric = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _distance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'Distance',
              suffixText: _metric ? 'km' : 'mi',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _efficiency,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: _metric ? 'Consumption' : 'Fuel economy',
              suffixText: _metric ? 'L/100km' : 'MPG',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'Fuel price',
              prefixText: '\$ ',
              suffixText: _metric ? '/L' : '/gal',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          if (result.isEmpty)
            Text(
              'Enter valid trip details',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else ...[
            for (final e in result.entries) ...[
              Text(e.key, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              SelectableText(e.value, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 14),
            ],
            OutlinedButton.icon(
              onPressed: () {
                final text =
                    result.entries.map((e) => '${e.key}: ${e.value}').join('\n');
                ToolScaffold.copy(text, message: 'Summary copied');
                ToolScaffold.logAction(
                  toolId: 'fuel_cost',
                  toolName: 'Fuel Cost',
                  action: 'Copied summary',
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy summary'),
            ),
          ],
        ],
      ),
    );
  }
}
