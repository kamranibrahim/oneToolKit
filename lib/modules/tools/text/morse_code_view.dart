import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class MorseCodeView extends StatefulWidget {
  const MorseCodeView({super.key});

  @override
  State<MorseCodeView> createState() => _MorseCodeViewState();
}

class _MorseCodeViewState extends State<MorseCodeView> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  int _mode = 0; // 0 text→morse, 1 morse→text
  String? _error;

  static const _map = {
    'A': '.-',
    'B': '-...',
    'C': '-.-.',
    'D': '-..',
    'E': '.',
    'F': '..-.',
    'G': '--.',
    'H': '....',
    'I': '..',
    'J': '.---',
    'K': '-.-',
    'L': '.-..',
    'M': '--',
    'N': '-.',
    'O': '---',
    'P': '.--.',
    'Q': '--.-',
    'R': '.-.',
    'S': '...',
    'T': '-',
    'U': '..-',
    'V': '...-',
    'W': '.--',
    'X': '-..-',
    'Y': '-.--',
    'Z': '--..',
    '0': '-----',
    '1': '.----',
    '2': '..---',
    '3': '...--',
    '4': '....-',
    '5': '.....',
    '6': '-....',
    '7': '--...',
    '8': '---..',
    '9': '----.',
    '.': '.-.-.-',
    ',': '--..--',
    '?': '..--..',
    "'": '.----.',
    '!': '-.-.--',
    '/': '-..-.',
    '(': '-.--.',
    ')': '-.--.-',
    '&': '.-...',
    ':': '---...',
    ';': '-.-.-.',
    '=': '-...-',
    '+': '.-.-.',
    '-': '-....-',
    '_': '..--.-',
    '"': '.-..-.',
    '\$': '...-..-',
    '@': '.--.-.',
  };

  late final Map<String, String> _reverse = {
    for (final e in _map.entries) e.value: e.key,
  };

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  void _convert() {
    try {
      if (_mode == 0) {
        final buffer = StringBuffer();
        for (final rune in _input.text.toUpperCase().runes) {
          final ch = String.fromCharCode(rune);
          if (ch == ' ' || ch == '\n') {
            buffer.write(' / ');
            continue;
          }
          final code = _map[ch];
          if (code == null) throw Exception('Unsupported character: $ch');
          buffer.write('$code ');
        }
        _output.text = buffer.toString().trim();
      } else {
        final words = _input.text.trim().split(RegExp(r'\s*/\s*'));
        final buffer = StringBuffer();
        for (var w = 0; w < words.length; w++) {
          if (w > 0) buffer.write(' ');
          final letters = words[w].trim().split(RegExp(r'\s+'));
          for (final letter in letters) {
            if (letter.isEmpty) continue;
            final ch = _reverse[letter];
            if (ch == null) throw Exception('Unknown Morse: $letter');
            buffer.write(ch);
          }
        }
        _output.text = buffer.toString();
      }
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'morse_code',
        toolName: 'Morse Code',
        action: _mode == 0 ? 'Text → Morse' : 'Morse → text',
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _output.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'morse_code',
      title: 'Morse Code',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Text → Morse')),
              ButtonSegment(value: 1, label: Text('Morse → Text')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            maxLines: 5,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: _mode == 0 ? 'Text' : 'Morse (space = letter, / = word)',
              hintText: _mode == 0 ? 'SOS HELP' : '... --- ... / .... . .-.. .--.',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _convert, child: const Text('Convert')),
          const SizedBox(height: 16),
          TextField(
            controller: _output,
            readOnly: true,
            maxLines: 5,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: const InputDecoration(labelText: 'Output'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _output.text.isEmpty
                ? null
                : () => ToolScaffold.copy(_output.text),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy output'),
          ),
        ],
      ),
    );
  }
}
