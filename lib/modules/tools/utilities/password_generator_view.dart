import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class PasswordGeneratorView extends StatefulWidget {
  const PasswordGeneratorView({super.key});

  @override
  State<PasswordGeneratorView> createState() => _PasswordGeneratorViewState();
}

class _PasswordGeneratorViewState extends State<PasswordGeneratorView> {
  static const _lower = 'abcdefghijkmnopqrstuvwxyz';
  static const _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const _digits = '23456789';
  static const _symbols = r'!@#$%^&*()-_=+[]{};:,.?';

  final _random = Random.secure();
  int _length = 16;
  bool _useLower = true;
  bool _useUpper = true;
  bool _useDigits = true;
  bool _useSymbols = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    var pool = '';
    final required = <String>[];
    if (_useLower) {
      pool += _lower;
      required.add(_lower[_random.nextInt(_lower.length)]);
    }
    if (_useUpper) {
      pool += _upper;
      required.add(_upper[_random.nextInt(_upper.length)]);
    }
    if (_useDigits) {
      pool += _digits;
      required.add(_digits[_random.nextInt(_digits.length)]);
    }
    if (_useSymbols) {
      pool += _symbols;
      required.add(_symbols[_random.nextInt(_symbols.length)]);
    }
    if (pool.isEmpty) {
      setState(() => _password = '');
      return;
    }

    final chars = List<String>.from(required);
    while (chars.length < _length) {
      chars.add(pool[_random.nextInt(pool.length)]);
    }
    chars.shuffle(_random);
    setState(() => _password = chars.join());
  }

  double get _strength {
    if (_password.isEmpty) return 0;
    var score = 0.0;
    score += (_length / 32).clamp(0, 0.4);
    if (_useLower) score += 0.15;
    if (_useUpper) score += 0.15;
    if (_useDigits) score += 0.15;
    if (_useSymbols) score += 0.15;
    return score.clamp(0, 1);
  }

  String get _strengthLabel {
    final s = _strength;
    if (s < 0.35) return 'Weak';
    if (s < 0.6) return 'Fair';
    if (s < 0.8) return 'Strong';
    return 'Very strong';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'password_generator',
      title: 'Password Generator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Cryptographically secure passwords, generated on device. Nothing is stored.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              _password.isEmpty ? 'Select at least one character set' : _password,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Strength · $_strengthLabel'),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: _strength),
          const SizedBox(height: 16),
          Text('Length $_length'),
          Slider(
            value: _length.toDouble(),
            min: 8,
            max: 64,
            divisions: 56,
            onChanged: (v) => setState(() {
              _length = v.round();
              _generate();
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lowercase'),
            value: _useLower,
            onChanged: (v) => setState(() {
              _useLower = v;
              _generate();
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Uppercase'),
            value: _useUpper,
            onChanged: (v) => setState(() {
              _useUpper = v;
              _generate();
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Digits'),
            value: _useDigits,
            onChanged: (v) => setState(() {
              _useDigits = v;
              _generate();
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Symbols'),
            value: _useSymbols,
            onChanged: (v) => setState(() {
              _useSymbols = v;
              _generate();
            }),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              _generate();
              ToolScaffold.logAction(
                toolId: 'password_generator',
                toolName: 'Password Generator',
                action: 'Generated',
                detail: '$_length chars',
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Generate'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _password.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _password));
                    ToolScaffold.copy(_password, message: 'Password copied');
                  },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
