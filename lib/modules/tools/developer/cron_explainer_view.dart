import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class CronExplainerView extends StatefulWidget {
  const CronExplainerView({super.key});

  @override
  State<CronExplainerView> createState() => _CronExplainerViewState();
}

class _CronExplainerViewState extends State<CronExplainerView> {
  final _controller = TextEditingController(text: '0 9 * * 1-5');
  String? _error;
  List<_CronField> _fields = const [];
  String _summary = '';

  static const _presets = {
    'Every minute': '* * * * *',
    'Hourly': '0 * * * *',
    'Daily 9am': '0 9 * * *',
    'Weekdays 9am': '0 9 * * 1-5',
    'Monthly 1st': '0 0 1 * *',
    'Sunday midnight': '0 0 * * 0',
  };

  @override
  void initState() {
    super.initState();
    _parse(log: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parse({bool log = true}) {
    final parts = _controller.text.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) {
      setState(() {
        _error = 'Need 5 fields: minute hour day month weekday';
        _fields = const [];
        _summary = '';
      });
      return;
    }

    try {
      final fields = [
        _CronField('Minute', parts[0], _describe(parts[0], 0, 59, 'minute')),
        _CronField('Hour', parts[1], _describe(parts[1], 0, 23, 'hour')),
        _CronField('Day of month', parts[2], _describe(parts[2], 1, 31, 'day')),
        _CronField('Month', parts[3], _describeMonth(parts[3])),
        _CronField('Weekday', parts[4], _describeWeekday(parts[4])),
      ];
      setState(() {
        _error = null;
        _fields = fields;
        _summary =
            'At ${fields[0].meaning.toLowerCase()}, ${fields[1].meaning.toLowerCase()}, '
            '${fields[2].meaning.toLowerCase()}, ${fields[3].meaning.toLowerCase()}, '
            '${fields[4].meaning.toLowerCase()}.';
      });
      if (log) {
        ToolScaffold.logAction(
          toolId: 'cron_explainer',
          toolName: 'Cron Explainer',
          action: 'Explained',
          detail: _controller.text.trim(),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _fields = const [];
        _summary = '';
      });
    }
  }

  String _describe(String expr, int min, int max, String unit) {
    if (expr == '*') return 'every $unit';
    if (expr.startsWith('*/')) {
      final step = int.parse(expr.substring(2));
      return 'every $step ${unit}s';
    }
    if (expr.contains(',')) {
      return 'at ${expr.split(',').join(', ')}';
    }
    if (expr.contains('-')) {
      final parts = expr.split('-');
      return 'from ${parts[0]} through ${parts[1]}';
    }
    final n = int.parse(expr);
    if (n < min || n > max) throw Exception('$unit out of range ($min–$max)');
    return 'at $n';
  }

  String _describeMonth(String expr) {
    const names = {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
    };
    if (expr == '*') return 'every month';
    if (expr.startsWith('*/')) {
      return 'every ${expr.substring(2)} months';
    }
    if (expr.contains(',')) {
      return expr.split(',').map((e) => names[e] ?? e).join(', ');
    }
    if (expr.contains('-')) {
      final p = expr.split('-');
      return '${names[p[0]] ?? p[0]}–${names[p[1]] ?? p[1]}';
    }
    return names[expr] ?? 'month $expr';
  }

  String _describeWeekday(String expr) {
    const names = {
      '0': 'Sunday',
      '1': 'Monday',
      '2': 'Tuesday',
      '3': 'Wednesday',
      '4': 'Thursday',
      '5': 'Friday',
      '6': 'Saturday',
      '7': 'Sunday',
    };
    if (expr == '*') return 'every day of the week';
    if (expr.startsWith('*/')) {
      return 'every ${expr.substring(2)} weekdays';
    }
    if (expr.contains(',')) {
      return expr.split(',').map((e) => names[e] ?? e).join(', ');
    }
    if (expr.contains('-')) {
      final p = expr.split('-');
      return '${names[p[0]] ?? p[0]}–${names[p[1]] ?? p[1]}';
    }
    return names[expr] ?? 'weekday $expr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'cron_explainer',
      title: 'Cron Explainer',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'Cron expression',
              hintText: 'minute hour day month weekday',
              errorText: _error,
              suffixIcon: IconButton(
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: _parse,
              ),
            ),
            onSubmitted: (_) => _parse(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _presets.entries)
                ActionChip(
                  label: Text(e.key),
                  onPressed: () {
                    _controller.text = e.value;
                    _parse();
                  },
                ),
            ],
          ),
          if (_summary.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Summary', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SelectableText(_summary, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => ToolScaffold.copy(_summary),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy summary'),
              ),
            ),
            const SizedBox(height: 16),
            Text('Fields', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final f in _fields)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(f.label),
                subtitle: Text(f.meaning),
                trailing: Text(
                  f.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CronField {
  const _CronField(this.label, this.value, this.meaning);
  final String label;
  final String value;
  final String meaning;
}
