import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class HtmlFormatterView extends StatefulWidget {
  const HtmlFormatterView({super.key});

  @override
  State<HtmlFormatterView> createState() => _HtmlFormatterViewState();
}

class _HtmlFormatterViewState extends State<HtmlFormatterView> {
  final _controller = TextEditingController();
  String? _error;

  void _beautify() {
    try {
      _controller.text = _formatHtml(_controller.text, minify: false);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'html_formatter',
        toolName: 'HTML Formatter',
        action: 'Beautified',
      );
    } catch (_) {
      setState(() => _error = 'Could not format HTML');
    }
  }

  void _minify() {
    try {
      _controller.text = _formatHtml(_controller.text, minify: true);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'html_formatter',
        toolName: 'HTML Formatter',
        action: 'Minified',
      );
    } catch (_) {
      setState(() => _error = 'Could not minify HTML');
    }
  }

  /// Lightweight structural indent — not a full HTML parser.
  String _formatHtml(String input, {required bool minify}) {
    final compact = input
        .replaceAll(RegExp(r'>\s+<'), '><')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (minify) return compact;

    final tokens = RegExp(r'(<[^>]+>|[^<]+)')
        .allMatches(compact)
        .map((m) => m.group(0)!)
        .where((t) => t.trim().isNotEmpty)
        .toList();

    final buffer = StringBuffer();
    var depth = 0;
    for (final token in tokens) {
      final trimmed = token.trim();
      final isClosing = RegExp(r'^</\w').hasMatch(trimmed);
      final isSelfClosing = RegExp(r'/>$').hasMatch(trimmed) ||
          RegExp(r'^<(br|hr|img|input|meta|link|source|area|base|col|embed|wbr)\b',
                  caseSensitive: false)
              .hasMatch(trimmed);
      final isDoctypeOrComment = trimmed.startsWith('<!') || trimmed.startsWith('<?');

      if (isClosing) depth = (depth - 1).clamp(0, 64);
      if (!trimmed.startsWith('<')) {
        buffer.writeln('${'  ' * depth}$trimmed');
        continue;
      }
      buffer.writeln('${'  ' * depth}$trimmed');
      if (!isClosing && !isSelfClosing && !isDoctypeOrComment) {
        depth += 1;
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
    return ToolScaffold(
      toolId: 'html_formatter',
      title: 'HTML Formatter',
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
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Paste HTML…',
                  errorText: _error,
                  alignLabelWithHint: true,
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
                IconButton(
                  tooltip: 'Copy',
                  onPressed: () =>
                      ToolScaffold.copy(_controller.text, message: 'Copied'),
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
