import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_pages.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/catalog/tool_catalog.dart';
import '../../data/models/tool_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/tool_card.dart';
import '../shell/shell_controller.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppConstants.appName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const OfflineBadge(),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    const _SearchField(),
                  ],
                ),
              ),
            ),
            Obx(() {
              controller.favorites.favorites.length;
              controller.favorites.pinned.length;
              controller.history.recentToolIds.length;
              controller.history.history.length;

              final favs = controller.favoriteTools;
              final recent = controller.recent;
              final actions = controller.recentActions;

              return ContainedSliverList(
                children: [
                  if (favs.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Favorites',
                      actionLabel: 'See all',
                      onAction: () => Get.find<ShellController>().changeTab(2),
                    ),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: favs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, i) => ToolChip(tool: favs[i]),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                  ],
                  if (recent.isNotEmpty) ...[
                    const SectionHeader(title: 'Recent'),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recent.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, i) => ToolChip(tool: recent[i]),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                  ],
                  SectionHeader(
                    title: 'Tools',
                    actionLabel: 'Browse',
                    onAction: () => Get.find<ShellController>().changeTab(1),
                  ),
                  _CategoryGrid(categories: controller.categories),
                  const SizedBox(height: AppSpace.sm),
                  const SectionHeader(title: 'Popular'),
                  SizedBox(
                    height: 148,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.popular.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          PopularToolTile(tool: controller.popular[i]),
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.sm),
                    const SectionHeader(title: 'Recent activity'),
                    ...actions.map((item) {
                      final tool = ToolCatalog.byId(item.toolId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(AppSpace.radius),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppSpace.radius),
                            onTap: tool == null ? null : () => openTool(tool),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppSpace.radius),
                                border: Border.all(
                                  color: theme.dividerColor.withValues(alpha: 0.7),
                                ),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(
                                    tool?.icon ?? Icons.history_rounded,
                                    color: tool?.category.accent ??
                                        theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.toolName,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          item.detail == null
                                              ? item.action
                                              : '${item.action} · ${item.detail}',
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: theme.iconTheme.color
                                        ?.withValues(alpha: 0.35),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: AppSpace.lg),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Pads list children like a Files content column.
class ContainedSliverList extends StatelessWidget {
  const ContainedSliverList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      sliver: SliverList(delegate: SliverChildListDelegate(children)),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpace.radiusLg),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.search),
        borderRadius: BorderRadius.circular(AppSpace.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpace.radiusLg),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.8)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 22,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search everything',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<ToolCategory> categories;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) => _CategoryTile(category: categories[index]),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final ToolCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available =
        ToolCatalog.byCategory(category).where((t) => t.isAvailable).length;

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpace.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpace.radius),
        onTap: () => Get.toNamed(AppRoutes.categoryDetail, arguments: category),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpace.radius),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: category.accent, size: 22),
              ),
              const Spacer(),
              Text(
                category.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$available tools',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
