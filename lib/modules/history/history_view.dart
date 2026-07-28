import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/routes/app_pages.dart';
import '../../app/theme/app_colors.dart';
import '../../data/catalog/tool_catalog.dart';
import '../../widgets/empty_state.dart';
import 'history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d · HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: controller.clearAll,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      body: Obx(() {
        final items = controller.historyService.history;
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No History',
            message: 'Finished actions will appear here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Material(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppSpace.radius),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const Divider(height: 0.5, indent: 56),
                    Dismissible(
                      key: ValueKey(items[i].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: theme.colorScheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) =>
                          controller.historyService.deleteItem(items[i].id),
                      child: Builder(
                        builder: (context) {
                          final item = items[i];
                          final tool = ToolCatalog.byId(item.toolId);
                          return InkWell(
                            onTap: tool == null ? null : () => openTool(tool),
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
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.toolName,
                                          style: theme.textTheme.titleSmall,
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
                                  Text(
                                    fmt.format(item.timestamp),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
