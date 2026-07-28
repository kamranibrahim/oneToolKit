import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../app/routes/app_pages.dart';
import '../app/theme/app_colors.dart';
import '../data/models/tool_model.dart';
import '../data/services/favorites_service.dart';

class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.tool,
    this.compact = false,
  });

  final ToolModel tool;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final favorites = Get.find<FavoritesService>();
    final theme = Theme.of(context);
    final accent = tool.category.accent;

    return Obx(() {
      final isFav = favorites.isFavorite(tool.id);
      return Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpace.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpace.radius),
          onTap: () => openTool(tool),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showActions(context, tool, isFav);
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpace.radius),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.7),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 14),
              child: Row(
                children: [
                  Container(
                    width: compact ? 44 : 48,
                    height: compact ? 44 : 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpace.radiusSm),
                    ),
                    child: Icon(tool.icon, color: accent, size: compact ? 22 : 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tool.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!tool.isAvailable)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Soon',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 3),
                          Text(
                            tool.description,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => toggleFavorite(tool),
                    icon: Icon(
                      isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFav ? const Color(0xFFEAB308) : theme.iconTheme.color,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showActions(BuildContext context, ToolModel tool, bool isFav) {
    final favorites = Get.find<FavoritesService>();
    final isPinned = favorites.isPinned(tool.id);

    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
                title: Text(isFav ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () {
                  toggleFavorite(tool);
                  Get.back();
                },
              ),
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                ),
                title: Text(isPinned ? 'Unpin from Home' : 'Pin to Home'),
                onTap: () {
                  favorites.togglePin(tool.id);
                  Get.back();
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('Open'),
                onTap: () {
                  Get.back();
                  openTool(tool);
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }
}

/// Canva-style discovery tile for Popular tools.
class PopularToolTile extends StatelessWidget {
  const PopularToolTile({super.key, required this.tool});

  final ToolModel tool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tool.category.accent;

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpace.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpace.radius),
        onTap: () => openTool(tool),
        child: Ink(
          width: 148,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpace.radius),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpace.radiusSm),
                ),
                child: Icon(tool.icon, color: accent, size: 22),
              ),
              const Spacer(),
              Text(
                tool.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                tool.category.label,
                style: theme.textTheme.labelSmall,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal chip for Favorites / Recent (Apple Files vibe).
class ToolChip extends StatelessWidget {
  const ToolChip({super.key, required this.tool});

  final ToolModel tool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tool.category.accent;

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpace.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpace.radius),
        onTap: () => openTool(tool),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpace.radius),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tool.icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                tool.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
