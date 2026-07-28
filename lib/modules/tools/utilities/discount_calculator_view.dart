import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class DiscountCalculatorView extends StatefulWidget {
  const DiscountCalculatorView({super.key});

  @override
  State<DiscountCalculatorView> createState() => _DiscountCalculatorViewState();
}

class _DiscountCalculatorViewState extends State<DiscountCalculatorView> {
  final _price = TextEditingController(text: '100');
  final _discount = TextEditingController(text: '20');
  final _tax = TextEditingController(text: '0');

  @override
  void dispose() {
    _price.dispose();
    _discount.dispose();
    _tax.dispose();
    super.dispose();
  }

  Map<String, String> get _result {
    final price = double.tryParse(_price.text.trim());
    final discount = double.tryParse(_discount.text.trim());
    final tax = double.tryParse(_tax.text.trim()) ?? 0;
    if (price == null || discount == null || price < 0 || discount < 0) {
      return {};
    }
    final saved = price * (discount / 100);
    final afterDiscount = price - saved;
    final taxAmount = afterDiscount * (tax / 100);
    final finalPrice = afterDiscount + taxAmount;
    return {
      'You save': _money(saved),
      'After discount': _money(afterDiscount),
      if (tax > 0) 'Tax': _money(taxAmount),
      'Final price': _money(finalPrice),
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
      toolId: 'discount_calculator',
      title: 'Discount Calculator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Original price',
              prefixText: '\$ ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _discount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Discount',
              suffixText: '%',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tax,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Tax (optional)',
              suffixText: '%',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          if (result.isEmpty)
            Text(
              'Enter a valid price and discount',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else ...[
            for (final e in result.entries) ...[
              Text(e.key, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              SelectableText(
                e.value,
                style: e.key == 'Final price'
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
            ],
            OutlinedButton.icon(
              onPressed: () {
                final text =
                    result.entries.map((e) => '${e.key}: ${e.value}').join('\n');
                ToolScaffold.copy(text, message: 'Summary copied');
                ToolScaffold.logAction(
                  toolId: 'discount_calculator',
                  toolName: 'Discount Calculator',
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
