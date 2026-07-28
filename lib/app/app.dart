import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/constants/app_constants.dart';
import '../data/services/storage_service.dart';
import '../modules/settings/settings_controller.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class OneToolkitApp extends StatelessWidget {
  const OneToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final storage = Get.find<StorageService>();
    final seenOnboarding =
        storage.read<bool>(AppConstants.keyOnboardingDone) == true;

    return Obx(
      () => GetMaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settings.themeMode.value,
        initialBinding: InitialBinding(),
        initialRoute: seenOnboarding ? AppRoutes.shell : AppRoutes.onboarding,
        getPages: AppPages.pages,
        defaultTransition: Transition.cupertino,
        builder: (context, child) {
          final brightness = Theme.of(context).brightness;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  brightness == Brightness.dark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: Theme.of(context).cardTheme.color,
              systemNavigationBarIconBrightness:
                  brightness == Brightness.dark ? Brightness.light : Brightness.dark,
            ),
          );
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
