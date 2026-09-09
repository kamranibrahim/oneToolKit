import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/catalog/tool_catalog.dart';

Future<void> showShareTargetSheet({
  required List<String> ids,
  required void Function(String toolId) onPick,
}) {
  final theme = Get.theme;
  return Get.bottomSheet<void>(
    ShareTargetSheet(ids: ids, onPick: onPick),
    backgroundColor: theme.cardTheme.color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpace.radiusLg),
      ),
    ),
    isScrollControlled: true,
  );
}

class ShareTargetSheet extends StatelessWidget {
  const ShareTargetSheet({
    super.key,
    required this.ids,
    required this.onPick,
  });

  final List<String> ids;
  final void Function(String toolId) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('Open with', style: theme.textTheme.titleMedium),
            ),
            for (final id in ids)
              Builder(
                builder: (context) {
                  final tool = ToolCatalog.byId(id);
                  if (tool == null) return const SizedBox.shrink();
                  return ListTile(
                    leading: Icon(tool.icon, color: tool.category.accent),
                    title: Text(tool.name),
                    subtitle: Text(
                      tool.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Get.back();
                      onPick(id);
                    },
                  );
                },
              ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
