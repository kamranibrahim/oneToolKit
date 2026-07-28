import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tool_card.dart';
import 'favorites_controller.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Obx(() {
        controller.favorites.favorites.length;
        final tools = controller.tools;
        if (tools.isEmpty) {
          return const EmptyState(
            icon: Icons.star_outline_rounded,
            title: 'No Favorites',
            message: 'Star tools you use often for quick access.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Material(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppSpace.radius),
              clipBehavior: Clip.antiAlias,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tools.length,
                onReorder: controller.reorder,
                buildDefaultDragHandles: true,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 2,
                    color: theme.cardTheme.color,
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  return Column(
                    key: ValueKey(tool.id),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0) const Divider(height: 0.5, indent: 58),
                      ToolCard(tool: tool, compact: true),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
