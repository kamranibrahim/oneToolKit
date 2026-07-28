import 'package:get/get.dart';

import '../../data/catalog/tool_catalog.dart';
import '../../data/models/history_item.dart';
import '../../data/models/tool_model.dart';
import '../../data/services/favorites_service.dart';
import '../../data/services/history_service.dart';

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
    final seen = <String>{};
    final out = <ToolModel>[];
    for (final t in [...ToolCatalog.trending, ...ToolCatalog.recommended]) {
      if (!t.isAvailable || seen.contains(t.id)) continue;
      seen.add(t.id);
      out.add(t);
      if (out.length >= 8) break;
    }
    return out;
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
}
