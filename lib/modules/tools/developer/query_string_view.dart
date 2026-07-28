import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class QueryStringView extends StatefulWidget {
  const QueryStringView({super.key});

  @override
  State<QueryStringView> createState() => _QueryStringViewState();
}

class _QueryStringViewState extends State<QueryStringView> {
  final _input = TextEditingController(
    text: 'https://example.com/search?q=one+toolkit&page=1&sort=name',
  );
  final _output = TextEditingController();
  final List<_Pair> _pairs = [];
  String? _error;
  String _base = '';

  @override
  void initState() {
    super.initState();
    _parse(log: false);
  }

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    for (final p in _pairs) {
      p.dispose();
    }
    super.dispose();
  }

  void _parse({bool log = true}) {
    try {
      final raw = _input.text.trim();
      final hasScheme = raw.contains('://');
      final uri = Uri.parse(
        hasScheme
            ? raw
            : (raw.startsWith('?')
                ? 'https://x.invalid$raw'
                : 'https://x.invalid/?$raw'),
      );
      final pairs = <_Pair>[
        for (final e in uri.queryParameters.entries)
          _Pair(
            TextEditingController(text: e.key),
            TextEditingController(text: e.value),
          ),
      ];
      if (pairs.isEmpty) {
        pairs.add(_Pair(TextEditingController(), TextEditingController()));
      }
      for (final p in _pairs) {
        p.dispose();
      }
      setState(() {
        _error = null;
        _pairs
          ..clear()
          ..addAll(pairs);
        _base = hasScheme ? '${uri.scheme}://${uri.host}${uri.path}' : '';
        _rebuildOutput();
      });
      if (log) {
        ToolScaffold.logAction(
          toolId: 'query_string',
          toolName: 'Query String',
          action: 'Parsed',
        );
      }
    } catch (_) {
      setState(() => _error = 'Could not parse query string');
    }
  }

  void _rebuildOutput() {
    final params = <String, String>{};
    for (final p in _pairs) {
      final k = p.key.text.trim();
      if (k.isEmpty) continue;
      params[k] = p.value.text;
    }
    final query = Uri(queryParameters: params).query;
    _output.text = _base.isEmpty
        ? (query.isEmpty ? '' : '?$query')
        : (_base + (query.isEmpty ? '' : '?$query'));
  }

  void _addPair() {
    setState(() {
      _pairs.add(_Pair(TextEditingController(), TextEditingController()));
      _rebuildOutput();
    });
  }

  void _removePair(int index) {
    setState(() {
      _pairs.removeAt(index).dispose();
      if (_pairs.isEmpty) {
        _pairs.add(_Pair(TextEditingController(), TextEditingController()));
      }
      _rebuildOutput();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'query_string',
      title: 'Query String',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _input,
            maxLines: 3,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'URL or query string',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _parse, child: const Text('Parse')),
          const SizedBox(height: 20),
          Text('Parameters', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (var i = 0; i < _pairs.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pairs[i].key,
                    decoration: const InputDecoration(labelText: 'Key'),
                    onChanged: (_) => setState(_rebuildOutput),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _pairs[i].value,
                    decoration: const InputDecoration(labelText: 'Value'),
                    onChanged: (_) => setState(_rebuildOutput),
                  ),
                ),
                IconButton(
                  onPressed: () => _removePair(i),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addPair,
              icon: const Icon(Icons.add),
              label: const Text('Add parameter'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _output,
            readOnly: true,
            maxLines: 3,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: const InputDecoration(labelText: 'Built URL / query'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _output.text.isEmpty
                ? null
                : () {
                    ToolScaffold.copy(_output.text);
                    ToolScaffold.logAction(
                      toolId: 'query_string',
                      toolName: 'Query String',
                      action: 'Copied',
                    );
                  },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

class _Pair {
  _Pair(this.key, this.value);
  final TextEditingController key;
  final TextEditingController value;

  void dispose() {
    key.dispose();
    value.dispose();
  }
}
