import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/history_service.dart';

class HistoryController extends GetxController {
  final historyService = Get.find<HistoryService>();

  Future<void> clearAll() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes all recent actions and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirm == true) {
      await historyService.clearHistory();
      await historyService.clearRecentTools();
    }
  }
}
