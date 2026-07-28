import 'package:get/get.dart';

import '../../data/models/tool_model.dart';
import '../../data/services/favorites_service.dart';

class FavoritesController extends GetxController {
  final favorites = Get.find<FavoritesService>();

  List<ToolModel> get tools => favorites.favoriteTools();

  void reorder(int oldIndex, int newIndex) {
    favorites.reorderFavorites(oldIndex, newIndex);
  }
}
