import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/app.dart';
import 'data/services/favorites_service.dart';
import 'data/services/history_service.dart';
import 'data/services/storage_service.dart';
import 'data/services/widget_sync_service.dart';
import 'modules/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  final storage = await Get.putAsync(() => StorageService().init(), permanent: true);
  Get.put(FavoritesService(storage), permanent: true);
  Get.put(HistoryService(storage), permanent: true);
  Get.put(SettingsController(storage), permanent: true);
  final widgets = await Get.putAsync(() => WidgetSyncService().init(), permanent: true);
  await widgets.syncFavorites();

  runApp(const OneToolkitApp());
}
