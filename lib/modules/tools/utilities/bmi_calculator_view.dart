import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class BmiCalculatorView extends StatefulWidget {
  const BmiCalculatorView({super.key});

  @override
  State<BmiCalculatorView> createState() => _BmiCalculatorViewState();
}

class _BmiCalculatorViewState extends State<BmiCalculatorView> {
  final _weight = TextEditingController(text: '70');
  final _height = TextEditingController(text: '175');
  bool _metric = true; // kg/cm vs lb/in

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  double? get _bmi {
    final w = double.tryParse(_weight.text.trim());
    final h = double.tryParse(_height.text.trim());
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    if (_metric) {
      final meters = h / 100;
      return w / (meters * meters);
    }
    return (w / (h * h)) * 703;
  }

  String get _category {
    final bmi = _bmi;
    if (bmi == null) return '—';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _categoryColor(BuildContext context) {
    final bmi = _bmi;
    final scheme = Theme.of(context).colorScheme;
    if (bmi == null) return scheme.onSurface;
    if (bmi < 18.5) return const Color(0xFF0284C7);
    if (bmi < 25) return const Color(0xFF16A34A);
    if (bmi < 30) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bmi = _bmi;
    final bmiText = bmi == null ? '—' : bmi.toStringAsFixed(1);
    return ToolScaffold(
      toolId: 'bmi_calculator',
      title: 'BMI Calculator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Metric')),
              ButtonSegment(value: false, label: Text('Imperial')),
            ],
            selected: {_metric},
            onSelectionChanged: (s) => setState(() => _metric = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'Weight',
              suffixText: _metric ? 'kg' : 'lb',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'Height',
              suffixText: _metric ? 'cm' : 'in',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text('BMI', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          SelectableText(bmiText, style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            _category,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _categoryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: bmi == null
                ? null
                : () {
                    final text = 'BMI $bmiText ($_category)';
                    ToolScaffold.copy(text, message: 'BMI copied');
                    ToolScaffold.logAction(
                      toolId: 'bmi_calculator',
                      toolName: 'BMI Calculator',
                      action: 'Copied',
                      detail: text,
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
