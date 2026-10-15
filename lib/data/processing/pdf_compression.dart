import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/image_scale.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfCompressionResult {
  const PdfCompressionResult(this.path, this.originalBytes, this.outputBytes);
  final String path;
  final int originalBytes;
  final int outputBytes;
  bool get reduced => outputBytes < originalBytes;
}

class _Snapshot {
  const _Snapshot(
    this.sizes,
    this.rotations,
    this.text,
    this.fields,
    this.annotations,
  );
  final List<Size> sizes;
  final List<PdfPageRotateAngle> rotations;
  final String text;
  final int fields;
  final List<int> annotations;
}

abstract final class PdfCompression {
  static Future<PdfCompressionResult> optimize(
    String input,
    String temporaryRoot, {
    bool scannedCopy = false,
    int quality = 65,
  }) async {
    if (quality < 20 || quality > 90) {
      throw const FormatException('Choose quality from 20 to 90.');
    }
    final originalBytes = await File(input).length();
    if (originalBytes > 50 * 1024 * 1024) {
      throw const FormatException('Choose a PDF under 50 MB.');
    }
    final snapshot = await Isolate.run(() => _inspect(input));
    if (scannedCopy &&
        (snapshot.sizes.length > 20 ||
            snapshot.fields > 0 ||
            snapshot.rotations.any(
              (r) => r != PdfPageRotateAngle.rotateAngle0,
            ) ||
            snapshot.sizes.any((s) => s.width > 2000 || s.height > 2000))) {
      throw const FormatException(
        'Scanned copies support up to 20 unrotated pages without form fields, at ordinary page sizes. Use Preserve mode for this PDF.',
      );
    }
    final work = await Directory(temporaryRoot).createTemp('pdf_compress_');
    final output = p.join(work.path, 'compressed.pdf');
    var keepOutput = false;
    try {
      if (scannedCopy) {
        final images = await PdfCombiner.createImageFromPDF(
          input: MergeInput.path(input),
          outputDirPath: work.path,
          config: const ImageFromPdfConfig(
            rescale: ImageScale.original,
            createOneImage: false,
          ),
        );
        if (images.length != snapshot.sizes.length) {
          throw const FormatException('Not every page could be rendered.');
        }
        final compressed = <String>[];
        for (var i = 0; i < images.length; i++) {
          final result = await FlutterImageCompress.compressAndGetFile(
            images[i],
            p.join(work.path, 'page_$i.jpg'),
            quality: quality,
            format: CompressFormat.jpeg,
          );
          if (result == null) {
            throw const FormatException('A page could not be compressed.');
          }
          compressed.add(result.path);
        }
        await Isolate.run(
          () => assembleScannedPages(compressed, snapshot.sizes, output),
        );
      } else {
        await Isolate.run(() => _preserve(input, output));
      }
      await Isolate.run(() => _verify(output, snapshot, scannedCopy));
      final outputBytes = await File(output).length();
      if (outputBytes >= originalBytes) {
        return PdfCompressionResult(input, originalBytes, originalBytes);
      }
      keepOutput = true;
      return PdfCompressionResult(output, originalBytes, outputBytes);
    } finally {
      if (keepOutput) {
        await for (final entity in work.list()) {
          if (entity.path != output) await entity.delete(recursive: true);
        }
      } else {
        await work.delete(recursive: true);
      }
    }
  }

  static _Snapshot _inspect(String path) {
    final doc = PdfDocument(inputBytes: File(path).readAsBytesSync());
    try {
      if (doc.pages.count == 0 || doc.pages.count > 100) {
        throw const FormatException('Choose a PDF with 1–100 pages.');
      }
      for (var i = 0; i < doc.form.fields.count; i++) {
        if (doc.form.fields[i] is PdfSignatureField) {
          throw const FormatException(
            'Signed or signature-enabled PDFs should be kept unchanged.',
          );
        }
      }
      return _Snapshot(
        [for (var i = 0; i < doc.pages.count; i++) doc.pages[i].size],
        [for (var i = 0; i < doc.pages.count; i++) doc.pages[i].rotation],
        PdfTextExtractor(doc).extractText(),
        doc.form.fields.count,
        [
          for (var i = 0; i < doc.pages.count; i++)
            doc.pages[i].annotations.count,
        ],
      );
    } finally {
      doc.dispose();
    }
  }

  static void _preserve(String input, String output) {
    final doc = PdfDocument(inputBytes: File(input).readAsBytesSync());
    try {
      doc.compressionLevel = PdfCompressionLevel.best;
      doc.fileStructure.incrementalUpdate = false;
      File(output).writeAsBytesSync(doc.saveSync(), flush: true);
    } finally {
      doc.dispose();
    }
  }

  static void assembleScannedPages(
    List<String> images,
    List<Size> sizes,
    String output,
  ) {
    final doc = PdfDocument();
    try {
      for (var i = 0; i < images.length; i++) {
        final section = doc.sections!.add();
        section.pageSettings.orientation = sizes[i].width > sizes[i].height
            ? PdfPageOrientation.landscape
            : PdfPageOrientation.portrait;
        section.pageSettings.size = sizes[i];
        section.pageSettings.setMargins(0);
        section.pages.add().graphics.drawImage(
          PdfBitmap(File(images[i]).readAsBytesSync()),
          Rect.fromLTWH(0, 0, sizes[i].width, sizes[i].height),
        );
      }
      File(output).writeAsBytesSync(doc.saveSync(), flush: true);
    } finally {
      doc.dispose();
    }
  }

  static void _verify(String output, _Snapshot original, bool scanned) {
    final check = _inspect(output);
    if (check.sizes.length != original.sizes.length) {
      throw const FormatException('Output page count changed.');
    }
    for (var i = 0; i < check.sizes.length; i++) {
      if ((check.sizes[i].width - original.sizes[i].width).abs() > 0.1 ||
          (check.sizes[i].height - original.sizes[i].height).abs() > 0.1 ||
          check.rotations[i] != original.rotations[i]) {
        throw const FormatException('Output page geometry changed.');
      }
    }
    if (!scanned &&
        (check.text != original.text ||
            check.fields != original.fields ||
            check.annotations.toString() != original.annotations.toString())) {
      throw const FormatException(
        'Output content verification failed. Original retained.',
      );
    }
  }
}
