import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../data/services/favorites_service.dart';
import '../data/services/history_service.dart';
import 'empty_state.dart';

/// Shared scaffold for every tool screen.
class ToolScaffold extends StatelessWidget {
  const ToolScaffold({
    super.key,
    required this.toolId,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String toolId;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final favorites = Get.find<FavoritesService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Obx(() {
            final isFav = favorites.isFavorite(toolId);
            return IconButton(
              tooltip: isFav ? 'Unfavorite' : 'Favorite',
              onPressed: () {
                HapticFeedback.selectionClick();
                favorites.toggleFavorite(toolId);
              },
              icon: Icon(
                isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFav ? const Color(0xFFEAB308) : null,
              ),
            );
          }),
          ...?actions,
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: OfflineBadge(),
          ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  /// Helper to log a completed action to history.
  static Future<void> logAction({
    required String toolId,
    required String toolName,
    required String action,
    String? detail,
  }) {
    return Get.find<HistoryService>().addAction(
      toolId: toolId,
      toolName: toolName,
      action: action,
      detail: detail,
    );
  }

  static void copy(String text, {String message = 'Copied'}) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      message,
      '',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      messageText: const SizedBox.shrink(),
      titleText: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
