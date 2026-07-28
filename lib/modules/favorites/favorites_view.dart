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
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Obx(() {
        controller.favorites.favorites.length;
        final tools = controller.tools;
        if (tools.isEmpty) {
          return const EmptyState(
            icon: Icons.star_outline_rounded,
            title: 'No favorites yet',
            message:
                'Star tools you use often. They show up here and on Home for one-tap access.',
          );
        }
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          itemCount: tools.length,
          onReorder: controller.reorder,
          proxyDecorator: (child, index, animation) {
            return Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(AppSpace.radius),
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final tool = tools[index];
            return Padding(
              key: ValueKey(tool.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: ToolCard(tool: tool),
            );
          },
        );
      }),
    );
  }
}
