import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class CssFormatterView extends StatefulWidget {
  const CssFormatterView({super.key});

  @override
  State<CssFormatterView> createState() => _CssFormatterViewState();
}

class _CssFormatterViewState extends State<CssFormatterView> {
  final _controller = TextEditingController();
  String? _error;

  void _beautify() {
    try {
      _controller.text = _formatCss(_controller.text, minify: false);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'css_formatter',
        toolName: 'CSS Formatter',
        action: 'Beautified',
      );
    } catch (_) {
      setState(() => _error = 'Could not format CSS');
    }
  }

  void _minify() {
    try {
      _controller.text = _formatCss(_controller.text, minify: true);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'css_formatter',
        toolName: 'CSS Formatter',
        action: 'Minified',
      );
    } catch (_) {
      setState(() => _error = 'Could not minify CSS');
    }
  }

  String _formatCss(String input, {required bool minify}) {
    var s = input
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (minify) {
      return s
          .replaceAll(RegExp(r'\s*{\s*'), '{')
          .replaceAll(RegExp(r'\s*}\s*'), '}')
          .replaceAll(RegExp(r'\s*;\s*'), ';')
          .replaceAll(RegExp(r'\s*:\s*'), ':')
          .replaceAll(RegExp(r'\s*,\s*'), ',');
    }

    final buffer = StringBuffer();
    var depth = 0;
    var i = 0;
    while (i < s.length) {
      final ch = s[i];
      if (ch == '{') {
        buffer.write(' {\n');
        depth += 1;
        buffer.write('  ' * depth);
        i += 1;
        continue;
      }
      if (ch == '}') {
        depth = (depth - 1).clamp(0, 32);
        buffer.write('\n');
        buffer.write('  ' * depth);
        buffer.write('}');
        if (i + 1 < s.length) {
          buffer.write('\n');
          buffer.write('  ' * depth);
        }
        i += 1;
        continue;
      }
      if (ch == ';') {
        buffer.write(';\n');
        buffer.write('  ' * depth);
        i += 1;
        while (i < s.length && s[i] == ' ') {
          i += 1;
        }
        continue;
      }
      if (ch == ':' && depth > 0) {
        buffer.write(': ');
        i += 1;
        while (i < s.length && s[i] == ' ') {
          i += 1;
        }
        continue;
      }
      buffer.write(ch);
      i += 1;
    }
    return buffer.toString().replaceAll(RegExp(r'[ \t]+\n'), '\n').trimRight();
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
      toolId: 'css_formatter',
      title: 'CSS Formatter',
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
                  hintText: 'body { color: #111; margin: 0; }',
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
