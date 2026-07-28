import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../catalog/tool_catalog.dart';
import '../models/history_item.dart';
import '../models/tool_model.dart';
import 'storage_service.dart';

class HistoryService extends GetxService {
  HistoryService(this._storage);

  final StorageService _storage;
  final _uuid = const Uuid();

  final recentToolIds = <String>[].obs;
  final history = <HistoryItem>[].obs;
  final recentSearches = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    recentToolIds.assignAll(_storage.readStringList(AppConstants.keyRecentTools));
    recentSearches.assignAll(_storage.readStringList(AppConstants.keyRecentSearches));

    final raw = _storage.read(AppConstants.keyHistory);
    if (raw is List) {
      history.assignAll(
        raw
            .whereType<Map>()
            .map((e) => HistoryItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
  }

  List<ToolModel> recentTools({int limit = 8}) => recentToolIds
      .map(ToolCatalog.byId)
      .whereType<ToolModel>()
      .take(limit)
      .toList();

  Future<void> recordToolOpen(String toolId) async {
    recentToolIds.remove(toolId);
    recentToolIds.insert(0, toolId);
    if (recentToolIds.length > 20) {
      recentToolIds.removeRange(20, recentToolIds.length);
    }
    await _storage.writeStringList(
      AppConstants.keyRecentTools,
      recentToolIds.toList(),
    );
  }

  Future<void> addAction({
    required String toolId,
    required String toolName,
    required String action,
    String? detail,
  }) async {
    history.insert(
      0,
      HistoryItem(
        id: _uuid.v4(),
        toolId: toolId,
        toolName: toolName,
        action: action,
        timestamp: DateTime.now(),
        detail: detail,
      ),
    );
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    await _persistHistory();
  }

  Future<void> addSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    recentSearches.remove(q);
    recentSearches.insert(0, q);
    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }
    await _storage.writeStringList(
      AppConstants.keyRecentSearches,
      recentSearches.toList(),
    );
  }

  Future<void> deleteItem(String id) async {
    history.removeWhere((e) => e.id == id);
    await _persistHistory();
  }

  Future<void> clearHistory() async {
    history.clear();
    await _persistHistory();
  }

  Future<void> clearRecentTools() async {
    recentToolIds.clear();
    await _storage.writeStringList(AppConstants.keyRecentTools, []);
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    await _storage.writeStringList(AppConstants.keyRecentSearches, []);
  }

  Future<void> _persistHistory() async {
    await _storage.write(
      AppConstants.keyHistory,
      history.map((e) => e.toJson()).toList(),
    );
  }
}
