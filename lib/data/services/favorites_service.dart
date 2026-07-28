import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../catalog/tool_catalog.dart';
import '../models/tool_model.dart';
import 'storage_service.dart';
import 'widget_sync_service.dart';

class FavoritesService extends GetxService {
  FavoritesService(this._storage);

  final StorageService _storage;

  final favorites = <String>[].obs;
  final pinned = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    favorites.assignAll(_storage.readStringList(AppConstants.keyFavorites));
    pinned.assignAll(_storage.readStringList(AppConstants.keyPinned));
  }

  bool isFavorite(String toolId) => favorites.contains(toolId);

  bool isPinned(String toolId) => pinned.contains(toolId);

  Future<void> toggleFavorite(String toolId) async {
    if (favorites.contains(toolId)) {
      favorites.remove(toolId);
      pinned.remove(toolId);
    } else {
      favorites.add(toolId);
    }
    await _persist();
  }

  Future<void> togglePin(String toolId) async {
    if (pinned.contains(toolId)) {
      pinned.remove(toolId);
    } else {
      if (!favorites.contains(toolId)) favorites.add(toolId);
      pinned.add(toolId);
    }
    await _persist();
  }

  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = favorites.removeAt(oldIndex);
    favorites.insert(newIndex, item);
    await _persist();
  }

  List<ToolModel> favoriteTools() => favorites
      .map(ToolCatalog.byId)
      .whereType<ToolModel>()
      .toList();

  List<ToolModel> pinnedTools() => pinned
      .map(ToolCatalog.byId)
      .whereType<ToolModel>()
      .toList();

  Future<void> clearFavorites() async {
    favorites.clear();
    pinned.clear();
    await _persist();
  }

  Future<void> _persist() async {
    await _storage.writeStringList(AppConstants.keyFavorites, favorites.toList());
    await _storage.writeStringList(AppConstants.keyPinned, pinned.toList());
    if (Get.isRegistered<WidgetSyncService>()) {
      await Get.find<WidgetSyncService>().syncFavorites();
    }
  }
}
