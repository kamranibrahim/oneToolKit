import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../data/catalog/tool_catalog.dart';
import 'categories_controller.dart';

class CategoriesView extends GetView<CategoriesController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => Get.toNamed(AppRoutes.search),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: controller.categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cat = controller.categories[index];
          final tools = ToolCatalog.byCategory(cat);
          final available = tools.where((t) => t.isAvailable).length;

          return Material(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppSpace.radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpace.radius),
              onTap: () =>
                  Get.toNamed(AppRoutes.categoryDetail, arguments: cat),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpace.radius),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.7),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: cat.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(cat.icon, color: cat.accent, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.subtitle,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$available available',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cat.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.iconTheme.color?.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
