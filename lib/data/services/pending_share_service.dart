import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/routes/app_pages.dart';
import '../../app/routes/app_routes.dart';
import '../../core/utils/share_router.dart';
import '../catalog/tool_catalog.dart';
import '../models/shared_file.dart';
import '../../modules/share/share_target_sheet.dart';

class PendingShareService extends GetxService with WidgetsBindingObserver {
  static const channelName = 'com.kamranibrahim.onetoolkit/share';

  final pending = <SharedFile>[].obs;
  final MethodChannel _channel = const MethodChannel(channelName);

  bool _presenting = false;
  bool _presented = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShared') {
        await presentIfNeeded();
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(presentIfNeeded());
    }
  }

  Future<void> pullFromNative() async {
    await _pullMethod('takePending');
    await _pullMethod('takeInbox');
  }

  Future<void> _pullMethod(String method) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(method);
      _ingestRows(raw);
    } catch (_) {
      // Channel missing on desktop / unimplemented takeInbox on Android.
    }
  }

  void _ingestRows(dynamic raw) {
    if (raw is! List) return;
    var added = false;
    for (final row in raw) {
      if (row is! Map) continue;
      final path = row['path']?.toString() ?? '';
      final mime = row['mime']?.toString() ?? '';
      if (path.isEmpty) continue;
      if (!File(path).existsSync()) continue;
      pending.add(SharedFile(path: path, mime: mime.isEmpty ? 'application/octet-stream' : mime));
      added = true;
    }
    if (added) _presented = false;
  }

  Future<void> presentIfNeeded() async {
    if (_presenting) return;
    await pullFromNative();
    if (pending.isEmpty) {
      _presented = false;
      return;
    }
    if (Get.currentRoute == AppRoutes.onboarding) return;
    if (_presented) return;

    final ids = suggestedToolIds(pending.map((e) => e.mime));
    if (ids.isEmpty) {
      pending.clear();
      _presented = false;
      Get.snackbar(
        "Can't open this file type",
        '',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    if (ids.length == 1) {
      _presented = true;
      _open(ids.first);
      return;
    }

    _presenting = true;
    _presented = true;
    var opened = false;
    try {
      await showShareTargetSheet(
        ids: ids,
        onPick: (id) {
          opened = true;
          _open(id);
        },
      );
    } finally {
      _presenting = false;
      if (!opened) {
        pending.clear();
        _presented = false;
      }
    }
  }

  void _open(String toolId) {
    if (toolId == 'ai_ocr') {
      takeFor(toolId);
    }
    final tool = ToolCatalog.byId(toolId);
    if (tool == null) {
      pending.clear();
      _presented = false;
      return;
    }
    unawaited(openTool(tool));
  }

  List<SharedFile> takeFor(String toolId) {
    final wantPdf = toolId == 'pdf_merge';
    final wantImage = toolId == 'image_compress' ||
        toolId == 'images_to_pdf' ||
        toolId == 'ai_ocr';
    final taken = pending
        .where((e) {
          final k = shareKind(e.mime);
          if (wantPdf) return k == ShareKind.pdf;
          if (wantImage) return k == ShareKind.image;
          return false;
        })
        .toList();
    pending.clear();
    _presented = false;
    return taken;
  }
}
