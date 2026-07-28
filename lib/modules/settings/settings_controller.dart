import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../data/services/storage_service.dart';

class SettingsController extends GetxController {
  SettingsController(this._storage);

  final StorageService _storage;

  final themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    final saved = _storage.read<String>(AppConstants.keyThemeMode);
    themeMode.value = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storage.write(AppConstants.keyThemeMode, value);
  }
}
