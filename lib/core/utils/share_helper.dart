import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Shares files with a valid [sharePositionOrigin] for iOS popovers.
Future<ShareResult> shareFiles(
  BuildContext context,
  List<XFile> files, {
  String? subject,
  String? text,
}) async {
  Future<ShareResult> attempt(Rect origin) {
    return Share.shareXFiles(
      files,
      subject: subject,
      text: text,
      sharePositionOrigin: origin,
    );
  }

  try {
    return await attempt(shareOrigin(context));
  } on PlatformException catch (e) {
    // Retry with a safe mid-screen anchor if the first origin was rejected.
    if ('${e.message}'.contains('sharePositionOrigin')) {
      return attempt(_fallbackOrigin(context));
    }
    throw Exception(friendlyShareError(e));
  } catch (e) {
    throw Exception(friendlyShareError(e));
  }
}

/// Non-zero rect inside the window — required by UIActivityViewController on iOS.
Rect shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
    final origin = box.localToGlobal(Offset.zero) & box.size;
    if (origin.width > 0 && origin.height > 0) return origin;
  }
  return _fallbackOrigin(context);
}

Rect _fallbackOrigin(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return Rect.fromLTWH(
    size.width * 0.25,
    size.height * 0.45,
    size.width * 0.5,
    64,
  );
}

String friendlyShareError(Object error) {
  final text = error.toString();
  if (text.contains('sharePositionOrigin')) {
    return 'Could not open the share sheet. Try again.';
  }
  if (text.contains('PlatformException')) {
    return 'Sharing failed on this device.';
  }
  return text
      .replaceFirst('Exception: ', '')
      .replaceFirst('PlatformException(', '')
      .trim();
}
