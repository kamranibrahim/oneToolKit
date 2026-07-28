import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class RandomGeneratorView extends StatefulWidget {
  const RandomGeneratorView({super.key});

  @override
  State<RandomGeneratorView> createState() => _RandomGeneratorViewState();
}

class _RandomGeneratorViewState extends State<RandomGeneratorView> {
  final _random = Random.secure();
  int _mode = 0; // 0 int, 1 dice, 2 pick, 3 string
  final _min = TextEditingController(text: '1');
  final _max = TextEditingController(text: '100');
  int _diceSides = 6;
  int _diceCount = 2;
  final _list = TextEditingController(text: 'Alice\nBob\nCharlie\nDana');
  int _stringLength = 12;
  bool _letters = true;
  bool _digits = true;
  String _result = '';

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _list.dispose();
    super.dispose();
  }

  void _generate() {
    setState(() {
      switch (_mode) {
        case 0:
          final lo = int.tryParse(_min.text.trim()) ?? 0;
          final hi = int.tryParse(_max.text.trim()) ?? lo;
          final a = lo <= hi ? lo : hi;
          final b = lo <= hi ? hi : lo;
          _result = (a + _random.nextInt(b - a + 1)).toString();
        case 1:
          final rolls = List.generate(
            _diceCount,
            (_) => 1 + _random.nextInt(_diceSides),
          );
          final sum = rolls.fold<int>(0, (s, v) => s + v);
          _result = '${rolls.join(' + ')} = $sum';
        case 2:
          final items = _list.text
              .split(RegExp(r'[\n,]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          _result = items.isEmpty
              ? 'Add at least one item'
              : items[_random.nextInt(items.length)];
        case 3:
          var pool = '';
          if (_letters) pool += 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
          if (_digits) pool += '0123456789';
          if (pool.isEmpty) {
            _result = 'Select letters and/or digits';
            return;
          }
          _result = List.generate(
            _stringLength,
            (_) => pool[_random.nextInt(pool.length)],
          ).join();
      }
    });
    ToolScaffold.logAction(
      toolId: 'random_generator',
      toolName: 'Random Generator',
      action: 'Generated',
      detail: switch (_mode) {
        0 => 'integer',
        1 => 'dice',
        2 => 'pick',
        _ => 'string',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'random_generator',
      title: 'Random Generator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Secure random integers, dice rolls, list picks, and strings.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Int')),
              ButtonSegment(value: 1, label: Text('Dice')),
              ButtonSegment(value: 2, label: Text('Pick')),
              ButtonSegment(value: 3, label: Text('Text')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          if (_mode == 0) ...[
            TextField(
              controller: _min,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Min'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _max,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max'),
            ),
          ],
          if (_mode == 1) ...[
            Text('Dice $_diceCount × D$_diceSides'),
            Slider(
              value: _diceCount.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_diceCount',
              onChanged: (v) => setState(() => _diceCount = v.round()),
            ),
            Wrap(
              spacing: 8,
              children: [4, 6, 8, 10, 12, 20]
                  .map(
                    (s) => ChoiceChip(
                      label: Text('D$s'),
                      selected: _diceSides == s,
                      onSelected: (_) => setState(() => _diceSides = s),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (_mode == 2)
            TextField(
              controller: _list,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Items (one per line)',
              ),
            ),
          if (_mode == 3) ...[
            Text('Length $_stringLength'),
            Slider(
              value: _stringLength.toDouble(),
              min: 4,
              max: 64,
              divisions: 60,
              onChanged: (v) => setState(() => _stringLength = v.round()),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Letters'),
              value: _letters,
              onChanged: (v) => setState(() => _letters = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Digits'),
              value: _digits,
              onChanged: (v) => setState(() => _digits = v),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.casino_rounded),
            label: const Text('Generate'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 16),
            SelectableText(_result, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _result));
                ToolScaffold.copy(_result, message: 'Copied');
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
