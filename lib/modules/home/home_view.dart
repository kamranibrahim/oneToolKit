import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/tool_model.dart';
import '../../widgets/section_header.dart';
import '../../widgets/tool_card.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.tertiary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.handyman_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.appName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                AppConstants.appTagline,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SearchField(
                      onTap: () => Get.toNamed(AppRoutes.search),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  const SectionHeader(title: 'Categories'),
                  _CategoryGrid(categories: controller.categories),
                  Obx(() {
                    // Observe favorites/history for reactivity
                    controller.favorites.pinned.length;
                    controller.history.recentToolIds.length;
                    final pinned = controller.pinned;
                    if (pinned.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Pinned'),
                        ...pinned.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ToolCard(tool: t, compact: true),
                            )),
                      ],
                    );
                  }),
                  Obx(() {
                    controller.history.recentToolIds.length;
                    final recent = controller.recent;
                    if (recent.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Recent'),
                        ...recent.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ToolCard(tool: t, compact: true),
                            )),
                      ],
                    );
                  }),
                  const SectionHeader(title: 'Recommended'),
                  ...controller.recommended.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ToolCard(tool: t),
                      )),
                  const SectionHeader(title: 'Trending'),
                  ...controller.trending.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ToolCard(tool: t),
                      )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Text(
                'Search tools…',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _CategoryTile(category: cat);
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final ToolCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(AppRoutes.categoryDetail, arguments: category),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.icon, color: category.accent, size: 20),
              ),
              const Spacer(),
              Text(
                category.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                category.subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
