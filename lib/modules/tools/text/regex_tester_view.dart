import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class RegexTesterView extends StatefulWidget {
  const RegexTesterView({super.key});

  @override
  State<RegexTesterView> createState() => _RegexTesterViewState();
}

class _RegexTesterViewState extends State<RegexTesterView> {
  final _pattern = TextEditingController(text: r'\b\w+@\w+\.\w+\b');
  final _input = TextEditingController(
    text: 'Contact us at hello@onetoolkit.app or support@example.com',
  );
  bool _caseSensitive = true;
  bool _multiLine = false;
  bool _dotAll = false;
  String? _error;
  List<RegExpMatch> _matches = [];

  void _run() {
    try {
      final re = RegExp(
        _pattern.text,
        caseSensitive: _caseSensitive,
        multiLine: _multiLine,
        dotAll: _dotAll,
      );
      setState(() {
        _matches = re.allMatches(_input.text).toList();
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _matches = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _pattern.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'regex_tester',
      title: 'Regex Tester',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _pattern,
            decoration: InputDecoration(
              labelText: 'Pattern',
              errorText: _error,
            ),
            onChanged: (_) => _run(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Case'),
                selected: _caseSensitive,
                onSelected: (v) {
                  setState(() => _caseSensitive = v);
                  _run();
                },
              ),
              FilterChip(
                label: const Text('Multi-line'),
                selected: _multiLine,
                onSelected: (v) {
                  setState(() => _multiLine = v);
                  _run();
                },
              ),
              FilterChip(
                label: const Text('DotAll'),
                selected: _dotAll,
                onSelected: (v) {
                  setState(() => _dotAll = v);
                  _run();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _input,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Test string'),
            onChanged: (_) => _run(),
          ),
          const SizedBox(height: 12),
          Text(
            '${_matches.length} match(es)',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._matches.map(
            (m) => Card(
              child: ListTile(
                title: Text(m.group(0) ?? ''),
                subtitle: Text('Index ${m.start}–${m.end}'),
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () => ToolScaffold.copy(m.group(0) ?? ''),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
