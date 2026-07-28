import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/store_copy.dart';
import '../../data/catalog/tool_catalog.dart';
import '../../data/services/favorites_service.dart';
import '../../data/services/history_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/widget_sync_service.dart';
import 'settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = ToolCatalog.available.length;
    final total = ToolCatalog.all.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  return SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_rounded, size: 18),
                      ),
                    ],
                    selected: {controller.themeMode.value},
                    onSelectionChanged: (s) => controller.setThemeMode(s.first),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.widgets_outlined),
                  title: const Text('Home screen widget'),
                  subtitle: Text(
                    Platform.isIOS
                        ? 'Sync favorites to iOS WidgetKit'
                        : 'Sync favorites to Android widget',
                  ),
                  onTap: () async {
                    await Get.find<WidgetSyncService>().syncFavorites();
                    Get.snackbar(
                      'Widget updated',
                      Platform.isIOS
                          ? 'Long-press the Home Screen → Widgets → OneToolkit Favorites.'
                          : 'Add “OneToolkit Favorites” from your home screen widgets.',
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: const Text('Replay intro'),
                  subtitle: const Text('Show the first-run tips again'),
                  onTap: () => Get.toNamed(AppRoutes.onboarding),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Clear local data'),
                  subtitle: const Text(
                    'Favorites, history, recent tools, and notepad',
                  ),
                  onTap: () => _confirmClear(context),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy'),
                  subtitle: const Text('What stays on your device'),
                  onTap: () => _showInfo(
                    'Privacy',
                    StoreCopy.privacySummary,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Store listing'),
                  subtitle: const Text('Copy App Store / Play description'),
                  onTap: () => _showStoreListing(context),
                ),
                const Divider(height: 1),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '1.0.0';
                    final build = snapshot.data?.buildNumber ?? '';
                    final label = build.isEmpty ? version : '$version+$build';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('About'),
                      subtitle:
                          Text('$available of $total tools available · v$label'),
                      onTap: () => _showInfo(
                        AppConstants.appName,
                        '${StoreCopy.subtitle}\n\n'
                        '${StoreCopy.promotionalText}\n\n'
                        'Version $label',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Free forever · No forced sign-up · Offline-first',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text(
          'This removes favorites, history, recent tools, and notepad notes '
          'from this device. Your files in Photos/Files are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Get.find<FavoritesService>().clearFavorites();
    final history = Get.find<HistoryService>();
    await history.clearHistory();
    await history.clearRecentTools();
    await history.clearRecentSearches();
    await Get.find<StorageService>().remove(AppConstants.keyNotes);
    Get.snackbar(
      'Cleared',
      'Local preferences were reset.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void _showInfo(String title, String body) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('OK')),
        ],
      ),
    );
  }

  void _showStoreListing(BuildContext context) {
    final text = [
      StoreCopy.name,
      StoreCopy.subtitle,
      '',
      StoreCopy.promotionalText,
      '',
      StoreCopy.description.trim(),
      '',
      'Keywords: ${StoreCopy.keywords}',
    ].join('\n');

    Get.dialog(
      AlertDialog(
        title: const Text('Store listing'),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Get.back();
              Get.snackbar(
                'Copied',
                'Store listing copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
              );
            },
            child: const Text('Copy all'),
          ),
          TextButton(onPressed: Get.back, child: const Text('Close')),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
