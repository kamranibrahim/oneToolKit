import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class DiffCheckerView extends StatefulWidget {
  const DiffCheckerView({super.key});

  @override
  State<DiffCheckerView> createState() => _DiffCheckerViewState();
}

class _DiffCheckerViewState extends State<DiffCheckerView> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  List<_DiffLine> _diff = [];

  void _compare() {
    final aLines = _a.text.split('\n');
    final bLines = _b.text.split('\n');
    final maxLen = aLines.length > bLines.length ? aLines.length : bLines.length;
    final result = <_DiffLine>[];
    for (var i = 0; i < maxLen; i++) {
      final left = i < aLines.length ? aLines[i] : null;
      final right = i < bLines.length ? bLines[i] : null;
      if (left == right) {
        result.add(_DiffLine(type: _DiffType.same, text: left ?? ''));
      } else {
        if (left != null) {
          result.add(_DiffLine(type: _DiffType.removed, text: left));
        }
        if (right != null) {
          result.add(_DiffLine(type: _DiffType.added, text: right));
        }
      }
    }
    setState(() => _diff = result);
    ToolScaffold.logAction(
      toolId: 'diff_checker',
      toolName: 'Diff Checker',
      action: 'Compared',
      detail: '${result.where((d) => d.type != _DiffType.same).length} diffs',
    );
  }

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'diff_checker',
      title: 'Diff Checker',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _a,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Original'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _b,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Modified'),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _compare, child: const Text('Compare')),
          const SizedBox(height: 16),
          if (_diff.isNotEmpty)
            ..._diff.map((line) {
              final color = switch (line.type) {
                _DiffType.same => theme.cardTheme.color,
                _DiffType.added => Colors.green.withValues(alpha: 0.15),
                _DiffType.removed => Colors.red.withValues(alpha: 0.15),
              };
              final prefix = switch (line.type) {
                _DiffType.same => '  ',
                _DiffType.added => '+ ',
                _DiffType.removed => '- ',
              };
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: color,
                child: Text(
                  '$prefix${line.text}',
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              );
            }),
        ],
      ),
    );
  }
}

enum _DiffType { same, added, removed }

class _DiffLine {
  _DiffLine({required this.type, required this.text});
  final _DiffType type;
  final String text;
}
