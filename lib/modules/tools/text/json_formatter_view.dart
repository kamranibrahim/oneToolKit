import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class JsonFormatterView extends StatefulWidget {
  const JsonFormatterView({super.key});

  @override
  State<JsonFormatterView> createState() => _JsonFormatterViewState();
}

class _JsonFormatterViewState extends State<JsonFormatterView> {
  final _controller = TextEditingController();
  String? _error;

  void _beautify() {
    try {
      final decoded = jsonDecode(_controller.text);
      _controller.text = const JsonEncoder.withIndent('  ').convert(decoded);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'json_formatter',
        toolName: 'JSON Formatter',
        action: 'Beautified',
      );
    } catch (e) {
      setState(() => _error = 'Invalid JSON');
    }
  }

  void _minify() {
    try {
      final decoded = jsonDecode(_controller.text);
      _controller.text = jsonEncode(decoded);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'json_formatter',
        toolName: 'JSON Formatter',
        action: 'Minified',
      );
    } catch (e) {
      setState(() => _error = 'Invalid JSON');
    }
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
      toolId: 'json_formatter',
      title: 'JSON Formatter',
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
                  hintText: '{"hello": "world"}',
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
