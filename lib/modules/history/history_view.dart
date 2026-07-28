import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/routes/app_pages.dart';
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
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Obx(() {
        final items = controller.historyService.history;
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No history yet',
            message: 'Completed tool actions will show up here so you can reopen them quickly.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            final tool = ToolCatalog.byId(item.toolId);
            return Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.white),
              ),
              onDismissed: (_) =>
                  controller.historyService.deleteItem(item.id),
              child: Material(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: tool == null ? null : () => openTool(tool),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          tool?.icon ?? Icons.history_rounded,
                          color: tool?.category.accent ?? theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.toolName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                item.detail == null
                                    ? item.action
                                    : '${item.action} · ${item.detail}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.65),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          fmt.format(item.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
