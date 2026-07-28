import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class MarkdownPreviewView extends StatefulWidget {
  const MarkdownPreviewView({super.key});

  @override
  State<MarkdownPreviewView> createState() => _MarkdownPreviewViewState();
}

class _MarkdownPreviewViewState extends State<MarkdownPreviewView> {
  final _controller = TextEditingController(
    text: '# Hello\n\n**Bold** and *italic*\n\n- Item one\n- Item two\n\n`inline code`',
  );

  /// Lightweight markdown → styled spans (no external md package).
  List<InlineSpan> _parse(String source) {
    final spans = <InlineSpan>[];
    for (final line in source.split('\n')) {
      if (line.startsWith('# ')) {
        spans.add(TextSpan(
          text: '${line.substring(2)}\n',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.6),
        ));
      } else if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: '${line.substring(3)}\n',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.6),
        ));
      } else if (line.startsWith('- ')) {
        spans.add(TextSpan(text: '• ${line.substring(2)}\n', style: const TextStyle(height: 1.6)));
      } else {
        spans.add(_inline(line));
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }

  TextSpan _inline(String line) {
    final children = <InlineSpan>[];
    final regex = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
    var start = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > start) {
        children.add(TextSpan(text: line.substring(start, match.start)));
      }
      final token = match.group(0)!;
      if (token.startsWith('**')) {
        children.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      } else if (token.startsWith('*')) {
        children.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('`')) {
        children.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: const TextStyle(fontFamily: 'monospace', backgroundColor: Color(0x22000000)),
        ));
      }
      start = match.end;
    }
    if (start < line.length) children.add(TextSpan(text: line.substring(start)));
    return TextSpan(children: children, style: const TextStyle(height: 1.6));
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
      toolId: 'markdown_preview',
      title: 'Markdown Preview',
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
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Markdown…'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: _parse(_controller.text),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
