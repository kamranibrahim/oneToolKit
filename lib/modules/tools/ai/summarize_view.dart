import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

/// Offline extractive summary — ranks sentences by word frequency.
class SummarizeView extends StatefulWidget {
  const SummarizeView({super.key});

  @override
  State<SummarizeView> createState() => _SummarizeViewState();
}

class _SummarizeViewState extends State<SummarizeView> {
  final _input = TextEditingController();
  double _ratio = 0.3;
  String _output = '';
  String? _status;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  static final _stop = {
    'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'as', 'by', 'with', 'from', 'is', 'are', 'was', 'were', 'be',
    'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
    'would', 'could', 'should', 'may', 'might', 'must', 'shall', 'can',
    'this', 'that', 'these', 'those', 'it', 'its', 'they', 'them', 'their',
    'we', 'our', 'you', 'your', 'he', 'she', 'his', 'her', 'i', 'me', 'my',
    'not', 'no', 'so', 'if', 'than', 'then', 'there', 'here', 'what', 'which',
    'who', 'whom', 'when', 'where', 'why', 'how', 'also', 'just', 'into',
  };

  List<String> _sentences(String text) {
    final parts = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts;
  }

  String _summarize(String text) {
    final sentences = _sentences(text);
    if (sentences.length <= 2) return text.trim();

    final freq = <String, int>{};
    for (final sentence in sentences) {
      for (final raw in sentence.toLowerCase().split(RegExp(r'[^a-z0-9]+'))) {
        if (raw.length < 3 || _stop.contains(raw)) continue;
        freq[raw] = (freq[raw] ?? 0) + 1;
      }
    }

    final scored = <({int index, double score, String text})>[];
    for (var i = 0; i < sentences.length; i++) {
      final words = sentences[i]
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((w) => w.length >= 3 && !_stop.contains(w));
      var score = 0.0;
      var count = 0;
      for (final w in words) {
        score += freq[w] ?? 0;
        count++;
      }
      // Prefer earlier sentences slightly (lead bias).
      final lead = 1.0 + (sentences.length - i) / sentences.length * 0.15;
      scored.add((
        index: i,
        score: (count == 0 ? 0.0 : score / count) * lead,
        text: sentences[i],
      ));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final keep = (sentences.length * _ratio).ceil().clamp(1, sentences.length);
    final chosen = scored.take(keep).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return chosen.map((s) => s.text).join(' ');
  }

  Future<void> _run() async {
    final text = _input.text.trim();
    if (text.isEmpty) {
      ToolScaffold.copy('', message: 'Paste text to summarize');
      return;
    }
    final summary = _summarize(text);
    setState(() {
      _output = summary;
      final before = text.split(RegExp(r'\s+')).length;
      final after = summary.split(RegExp(r'\s+')).length;
      _status = 'Reduced ~$before → $after words (offline extractive)';
    });
    await ToolScaffold.logAction(
      toolId: 'ai_summarize',
      toolName: 'Summarize',
      action: 'Summarized',
      detail: '${(_ratio * 100).round()}% keep',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'ai_summarize',
      title: 'Summarize',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Offline extractive summary — keeps the most informative sentences. No cloud, no model download.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            minLines: 8,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: 'Text',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Text('Keep ~${(_ratio * 100).round()}% of sentences'),
          Slider(
            value: _ratio,
            min: 0.15,
            max: 0.6,
            divisions: 9,
            onChanged: (v) => setState(() => _ratio = v),
          ),
          FilledButton.icon(
            onPressed: _run,
            icon: const Icon(Icons.summarize_rounded),
            label: const Text('Summarize'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, textAlign: TextAlign.center),
          ],
          if (_output.isNotEmpty) ...[
            const SizedBox(height: 16),
            SelectableText(_output, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _output));
                ToolScaffold.copy(_output, message: 'Summary copied');
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy'),
            ),
          ],
        ],
      ),
    );
  }
}
