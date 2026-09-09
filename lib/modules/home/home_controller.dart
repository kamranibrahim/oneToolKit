import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/popular_ranker.dart';
import '../../data/catalog/tool_catalog.dart';
import '../../data/models/history_item.dart';
import '../../data/models/tool_model.dart';
import '../../data/services/favorites_service.dart';
import '../../data/services/history_service.dart';
import '../../data/services/storage_service.dart';

class HomeController extends GetxController {
  final favorites = Get.find<FavoritesService>();
  final history = Get.find<HistoryService>();

  List<ToolModel> get favoriteTools {
    final pinned = favorites.pinnedTools();
    if (pinned.isNotEmpty) return pinned;
    return favorites.favoriteTools();
  }

  List<ToolModel> get recent => history.recentTools(limit: 10);

  List<ToolModel> get popular {
    final fallback = <ToolModel>[];
    final seen = <String>{};
    for (final t in [...ToolCatalog.trending, ...ToolCatalog.recommended]) {
      if (!t.isAvailable || seen.contains(t.id)) continue;
      seen.add(t.id);
      fallback.add(t);
    }
    return rankPopular<ToolModel>(
      recentToolIds: history.recentToolIds.toList(),
      historyToolIds: history.history.map((e) => e.toolId),
      fallback: fallback,
      idOf: (t) => t.id,
      isAvailable: (t) => t.isAvailable,
      limit: 8,
    );
  }

  /// Prefer everyday categories first (like Canva discovery).
  List<ToolCategory> get categories => const [
        ToolCategory.pdf,
        ToolCategory.images,
        ToolCategory.ai,
        ToolCategory.qr,
        ToolCategory.files,
        ToolCategory.developer,
        ToolCategory.text,
        ToolCategory.documents,
      ];

  List<HistoryItem> get recentActions => history.history.take(6).toList();

  HistoryItem? get continueAction =>
      history.history.isEmpty ? null : history.history.first;

  bool get hasNotes {
    final raw = Get.find<StorageService>().read(AppConstants.keyNotes);
    return raw is List && raw.isNotEmpty;
  }

  int get noteCount {
    final raw = Get.find<StorageService>().read(AppConstants.keyNotes);
    if (raw is! List) return 0;
    return raw.length;
  }

  bool get showContinue => continueAction != null || hasNotes;
}
