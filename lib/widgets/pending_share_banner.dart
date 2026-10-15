import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/pending_share_service.dart';

/// Keeps unconsumed inputs reachable after a tool is opened or the chooser closes.
class PendingShareBanner extends StatelessWidget {
  const PendingShareBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PendingShareService>()) {
      return const SizedBox.shrink();
    }
    final shares = Get.find<PendingShareService>();
    return Obx(() {
      final count = shares.pending.length;
      final error = shares.intakeError.value;
      if (count == 0 && error == null) return const SizedBox.shrink();
      return Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: SafeArea(
          bottom: false,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.file_present_outlined),
            title: Text(error ?? '$count shared file(s) waiting'),
            trailing: TextButton(
              onPressed: () => shares.presentIfNeeded(force: true),
              child: const Text('Review'),
            ),
          ),
        ),
      );
    });
  }
}
