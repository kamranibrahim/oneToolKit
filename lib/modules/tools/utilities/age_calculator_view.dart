import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class AgeCalculatorView extends StatefulWidget {
  const AgeCalculatorView({super.key});

  @override
  State<AgeCalculatorView> createState() => _AgeCalculatorViewState();
}

class _AgeCalculatorViewState extends State<AgeCalculatorView> {
  DateTime _birth = DateTime(1995, 1, 1);
  DateTime _asOf = DateTime.now();

  Future<void> _pickBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _pickAsOf() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOf,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _asOf = picked);
  }

  ({int years, int months, int days, int totalDays}) get _age {
    var years = _asOf.year - _birth.year;
    var months = _asOf.month - _birth.month;
    var days = _asOf.day - _birth.day;
    if (days < 0) {
      final prevMonth = DateTime(_asOf.year, _asOf.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }
    final totalDays = _asOf.difference(_birth).inDays;
    return (years: years, months: months, days: days, totalDays: totalDays);
  }

  String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = _age;
    return ToolScaffold(
      toolId: 'age_calculator',
      title: 'Age Calculator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Exact age between two dates — years, months, and days.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Birth date'),
            subtitle: Text(_d(_birth)),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: _pickBirth,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('As of'),
            subtitle: Text(_d(_asOf)),
            trailing: const Icon(Icons.event_rounded),
            onTap: _pickAsOf,
          ),
          const SizedBox(height: 12),
          Text(
            '${age.years} years · ${age.months} months · ${age.days} days',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('${age.totalDays} total days', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              final text =
                  'Age: ${age.years}y ${age.months}m ${age.days}d (${age.totalDays} days) · '
                  '${_d(_birth)} → ${_d(_asOf)}';
              Clipboard.setData(ClipboardData(text: text));
              ToolScaffold.copy(text, message: 'Age copied');
              ToolScaffold.logAction(
                toolId: 'age_calculator',
                toolName: 'Age Calculator',
                action: 'Calculated',
                detail: '${age.years}y',
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
