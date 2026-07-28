import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class DaysUntilView extends StatefulWidget {
  const DaysUntilView({super.key});

  @override
  State<DaysUntilView> createState() => _DaysUntilViewState();
}

class _DaysUntilViewState extends State<DaysUntilView> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now().add(const Duration(days: 30));

  DateTime get _fromDay => DateTime(_from.year, _from.month, _from.day);
  DateTime get _toDay => DateTime(_to.year, _to.month, _to.day);

  int get _days => _toDay.difference(_fromDay).inDays;

  String get _summary {
    final d = _days;
    if (d == 0) return 'Same day';
    if (d > 0) {
      return d == 1 ? '1 day until target' : '$d days until target';
    }
    final past = -d;
    return past == 1 ? '1 day ago' : '$past days ago';
  }

  String get _breakdown {
    var start = _fromDay;
    var end = _toDay;
    var sign = 1;
    if (end.isBefore(start)) {
      final tmp = start;
      start = end;
      end = tmp;
      sign = -1;
    }
    var years = end.year - start.year;
    var months = end.month - start.month;
    var days = end.day - start.day;
    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(end.year, end.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    final parts = <String>[];
    if (years > 0) parts.add('$years year${years == 1 ? '' : 's'}');
    if (months > 0) parts.add('$months month${months == 1 ? '' : 's'}');
    if (days > 0 || parts.isEmpty) {
      parts.add('$days day${days == 1 ? '' : 's'}');
    }
    final text = parts.join(', ');
    return sign < 0 ? '$text (past)' : text;
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _to = picked);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'days_until',
      title: 'Days Until',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('From'),
            subtitle: Text(_fmt(_from)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickFrom,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('To'),
            subtitle: Text(_fmt(_to)),
            trailing: const Icon(Icons.event_outlined),
            onTap: _pickTo,
          ),
          const SizedBox(height: 16),
          Text(_summary, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _breakdown,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exact days: $_days',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Today → +7'),
                onPressed: () => setState(() {
                  _from = DateTime.now();
                  _to = DateTime.now().add(const Duration(days: 7));
                }),
              ),
              ActionChip(
                label: const Text('Today → +30'),
                onPressed: () => setState(() {
                  _from = DateTime.now();
                  _to = DateTime.now().add(const Duration(days: 30));
                }),
              ),
              ActionChip(
                label: const Text('Swap'),
                onPressed: () => setState(() {
                  final tmp = _from;
                  _from = _to;
                  _to = tmp;
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              final text =
                  '$_summary\n$_breakdown\nFrom ${_fmt(_from)} to ${_fmt(_to)}';
              ToolScaffold.copy(text, message: 'Copied');
              ToolScaffold.logAction(
                toolId: 'days_until',
                toolName: 'Days Until',
                action: 'Copied',
                detail: _summary,
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
