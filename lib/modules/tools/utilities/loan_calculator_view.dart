import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class LoanCalculatorView extends StatefulWidget {
  const LoanCalculatorView({super.key});

  @override
  State<LoanCalculatorView> createState() => _LoanCalculatorViewState();
}

class _LoanCalculatorViewState extends State<LoanCalculatorView> {
  final _principal = TextEditingController(text: '250000');
  final _rate = TextEditingController(text: '6.5');
  final _years = TextEditingController(text: '30');

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _years.dispose();
    super.dispose();
  }

  Map<String, String> get _result {
    final p = double.tryParse(_principal.text.trim());
    final annual = double.tryParse(_rate.text.trim());
    final years = double.tryParse(_years.text.trim());
    if (p == null || annual == null || years == null || p <= 0 || years <= 0) {
      return {};
    }

    final n = (years * 12).round();
    final r = annual / 100 / 12;
    late final double payment;
    if (r == 0) {
      payment = p / n;
    } else {
      payment = p * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
    }
    final total = payment * n;
    final interest = total - p;

    return {
      'Monthly payment': _money(payment),
      'Total paid': _money(total),
      'Total interest': _money(interest),
      'Payments': '$n months',
    };
  }

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
      toolId: 'loan_calculator',
      title: 'Loan Calculator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Monthly payment for a fixed-rate loan',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _principal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Principal',
              prefixText: '\$ ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Annual interest rate',
              suffixText: '%',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _years,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Term',
              suffixText: 'years',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          if (result.isEmpty)
            Text(
              'Enter valid loan details',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else ...[
            for (final e in result.entries) ...[
              Text(e.key, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              SelectableText(e.value, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
            ],
            OutlinedButton.icon(
              onPressed: () {
                final text = result.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join('\n');
                ToolScaffold.copy(text, message: 'Loan summary copied');
                ToolScaffold.logAction(
                  toolId: 'loan_calculator',
                  toolName: 'Loan Calculator',
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
