import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class SqlFormatterView extends StatefulWidget {
  const SqlFormatterView({super.key});

  @override
  State<SqlFormatterView> createState() => _SqlFormatterViewState();
}

class _SqlFormatterViewState extends State<SqlFormatterView> {
  final _controller = TextEditingController();
  String? _error;

  static const _keywords = {
    'select',
    'from',
    'where',
    'and',
    'or',
    'join',
    'inner',
    'left',
    'right',
    'outer',
    'full',
    'on',
    'group',
    'by',
    'order',
    'having',
    'limit',
    'offset',
    'insert',
    'into',
    'values',
    'update',
    'set',
    'delete',
    'create',
    'table',
    'alter',
    'drop',
    'as',
    'in',
    'not',
    'null',
    'is',
    'like',
    'between',
    'union',
    'all',
    'distinct',
    'case',
    'when',
    'then',
    'else',
    'end',
    'with',
    'exists',
  };

  void _beautify() {
    try {
      _controller.text = _formatSql(_controller.text, minify: false);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'sql_formatter',
        toolName: 'SQL Formatter',
        action: 'Beautified',
      );
    } catch (_) {
      setState(() => _error = 'Could not format SQL');
    }
  }

  void _minify() {
    try {
      _controller.text = _formatSql(_controller.text, minify: true);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'sql_formatter',
        toolName: 'SQL Formatter',
        action: 'Minified',
      );
    } catch (_) {
      setState(() => _error = 'Could not minify SQL');
    }
  }

  String _formatSql(String input, {required bool minify}) {
    final compact = input
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*,\s*'), ', ')
        .replaceAll(RegExp(r'\s*\(\s*'), ' (')
        .replaceAll(RegExp(r'\s*\)\s*'), ') ')
        .trim();
    if (minify) return compact;

    final tokens = compact.split(' ');
    final buffer = StringBuffer();
    var depth = 0;
    var lineStart = true;

    for (var i = 0; i < tokens.length; i++) {
      var token = tokens[i];
      if (token.isEmpty) continue;

      final lower = token.toLowerCase().replaceAll(RegExp(r'[(),;]$'), '');
      final isKeyword = _keywords.contains(lower);
      final breakBefore = isKeyword &&
          {
            'select',
            'from',
            'where',
            'and',
            'or',
            'join',
            'inner',
            'left',
            'right',
            'outer',
            'full',
            'group',
            'order',
            'having',
            'limit',
            'offset',
            'union',
            'values',
            'set',
            'on',
            'when',
            'else',
            'end',
          }.contains(lower);

      if (token.contains(')')) depth = (depth - 1).clamp(0, 32);

      if (breakBefore && !lineStart) {
        buffer.writeln();
        buffer.write('  ' * depth);
        lineStart = true;
      }

      if (!lineStart) buffer.write(' ');
      buffer.write(isKeyword ? token.toUpperCase() : token);
      lineStart = false;

      if (token.contains('(')) depth += 1;
      if (token.endsWith(';')) {
        buffer.writeln();
        lineStart = true;
        depth = 0;
      }
    }

    return buffer.toString().trimRight();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'sql_formatter',
      title: 'SQL Formatter',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'SELECT * FROM users WHERE id = 1;',
                  errorText: _error,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _beautify,
                    child: const Text('Beautify'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _minify,
                    child: const Text('Minify'),
                  ),
                ),
                const SizedBox(width: 10),
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
