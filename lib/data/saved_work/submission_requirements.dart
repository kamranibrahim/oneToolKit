import 'dart:io';
import 'dart:isolate';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../processing/file_names.dart';

/// Rules apply to the final export, never an earlier intermediate document.
class SubmissionRequirements {
  SubmissionRequirements({
    this.maxBytes,
    this.maxPages,
    this.format,
    this.exactName,
  }) {
    if ((maxBytes != null &&
            (maxBytes! < 1 || maxBytes! > 500 * 1024 * 1024)) ||
        (maxPages != null && (maxPages! < 1 || maxPages! > 100)) ||
        (format != null && !['pdf', 'zip'].contains(format))) {
      throw const FormatException('Enter a valid size or page limit.');
    }
    if (exactName != null) FileNames.validate(exactName!);
  }
  final int? maxBytes, maxPages;
  final String? format, exactName;
  bool get isEmpty =>
      maxBytes == null &&
      maxPages == null &&
      format == null &&
      exactName == null;
  Map<String, dynamic> toJson() => {
    'maxBytes': maxBytes,
    'maxPages': maxPages,
    'format': format,
    'exactName': exactName,
  };
  factory SubmissionRequirements.fromJson(Map<String, dynamic> json) =>
      SubmissionRequirements(
        maxBytes: json['maxBytes'] as int?,
        maxPages: json['maxPages'] as int?,
        format: json['format'] as String?,
        exactName: json['exactName'] as String?,
      );
}

enum SubmissionCheckStatus { passed, failed, unresolved }

class SubmissionCheck {
  const SubmissionCheck(this.status, this.message);
  final SubmissionCheckStatus status;
  final String message;
}

class SubmissionValidator {
  static Future<List<SubmissionCheck>> check(
    String path,
    String name,
    SubmissionRequirements rules,
  ) => Isolate.run(() async {
    final file = File(path);
    final bytes = await file.length();
    if (bytes > 100 * 1024 * 1024) {
      throw const FormatException('Export is too large to inspect safely.');
    }
    final header = await file.open();
    late List<int> signature;
    try {
      signature = await header.read(8);
    } finally {
      await header.close();
    }
    final pdf =
        signature.length >= 5 &&
        String.fromCharCodes(signature.take(5)) == '%PDF-';
    final zip =
        signature.length >= 4 &&
        signature[0] == 80 &&
        signature[1] == 75 &&
        signature[2] == 3 &&
        signature[3] == 4;
    final checks = <SubmissionCheck>[];
    void add(bool pass, String message) => checks.add(
      SubmissionCheck(
        pass ? SubmissionCheckStatus.passed : SubmissionCheckStatus.failed,
        message,
      ),
    );
    if (rules.maxBytes != null) {
      add(
        bytes <= rules.maxBytes!,
        'File size: $bytes bytes; maximum ${rules.maxBytes} bytes.',
      );
    }
    if (rules.exactName != null) {
      add(
        name == rules.exactName,
        'Filename: $name; required ${rules.exactName}.',
      );
    }
    if (rules.format != null) {
      add(
        rules.format == 'pdf' ? pdf : zip,
        'Export must be ${rules.format!.toUpperCase()} (file signature checked).',
      );
    }
    if (rules.maxPages != null) {
      if (!pdf) {
        checks.add(
          const SubmissionCheck(
            SubmissionCheckStatus.unresolved,
            'Page count cannot be checked on this export. Check a PDF before packaging it.',
          ),
        );
      } else {
        PdfDocument? document;
        try {
          document = PdfDocument(inputBytes: await file.readAsBytes());
          add(
            document.pages.count <= rules.maxPages!,
            'Pages: ${document.pages.count}; maximum ${rules.maxPages}.',
          );
        } catch (_) {
          checks.add(
            const SubmissionCheck(
              SubmissionCheckStatus.unresolved,
              'PDF page count could not be read.',
            ),
          );
        } finally {
          document?.dispose();
        }
      }
    }
    return checks;
  });
}
