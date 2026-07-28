import 'package:get/get.dart';

import '../categories/categories_controller.dart';
import '../favorites/favorites_controller.dart';
import '../history/history_controller.dart';
import '../home/home_controller.dart';
import '../settings/settings_controller.dart';
import 'shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ShellController());
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => CategoriesController());
    Get.lazyPut(() => FavoritesController());
    Get.lazyPut(() => HistoryController());
    // SettingsController is permanent from InitialBinding
    Get.find<SettingsController>();
  }
}
