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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 10 : 12,
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 40 : 44,
                  height: compact ? 40 : 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpace.radiusSm),
                  ),
                  child: Icon(tool.icon, color: accent, size: compact ? 20 : 22),
                ),
                const SizedBox(width: 12),
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
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!tool.isAvailable)
                            Text(
                              'Soon',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 2),
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
                    color: isFav
                        ? const Color(0xFFFFCC00)
                        : theme.textTheme.bodySmall?.color,
                    size: 22,
                  ),
                ),
              ],
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
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              ListTile(
                leading: Icon(
                  isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
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
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(isPinned ? 'Unpin from Home' : 'Pin to Home'),
                onTap: () {
                  favorites.togglePin(tool.id);
                  Get.back();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.open_in_new_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
    );
  }
}

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
        child: SizedBox(
          width: 132,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
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
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(tool.category.label, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(tool.icon, color: accent, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                tool.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
