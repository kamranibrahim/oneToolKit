import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class WordCounterView extends StatefulWidget {
  const WordCounterView({super.key});

  @override
  State<WordCounterView> createState() => _WordCounterViewState();
}

class _WordCounterViewState extends State<WordCounterView> {
  final _controller = TextEditingController();

  int get words {
    final t = _controller.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  int get chars => _controller.text.length;
  int get charsNoSpace => _controller.text.replaceAll(RegExp(r'\s'), '').length;
  int get lines => _controller.text.isEmpty ? 0 : _controller.text.split('\n').length;
  int get sentences {
    final t = _controller.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'word_counter',
      title: 'Word Counter',
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
                decoration: const InputDecoration(
                  hintText: 'Paste or type your text…',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: 'Words', value: '$words'),
                _StatChip(label: 'Characters', value: '$chars'),
                _StatChip(label: 'No spaces', value: '$charsNoSpace'),
                _StatChip(label: 'Lines', value: '$lines'),
                _StatChip(label: 'Sentences', value: '$sentences'),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                },
                child: const Text('Clear'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
