import 'package:flutter/cupertino.dart';
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
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const OfflineBadge(),
                    const SizedBox(height: 16),
                    const _IosSearchField(),
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

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: ContainedSliverList(
                  children: [
                    if (favs.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Favorites',
                        actionLabel: 'See All',
                        onAction: () =>
                            Get.find<ShellController>().changeTab(2),
                      ),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: favs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) => ToolChip(tool: favs[i]),
                        ),
                      ),
                    ],
                    if (recent.isNotEmpty) ...[
                      const SectionHeader(title: 'Recents'),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recent.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) =>
                              ToolChip(tool: recent[i]),
                        ),
                      ),
                    ],
                    SectionHeader(
                      title: 'Browse',
                      actionLabel: 'See All',
                      onAction: () => Get.find<ShellController>().changeTab(1),
                    ),
                    _CategoryGrid(categories: controller.categories),
                    const SectionHeader(title: 'Popular'),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.popular.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, i) =>
                            PopularToolTile(tool: controller.popular[i]),
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SectionHeader(title: 'Recent Activity'),
                      Material(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(AppSpace.radius),
                        child: Column(
                          children: [
                            for (var i = 0; i < actions.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 0.5,
                                  indent: 58,
                                  color: theme.dividerColor,
                                ),
                              Builder(
                                builder: (context) {
                                  final item = actions[i];
                                  final tool = ToolCatalog.byId(item.toolId);
                                  return InkWell(
                                    onTap:
                                        tool == null ? null : () => openTool(tool),
                                    borderRadius: BorderRadius.vertical(
                                      top: i == 0
                                          ? const Radius.circular(AppSpace.radius)
                                          : Radius.zero,
                                      bottom: i == actions.length - 1
                                          ? const Radius.circular(AppSpace.radius)
                                          : Radius.zero,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            tool?.icon ?? Icons.history_rounded,
                                            color: tool?.category.accent ??
                                                theme.colorScheme.primary,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.toolName,
                                                  style: theme
                                                      .textTheme.titleSmall,
                                                ),
                                                Text(
                                                  item.detail == null
                                                      ? item.action
                                                      : '${item.action} · ${item.detail}',
                                                  style:
                                                      theme.textTheme.bodySmall,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: theme
                                                .textTheme.bodySmall?.color,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ContainedSliverList extends StatelessWidget {
  const ContainedSliverList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SliverList(delegate: SliverChildListDelegate(children));
  }
}

class _IosSearchField extends StatelessWidget {
  const _IosSearchField();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.brightness == Brightness.dark
        ? AppColors.fillDark
        : AppColors.fillLight;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.search),
      child: AbsorbPointer(
        child: CupertinoSearchTextField(
          placeholder: 'Search',
          backgroundColor: fill,
          borderRadius: BorderRadius.circular(12),
          style: theme.textTheme.bodyLarge,
          placeholderStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodySmall?.color,
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) =>
          _CategoryTile(category: categories[index]),
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(category.icon, color: category.accent, size: 28),
              const Spacer(),
              Text(
                category.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
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
