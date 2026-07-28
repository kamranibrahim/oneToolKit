import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';

import '../catalog/tool_catalog.dart';
import 'favorites_service.dart';

/// Syncs favorite tools to the Android home-screen widget.
class WidgetSyncService extends GetxService {
  static const androidName = 'FavoritesWidgetProvider';
  static const iOSName = 'FavoritesWidget';

  Future<WidgetSyncService> init() async {
    try {
      await HomeWidget.setAppGroupId('group.com.onetoolkit.one_toolkit');
    } catch (_) {
      // App group is iOS-only; ignore on Android / unsupported.
    }
    return this;
  }

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
            'com.onetoolkit.one_toolkit.FavoritesWidgetProvider',
      );
    } catch (_) {
      // Widget APIs are best-effort (missing native targets, desktop, etc.).
    }
  }
}
