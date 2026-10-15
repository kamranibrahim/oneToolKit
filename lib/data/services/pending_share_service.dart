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
  final intakeError = RxnString();
  final MethodChannel _channel = const MethodChannel(channelName);

  bool _presenting = false;
  bool _pullAfterPresentation = false;
  String? _handoffTool;
  Set<String>? _handoffPaths;
  Future<void>? _pulling;
  bool _presented = false;
  final _acceptedPaths = <String>{};

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
    _channel.setMethodCallHandler(null);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(presentIfNeeded());
    }
  }

  Future<void> pullFromNative() => _pulling ??= _pullAll();

  Future<void> _pullAll() async {
    try {
      intakeError.value = null;
      await _pullMethod('takePending');
      await _pullMethod('takeInbox');
    } finally {
      _pulling = null;
    }
  }

  Future<void> _pullMethod(String method) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(method);
      final accepted = _ingestRows(raw);
      if (accepted.isNotEmpty) {
        await _channel.invokeMethod<void>('acknowledge', accepted);
      }
    } catch (_) {
      // Channel missing on desktop / unimplemented takeInbox on Android.
    }
  }

  List<String> _ingestRows(dynamic raw) {
    if (raw is! List) return const [];
    final accepted = <String>[];
    var added = false;
    for (final row in raw) {
      if (row is! Map) continue;
      if (row['error'] is String) {
        intakeError.value = row['error'] as String;
        continue;
      }
      final path = row['path']?.toString() ?? '';
      final mime = row['mime']?.toString() ?? '';
      if (path.isEmpty) continue;
      if (!File(path).existsSync()) continue;
      accepted.add(path);
      if (!_acceptedPaths.add(path)) continue;
      pending.add(
        SharedFile(
          path: path,
          mime: mime.isEmpty ? 'application/octet-stream' : mime,
        ),
      );
      added = true;
    }
    if (added) _presented = false;
    return accepted;
  }

  Future<void> presentIfNeeded({bool force = false}) async {
    if (_presenting) {
      _pullAfterPresentation = true;
      return;
    }
    _presenting = true;
    String? selected;
    try {
      await pullFromNative();
      if (pending.isEmpty) {
        _presented = false;
        return;
      }
      if (Get.currentRoute == AppRoutes.onboarding) return;
      if (_presented && !force) return;
      _presented = true;
      final offered = pending.toList();
      final ids = suggestedToolIds(offered.map((e) => e.mime));
      // Even a single action uses the chooser so retained inputs can be
      // inspected or explicitly discarded without unexpectedly opening a tool.
      await showShareTargetSheet(
        ids: ids,
        files: offered,
        onDiscard: discard,
        onPick: (id) {
          selected = id;
          _handoffTool = id;
          _handoffPaths = offered.map((file) => file.path).toSet();
        },
      );
    } finally {
      _presenting = false;
      if (_pullAfterPresentation) {
        _pullAfterPresentation = false;
        // A new native share may arrive while the chooser is open. Intake it
        // after this choice, without expanding the user's selected batch.
        unawaited(pullFromNative());
      }
    }
    if (selected != null) {
      final tool = ToolCatalog.byId(selected!);
      if (tool != null) await openTool(tool, preventDuplicates: false);
    }
  }

  void discard() {
    pending.clear();
    _handoffTool = null;
    _handoffPaths = null;
    _presented = false;
  }

  List<SharedFile> takeFor(String toolId) {
    final allowed = _handoffTool == toolId ? _handoffPaths : null;
    final taken = pending
        .where(
          (file) =>
              (allowed == null || allowed.contains(file.path)) &&
              acceptsSharedMime(toolId, file.mime),
        )
        .take(sharedInputLimit(toolId))
        .toList();
    if (_handoffTool == toolId) {
      _handoffTool = null;
      _handoffPaths = null;
    }
    final paths = taken.map((file) => file.path).toSet();
    pending.removeWhere((file) => paths.contains(file.path));
    if (pending.isEmpty) _presented = false;
    return taken;
  }
}
