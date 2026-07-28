import 'package:get/get.dart';

import '../../data/catalog/tool_catalog.dart';
import '../../data/models/tool_model.dart';
import '../../data/services/favorites_service.dart';
import '../../data/services/history_service.dart';

class HomeController extends GetxController {
  final favorites = Get.find<FavoritesService>();
  final history = Get.find<HistoryService>();

  List<ToolModel> get pinned => favorites.pinnedTools();
  List<ToolModel> get recent => history.recentTools();
  List<ToolModel> get recommended => ToolCatalog.recommended;
  List<ToolModel> get trending => ToolCatalog.trending;
  List<ToolCategory> get categories => ToolCategory.values;
}
