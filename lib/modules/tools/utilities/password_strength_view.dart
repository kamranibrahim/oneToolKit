import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class PasswordStrengthView extends StatefulWidget {
  const PasswordStrengthView({super.key});

  @override
  State<PasswordStrengthView> createState() => _PasswordStrengthViewState();
}

class _PasswordStrengthViewState extends State<PasswordStrengthView> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _Score get _score {
    final p = _controller.text;
    if (p.isEmpty) {
      return const _Score(0, 'Enter a password', Colors.grey, []);
    }

    var score = 0;
    final tips = <String>[];

    if (p.length >= 8) {
      score += 1;
    } else {
      tips.add('Use at least 8 characters');
    }
    if (p.length >= 12) score += 1;
    if (p.length >= 16) score += 1;

    if (RegExp(r'[a-z]').hasMatch(p)) {
      score += 1;
    } else {
      tips.add('Add lowercase letters');
    }
    if (RegExp(r'[A-Z]').hasMatch(p)) {
      score += 1;
    } else {
      tips.add('Add uppercase letters');
    }
    if (RegExp(r'[0-9]').hasMatch(p)) {
      score += 1;
    } else {
      tips.add('Add numbers');
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) {
      score += 1;
    } else {
      tips.add('Add symbols');
    }

    // Penalize common patterns lightly in tips only
    if (RegExp(r'(.)\1{2,}').hasMatch(p)) {
      tips.add('Avoid repeated characters');
      score = (score - 1).clamp(0, 8);
    }
    if (RegExp(
      r'(012|123|234|345|456|567|678|789|abc|qwerty|password)',
      caseSensitive: false,
    ).hasMatch(p)) {
      tips.add('Avoid common sequences');
      score = (score - 1).clamp(0, 8);
    }

    final label = switch (score) {
      <= 2 => 'Very weak',
      3 || 4 => 'Weak',
      5 => 'Fair',
      6 => 'Strong',
      _ => 'Very strong',
    };
    final color = switch (score) {
      <= 2 => const Color(0xFFDC2626),
      3 || 4 => const Color(0xFFEA580C),
      5 => const Color(0xFFD97706),
      6 => const Color(0xFF65A30D),
      _ => const Color(0xFF16A34A),
    };

    if (tips.isEmpty) tips.add('Looks solid for most uses');
    return _Score(score.clamp(0, 8) / 8, label, color, tips);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = _score;
    return ToolScaffold(
      toolId: 'password_strength',
      title: 'Password Strength',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            obscureText: _obscure,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(score.label, style: theme.textTheme.titleLarge?.copyWith(
            color: score.color,
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score.value,
              minHeight: 10,
              color: score.color,
              backgroundColor: score.color.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_controller.text.length} characters',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Text('Suggestions', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final tip in score.tips)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                Icons.check_circle_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              title: Text(tip),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _controller.text.isEmpty
                ? null
                : () {
                    ToolScaffold.logAction(
                      toolId: 'password_strength',
                      toolName: 'Password Strength',
                      action: 'Checked',
                      detail: score.label,
                    );
                  },
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Log check'),
          ),
        ],
      ),
    );
  }
}

class _Score {
  const _Score(this.value, this.label, this.color, this.tips);
  final double value;
  final String label;
  final Color color;
  final List<String> tips;
}
