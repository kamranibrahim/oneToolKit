import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/tool_model.dart';

class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tool = Get.arguments is ToolModel ? Get.arguments as ToolModel : null;
    final name = tool?.name ?? 'This tool';
    final accent = tool?.category.accent ?? theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(tool?.name ?? 'Coming Soon')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  tool?.icon ?? Icons.construction_rounded,
                  size: 36,
                  color: accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Coming soon',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$name is on the roadmap. Star it so it’s ready when we ship.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              if (tool != null)
                FilledButton.tonal(
                  onPressed: () => Get.back(),
                  child: const Text('Back to tools'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
