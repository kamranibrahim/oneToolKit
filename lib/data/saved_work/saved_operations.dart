import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../processing/archive_operations.dart';
import '../processing/file_names.dart';
import '../processing/pdf_compression.dart';
import 'saved_job.dart';

class SavedOperationInput {
  const SavedOperationInput(this.path, this.name, this.mime);
  final String path, name, mime;
}

class SavedOperationOutput {
  const SavedOperationOutput(this.path, this.mime, {this.message});
  final String path, mime;
  final String? message;
}

typedef SavedExecutor =
    Future<SavedOperationOutput> Function(
      SavedStep step,
      List<SavedOperationInput> inputs,
      Directory work,
    );

abstract final class SavedOperations {
  static void validatePlan(List<SavedStep> steps, List<String> mimes) {
    if (steps.isEmpty || steps.length > 4) {
      throw const FormatException('Choose 1–4 supported steps.');
    }
    var current = mimes;
    for (final step in steps) {
      if (step.version != 1) {
        throw const FormatException('Unsupported task step version.');
      }
      FileNames.validate(step.outputName);
      switch (step.operation) {
        case SavedOperation.mergePdf:
          if (current.length < 2 ||
              current.any((m) => m != 'application/pdf')) {
            throw const FormatException('Merge needs at least two PDFs.');
          }
        case SavedOperation.imagesToPdf:
          if (current.isEmpty ||
              current.length > 20 ||
              current.any((m) => m != 'image/jpeg' && m != 'image/png')) {
            throw const FormatException('Choose 1–20 JPG or PNG images.');
          }
        case SavedOperation.optimizePdf:
          if (current.length != 1 || current.single != 'application/pdf') {
            throw const FormatException('Optimization needs one PDF.');
          }
        case SavedOperation.zip:
          if (current.isEmpty) {
            throw const FormatException('Choose files to package.');
          }
      }
      final zip = step.operation == SavedOperation.zip;
      if (!step.outputName.toLowerCase().endsWith(zip ? '.zip' : '.pdf')) {
        throw const FormatException('Output extension must match the task.');
      }
      current = [zip ? 'application/zip' : 'application/pdf'];
    }
  }

  static Future<SavedOperationOutput> execute(
    SavedStep step,
    List<SavedOperationInput> inputs,
    Directory work,
  ) async {
    validatePlan([step], inputs.map((f) => f.mime).toList());
    final output = p.join(work.path, 'result.pdf');
    switch (step.operation) {
      case SavedOperation.mergePdf:
        final paths = inputs.map((f) => f.path).toList();
        final expected = await Isolate.run(
          () => _pdfPages(paths, rejectForms: true),
        );
        final result = await PdfCombiner.mergeMultiplePDFs(
          inputs: paths.map(MergeInput.path).toList(),
          outputPath: output,
        );
        final actual = await Isolate.run(() => _pdfPages([result]));
        if (expected != actual) {
          throw const FormatException('Merged PDF did not contain every page.');
        }
        return SavedOperationOutput(result, 'application/pdf');
      case SavedOperation.imagesToPdf:
        final paths = inputs.map((f) => f.path).toList();
        await Isolate.run(() => _images(paths, output));
        final count = await Isolate.run(() => _pdfPages([output]));
        if (count != inputs.length) {
          throw const FormatException('Not every image became a page.');
        }
        return SavedOperationOutput(output, 'application/pdf');
      case SavedOperation.optimizePdf:
        final result = await PdfCompression.optimize(
          inputs.single.path,
          work.path,
        );
        // Even an unchanged document gets a separately named saved result.
        await File(result.path).copy(output);
        return SavedOperationOutput(
          output,
          'application/pdf',
          message: result.reduced
              ? 'A smaller copy was saved.'
              : 'No smaller copy found. Original content retained.',
        );
      case SavedOperation.zip:
        final result = await ArchiveOperations.create(
          inputs.map((f) => ArchiveInput(f.path, f.name)).toList(),
          work.path,
        );
        return SavedOperationOutput(result, 'application/zip');
    }
  }

  static int _pdfPages(List<String> paths, {bool rejectForms = false}) {
    var count = 0;
    for (final path in paths) {
      if (File(path).lengthSync() > 50 * 1024 * 1024) {
        throw const FormatException('Each PDF must be under 50 MB.');
      }
      final doc = sf.PdfDocument(inputBytes: File(path).readAsBytesSync());
      try {
        if (rejectForms && doc.form.fields.count > 0) {
          throw const FormatException(
            'Saved merge currently supports PDFs without form or signature fields.',
          );
        }
        count += doc.pages.count;
        if (doc.pages.count == 0 || count > 100) {
          throw const FormatException('Use up to 100 PDF pages per task.');
        }
      } finally {
        doc.dispose();
      }
    }
    return count;
  }

  static Future<void> _images(List<String> paths, String output) async {
    final doc = pw.Document();
    var pixels = 0;
    for (final path in paths) {
      final bytes = File(path).readAsBytesSync();
      final info = img.findDecoderForData(bytes)?.startDecode(bytes);
      if (info == null || info.width <= 0 || info.height <= 0) {
        throw const FormatException('An image could not be read.');
      }
      pixels += info.width * info.height;
      if (info.width * info.height > 8000000 || pixels > 24000000) {
        throw const FormatException(
          'Images are too large for this task. Resize them first.',
        );
      }
      final image = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: info.width > info.height
              ? PdfPageFormat.a4.landscape
              : PdfPageFormat.a4,
          build: (_) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }
    File(output).writeAsBytesSync(await doc.save(), flush: true);
  }
}
