import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

import '../../../widgets/tool_scaffold.dart';

class CalculatorView extends StatefulWidget {
  const CalculatorView({super.key});

  @override
  State<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends State<CalculatorView> {
  String _expression = '';
  String _result = '0';
  final _history = <String>[];

  void _tap(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '0';
        return;
      }
      if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
        return;
      }
      if (value == '=') {
        _evaluate();
        return;
      }
      _expression += value;
    });
  }

  void _evaluate() {
    if (_expression.trim().isEmpty) return;
    try {
      final parsed = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('%', '/100');
      final expression = GrammarParser().parse(parsed);
      final value = RealEvaluator().evaluate(expression);
      final formatted = _format(value);
      setState(() {
        _result = formatted;
        _history.insert(0, '$_expression = $formatted');
        if (_history.length > 20) _history.removeLast();
        _expression = formatted;
      });
      ToolScaffold.logAction(
        toolId: 'calculator',
        toolName: 'Calculator',
        action: 'Calculated',
        detail: formatted,
      );
    } catch (_) {
      setState(() => _result = 'Error');
    }
  }

  String _format(num value) {
    if (value is int || value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = const [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '(', ')'],
      ['='],
    ];

    return ToolScaffold(
      toolId: 'calculator',
      title: 'Calculator',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: SelectableText(
                    _expression.isEmpty ? ' ' : _expression,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SelectableText(
                    _result,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('History', style: theme.textTheme.titleSmall),
                  ..._history.take(8).map(
                        (h) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(h),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: h));
                              ToolScaffold.copy(h, message: 'Copied');
                            },
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              children: keys.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: row.map((key) {
                      final isOp = '÷×-+%='.contains(key);
                      return Expanded(
                        flex: key == '=' ? 4 : 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: isOp
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              foregroundColor: isOp
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => _tap(key),
                            child: Text(
                              key,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
