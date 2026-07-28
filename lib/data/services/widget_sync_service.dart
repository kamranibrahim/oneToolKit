import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';

import '../catalog/tool_catalog.dart';
import '../../app/routes/app_pages.dart';
import 'favorites_service.dart';

/// Syncs favorite tools to home-screen widgets and handles deep links.
class WidgetSyncService extends GetxService {
  static const androidName = 'FavoritesWidgetProvider';
  static const iOSName = 'FavoritesWidget';
  static const scheme = 'onetoolkit';

  Future<WidgetSyncService> init() async {
    try {
      await HomeWidget.setAppGroupId('group.com.kamranibrahim.onetoolkit');
    } catch (_) {
      // App group is iOS-only; ignore on Android / unsupported.
    }
    return this;
  }

  /// Call after GetMaterialApp is ready.
  Future<void> bindLaunchHandlers() async {
    try {
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initial != null) {
        _openFromUri(initial);
      }
      HomeWidget.widgetClicked.listen(_openFromUri);
    } catch (_) {}
  }

  void _openFromUri(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme != scheme) return;
    if (uri.host != 'tool') return;
    final toolId = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.first
        : (uri.path.isNotEmpty ? uri.path.replaceFirst('/', '') : '');
    if (toolId.isEmpty) return;
    final tool = ToolCatalog.byId(toolId);
    if (tool == null) return;
    // Defer until navigation stack exists.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      openTool(tool);
    });
  }

  static Uri toolUri(String toolId) => Uri(
        scheme: scheme,
        host: 'tool',
        path: '/$toolId',
      );

  Future<void> syncFavorites() async {
    try {
      final favorites = Get.find<FavoritesService>();
      final ids = favorites.favorites.take(4).toList();
      final names = <String>[];
      for (final id in ids) {
        final tool = ToolCatalog.byId(id);
        if (tool != null) names.add(tool.name);
      }
      while (names.length < 4) {
        names.add('');
      }

      await HomeWidget.saveWidgetData<String>('title', 'OneToolkit');
      await HomeWidget.saveWidgetData<String>('subtitle', 'Favorites');
      for (var i = 0; i < 4; i++) {
        await HomeWidget.saveWidgetData<String>('tool_$i', names[i]);
        await HomeWidget.saveWidgetData<String>(
          'tool_id_$i',
          i < ids.length ? ids[i] : '',
        );
      }
      await HomeWidget.saveWidgetData<int>('tool_count', ids.length);
      await HomeWidget.updateWidget(
        name: androidName,
        iOSName: iOSName,
        qualifiedAndroidName:
            'com.kamranibrahim.onetoolkit.FavoritesWidgetProvider',
      );
    } catch (_) {
      // Widget APIs are best-effort (missing native targets, desktop, etc.).
    }
  }
}
