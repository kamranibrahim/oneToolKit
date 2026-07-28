import 'dart:math';

import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class LoremIpsumView extends StatefulWidget {
  const LoremIpsumView({super.key});

  @override
  State<LoremIpsumView> createState() => _LoremIpsumViewState();
}

class _LoremIpsumViewState extends State<LoremIpsumView> {
  int _paragraphs = 2;
  String _result = '';

  static const _words = [
    'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing',
    'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore',
    'et', 'dolore', 'magna', 'aliqua', 'enim', 'ad', 'minim', 'veniam',
    'quis', 'nostrud', 'exercitation', 'ullamco', 'laboris', 'nisi',
    'aliquip', 'ex', 'ea', 'commodo', 'consequat', 'duis', 'aute', 'irure',
    'in', 'reprehenderit', 'voluptate', 'velit', 'esse', 'cillum', 'fugiat',
    'nulla', 'pariatur', 'excepteur', 'sint', 'occaecat', 'cupidatat',
    'non', 'proident', 'sunt', 'culpa', 'qui', 'officia', 'deserunt',
    'mollit', 'anim', 'id', 'est', 'laborum',
  ];

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final rng = Random();
    final parts = <String>[];
    for (var p = 0; p < _paragraphs; p++) {
      final sentenceCount = 3 + rng.nextInt(3);
      final sentences = <String>[];
      for (var s = 0; s < sentenceCount; s++) {
        final wordCount = 8 + rng.nextInt(10);
        final words = List.generate(wordCount, (_) => _words[rng.nextInt(_words.length)]);
        words[0] = '${words[0][0].toUpperCase()}${words[0].substring(1)}';
        sentences.add('${words.join(' ')}.');
      }
      parts.add(sentences.join(' '));
    }
    setState(() => _result = parts.join('\n\n'));
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'lorem_ipsum',
      title: 'Lorem Ipsum',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Paragraphs: $_paragraphs'),
          Slider(
            value: _paragraphs.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_paragraphs',
            onChanged: (v) => setState(() => _paragraphs = v.round()),
          ),
          FilledButton(onPressed: _generate, child: const Text('Generate')),
          const SizedBox(height: 12),
          SelectableText(_result),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ToolScaffold.copy(_result),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
