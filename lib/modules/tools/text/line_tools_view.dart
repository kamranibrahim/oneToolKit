import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class LineToolsView extends StatefulWidget {
  const LineToolsView({super.key});

  @override
  State<LineToolsView> createState() => _LineToolsViewState();
}

class _LineToolsViewState extends State<LineToolsView> {
  final _controller = TextEditingController();

  List<String> get _lines =>
      _controller.text.replaceAll('\r\n', '\n').split('\n');

  void _apply(List<String> Function(List<String>) transform, String action) {
    final next = transform(_lines).join('\n');
    setState(() => _controller.text = next);
    ToolScaffold.logAction(
      toolId: 'line_tools',
      toolName: 'Line Tools',
      action: action,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _lines.where((l) => l.isNotEmpty).length;
    return ToolScaffold(
      toolId: 'line_tools',
      title: 'Line Tools',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$count non-empty line${count == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  hintText: 'One item per line…',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _apply(
                    (l) => [...l]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
                    'Sorted A→Z',
                  ),
                  child: const Text('Sort A→Z'),
                ),
                OutlinedButton(
                  onPressed: () => _apply(
                    (l) => [...l]
                      ..sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase())),
                    'Sorted Z→A',
                  ),
                  child: const Text('Sort Z→A'),
                ),
                OutlinedButton(
                  onPressed: () => _apply((l) {
                    final seen = <String>{};
                    return l.where((e) => seen.add(e)).toList();
                  }, 'Unique'),
                  child: const Text('Unique'),
                ),
                OutlinedButton(
                  onPressed: () => _apply((l) => l.reversed.toList(), 'Reversed'),
                  child: const Text('Reverse'),
                ),
                OutlinedButton(
                  onPressed: () => _apply(
                    (l) => l.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                    'Trimmed blanks',
                  ),
                  child: const Text('Trim blanks'),
                ),
                OutlinedButton(
                  onPressed: () => _apply(
                    (l) => [
                      for (var i = 0; i < l.length; i++) '${i + 1}. ${l[i]}',
                    ],
                    'Numbered',
                  ),
                  child: const Text('Number'),
                ),
                IconButton.filledTonal(
                  onPressed: () => ToolScaffold.copy(_controller.text),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
