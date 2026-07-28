import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../app/routes/app_pages.dart';
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openTool(tool),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showActions(context, tool, isFav);
          },
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Row(
              children: [
                Container(
                  width: compact ? 40 : 46,
                  height: compact ? 40 : 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
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
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!tool.isAvailable)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
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
                        const SizedBox(height: 2),
                        Text(
                          tool.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
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
                    color: isFav ? Colors.amber.shade600 : null,
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}
