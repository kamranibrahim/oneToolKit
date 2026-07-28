import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../categories/categories_view.dart';
import '../favorites/favorites_view.dart';
import '../history/history_view.dart';
import '../home/home_view.dart';
import '../settings/settings_view.dart';
import 'shell_controller.dart';

class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  static const _pages = [
    HomeView(),
    CategoriesView(),
    FavoritesView(),
    HistoryView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: controller.changeTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_outline_rounded),
              selectedIcon: Icon(Icons.star_rounded),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
