import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class HtmlEntitiesView extends StatefulWidget {
  const HtmlEntitiesView({super.key});

  @override
  State<HtmlEntitiesView> createState() => _HtmlEntitiesViewState();
}

class _HtmlEntitiesViewState extends State<HtmlEntitiesView> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  String? _error;

  static const _named = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  };

  static const _namedDecode = {
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
    'copy': '©',
    'reg': '®',
    'trade': '™',
    'mdash': '—',
    'ndash': '–',
    'hellip': '…',
    'euro': '€',
    'pound': '£',
    'yen': '¥',
  };

  void _encode() {
    try {
      final buffer = StringBuffer();
      for (final rune in _input.text.runes) {
        final ch = String.fromCharCode(rune);
        if (_named.containsKey(ch)) {
          buffer.write(_named[ch]);
        } else if (rune > 127) {
          buffer.write('&#$rune;');
        } else {
          buffer.write(ch);
        }
      }
      _output.text = buffer.toString();
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'html_entities',
        toolName: 'HTML Entities',
        action: 'Encoded',
      );
    } catch (_) {
      setState(() => _error = 'Encode failed');
    }
  }

  void _decode() {
    try {
      var text = _input.text;
      text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
        return String.fromCharCode(int.parse(m[1]!, radix: 16));
      });
      text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
        return String.fromCharCode(int.parse(m[1]!));
      });
      text = text.replaceAllMapped(RegExp(r'&([a-zA-Z]+);'), (m) {
        return _namedDecode[m[1]!.toLowerCase()] ?? m[0]!;
      });
      _output.text = text;
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'html_entities',
        toolName: 'HTML Entities',
        action: 'Decoded',
      );
    } catch (_) {
      setState(() => _error = 'Decode failed');
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'html_entities',
      title: 'HTML Entities',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _input,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '<div class="hi">& café</div>',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(onPressed: _encode, child: const Text('Encode')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(onPressed: _decode, child: const Text('Decode')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _output,
            maxLines: 5,
            readOnly: true,
            decoration: const InputDecoration(hintText: 'Output'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => ToolScaffold.copy(_output.text),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
