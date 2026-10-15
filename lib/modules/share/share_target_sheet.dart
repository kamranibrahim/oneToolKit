import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/catalog/tool_catalog.dart';
import '../../data/models/shared_file.dart';
import '../../core/utils/share_router.dart';

Future<void> showShareTargetSheet({
  required List<String> ids,
  required List<SharedFile> files,
  required VoidCallback onDiscard,
  required void Function(String toolId) onPick,
}) {
  final theme = Get.theme;
  return Get.bottomSheet<void>(
    ShareTargetSheet(
      ids: ids,
      files: files,
      onPick: onPick,
      onDiscard: onDiscard,
    ),
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
    required this.files,
    required this.onDiscard,
    required this.onPick,
  });

  final List<String> ids;
  final List<SharedFile> files;
  final VoidCallback onDiscard;
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
              child: Text(
                '${files.length} shared file(s)',
                style: theme.textTheme.titleMedium,
              ),
            ),
            for (final id in ids)
              Builder(
                builder: (context) {
                  final tool = ToolCatalog.byId(id);
                  if (tool == null) return const SizedBox.shrink();
                  final matching = files
                      .where((f) => acceptsSharedMime(id, f.mime))
                      .length;
                  final count = matching.clamp(0, sharedInputLimit(id));
                  return ListTile(
                    leading: Icon(tool.icon, color: tool.category.accent),
                    title: Text(tool.name),
                    subtitle: Text(
                      'Uses $count file(s)${count < files.length ? ' · ${files.length - count} kept for later' : ''}',
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
            if (ids.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'These files are not supported. You can discard them from this queue.',
                ),
              ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Keep for later'),
            ),
            TextButton(
              onPressed: () {
                onDiscard();
                Get.back();
              },
              child: const Text('Discard shared files'),
            ),
          ],
        ),
      ),
    );
  }
}
