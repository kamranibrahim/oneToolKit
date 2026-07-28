import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class SlugifyView extends StatefulWidget {
  const SlugifyView({super.key});

  @override
  State<SlugifyView> createState() => _SlugifyViewState();
}

class _SlugifyViewState extends State<SlugifyView> {
  final _input = TextEditingController();
  String _separator = '-';
  bool _lowercase = true;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String get _slug {
    var text = _input.text.trim();
    if (_lowercase) text = text.toLowerCase();

    // Common accent fold
    const map = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ñ': 'n',
      'ç': 'c',
      'ß': 'ss',
      'æ': 'ae',
      'œ': 'oe',
    };
    final folded = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      folded.write(map[ch] ?? ch);
    }

    final sep = RegExp.escape(_separator);
    var slug = folded
        .toString()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), _separator)
        .replaceAll(RegExp('$sep+'), _separator)
        .replaceAll(RegExp('^$sep|$sep\$'), '');
    return slug;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slug = _slug;
    return ToolScaffold(
      toolId: 'slugify',
      title: 'Slugify',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _input,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Title or phrase',
              hintText: 'Hello World — One Toolkit!',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('Separator', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '-', label: Text('-')),
              ButtonSegment(value: '_', label: Text('_')),
              ButtonSegment(value: '.', label: Text('.')),
            ],
            selected: {_separator},
            onSelectionChanged: (s) => setState(() => _separator = s.first),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lowercase'),
            value: _lowercase,
            onChanged: (v) => setState(() => _lowercase = v),
          ),
          const SizedBox(height: 12),
          Text('Slug', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SelectableText(
            slug.isEmpty ? '—' : slug,
            style: theme.textTheme.titleLarge?.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: slug.isEmpty
                ? null
                : () {
                    ToolScaffold.copy(slug, message: 'Slug copied');
                    ToolScaffold.logAction(
                      toolId: 'slugify',
                      toolName: 'Slugify',
                      action: 'Copied',
                      detail: slug,
                    );
                  },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy slug'),
          ),
        ],
      ),
    );
  }
}
