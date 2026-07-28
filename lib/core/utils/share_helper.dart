import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Shares files with a valid [sharePositionOrigin] for iOS popovers.
Future<ShareResult> shareFiles(
  BuildContext context,
  List<XFile> files, {
  String? subject,
  String? text,
}) {
  return Share.shareXFiles(
    files,
    subject: subject,
    text: text,
    sharePositionOrigin: shareOrigin(context),
  );
}

/// Non-zero rect inside the window — required by UIActivityViewController on iOS.
Rect shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
    final origin = box.localToGlobal(Offset.zero) & box.size;
    if (origin.width > 0 && origin.height > 0) return origin;
  }

  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 1,
    height: 1,
  );
}
