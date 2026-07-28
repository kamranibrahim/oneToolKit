import 'dart:io';
import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Renders low-res page previews for PDF tools.
abstract final class PdfThumbnails {
  /// Returns PNG bytes keyed by 0-based page index.
  static Future<Map<int, Uint8List>> render(
    String path, {
    double dpi = 72,
    int? maxPages,
  }) async {
    final bytes = await File(path).readAsBytes();
    final thumbs = <int, Uint8List>{};
    var index = 0;
    await for (final page in Printing.raster(bytes, dpi: dpi)) {
      thumbs[index] = await page.toPng();
      index += 1;
      if (maxPages != null && index >= maxPages) break;
    }
    return thumbs;
  }
}
