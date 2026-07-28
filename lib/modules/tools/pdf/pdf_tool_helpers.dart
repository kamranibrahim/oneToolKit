import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Shared helpers for Syncfusion PDF page tools.
abstract final class PdfToolHelpers {
  /// Parses ranges like `1-3,5,8` (1-based) into 0-based indices.
  static Set<int> parsePageSelection(String input, int pageCount) {
    final selected = <int>{};
    final parts = input.split(RegExp(r'[,\s]+')).where((p) => p.isNotEmpty);
    for (final part in parts) {
      if (part.contains('-')) {
        final ends = part.split('-');
        if (ends.length != 2) continue;
        final start = int.tryParse(ends[0].trim());
        final end = int.tryParse(ends[1].trim());
        if (start == null || end == null) continue;
        final lo = math.min(start, end);
        final hi = math.max(start, end);
        for (var n = lo; n <= hi; n++) {
          if (n >= 1 && n <= pageCount) selected.add(n - 1);
        }
      } else {
        final n = int.tryParse(part.trim());
        if (n != null && n >= 1 && n <= pageCount) selected.add(n - 1);
      }
    }
    return selected;
  }

  static Future<File> writeTempPdf(List<int> bytes, String prefix) async {
    final dir = await getTemporaryDirectory();
    final outPath = p.join(
      dir.path,
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final file = File(outPath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<PdfDocument> load(String path) async {
    final bytes = await File(path).readAsBytes();
    return PdfDocument(inputBytes: bytes);
  }

  /// Builds a new document with pages from [source] in [order] (0-based).
  static PdfDocument rebuildInOrder(PdfDocument source, List<int> order) {
    final dest = PdfDocument();
    dest.pageSettings.setMargins(0);
    for (final index in order) {
      if (index < 0 || index >= source.pages.count) continue;
      final page = source.pages[index];
      final size = page.size;
      dest.pageSettings.size = size;
      final template = page.createTemplate();
      final newPage = dest.pages.add();
      newPage.graphics.drawPdfTemplate(
        template,
        Offset.zero,
        Size(size.width, size.height),
      );
    }
    return dest;
  }
}
