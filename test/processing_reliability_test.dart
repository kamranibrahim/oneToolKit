import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:one_toolkit/data/processing/archive_operations.dart';
import 'package:one_toolkit/data/processing/csv_codec.dart';
import 'package:one_toolkit/data/processing/file_names.dart';
import 'package:one_toolkit/data/processing/pdf_compression.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('CSV fidelity', () {
    test(
      'worker conversion returns records and propagates validation errors',
      () async {
        expect(
          jsonDecode(
            await CsvTableCodec.convert(
              'name,note\nAda,"hello, world"',
              toJson: true,
            ),
          ),
          [
            {'name': 'Ada', 'note': 'hello, world'},
          ],
        );
        await expectLater(
          CsvTableCodec.convert('a,b\n1', toJson: true),
          throwsFormatException,
        );
      },
    );

    test(
      'quoted multiline cells, escaped quotes, whitespace and trailing empty fields survive',
      () {
        const csv =
            '\uFEFFname,note,empty\r\n"Ada, L","first\r\nsecond ""quoted""",\r\n Grace ,"",end\r\n';
        final rows = jsonDecode(CsvTableCodec.toJson(csv));
        expect(rows, [
          {'name': 'Ada, L', 'note': 'first\r\nsecond "quoted"', 'empty': ''},
          {'name': ' Grace ', 'note': '', 'empty': 'end'},
        ]);
        expect(
          jsonDecode(
            CsvTableCodec.toJson(CsvTableCodec.fromJson(jsonEncode(rows))),
          ),
          rows,
        );
      },
    );
    test('header names containing quotes, commas and CR are escaped', () {
      final input = [
        {'a,b': 'x', 'say"hi': 'y', 'line\rreturn': 'z'},
      ];
      expect(
        jsonDecode(
          CsvTableCodec.toJson(CsvTableCodec.fromJson(jsonEncode(input))),
        ),
        input,
      );
    });
    for (final csv in [
      'a,a\n1,2',
      ',b\n1,2',
      'a,b\n1,2,3',
      'a,b\n1',
      'a\n"unclosed',
      'a\n"closed"extra',
      'a\nno"quote',
    ]) {
      test('rejects malformed or lossy CSV: ${jsonEncode(csv)}', () {
        expect(() => CsvTableCodec.toJson(csv), throwsFormatException);
      });
    }
    test('oversized CSV and JSON are rejected before parsing', () {
      final input = 'a' * (CsvTableCodec.maxInputCharacters + 1);
      expect(() => CsvTableCodec.toJson(input), throwsFormatException);
      expect(() => CsvTableCodec.fromJson(input), throwsFormatException);
    });

    test(
      'empty values remain rows and a final newline does not create a row',
      () {
        expect(jsonDecode(CsvTableCodec.toJson('value\n""\n')), [
          {'value': ''},
        ]);
        expect(jsonDecode(CsvTableCodec.toJson('value\n')), []);
      },
    );
    for (final json in [
      '[{},1]',
      '[{"a": [1]}]',
      '[{"a": {"b": 1}}]',
      '[{"": 1}]',
    ]) {
      test(
        'rejects JSON that cannot be represented as flat records: $json',
        () {
          expect(() => CsvTableCodec.fromJson(json), throwsFormatException);
        },
      );
    }
  });

  group('Rename contracts', () {
    test('numbered names keep original extensions even for dotted stems', () {
      expect(
        FileNames.rename(['report.final.pdf', 'photo.png'], '{name}_{n}', 9),
        ['report.final_09.pdf', 'photo_10.png'],
      );
      expect(FileNames.rename(['a.pdf'], 'file_{n}.{ext}', 1), ['file_01.pdf']);
    });
    test('does not re-expand placeholders occurring in source filenames', () {
      expect(FileNames.rename(['{n}.txt'], '{name}', 1), ['{n}.txt']);
    });
    test('rejects duplicate names including case-only collisions', () {
      expect(
        () => FileNames.rename(['a.pdf', 'b.pdf'], 'same', 1),
        throwsFormatException,
      );
      expect(
        () => FileNames.rename(['a.pdf', 'A.pdf'], '{name}', 1),
        throwsFormatException,
      );
    });
    for (final pattern in [
      '../escape',
      '/absolute',
      r'folder\name',
      'name:bad',
      '.',
      'CON',
      'name ',
      '{unknown}',
      '',
      '{name',
    ]) {
      test('rejects invalid pattern $pattern', () {
        expect(
          () => FileNames.rename(['input'], pattern, 1),
          throwsFormatException,
        );
      });
    }
  });

  group('Real archive outputs', () {
    late Directory root;
    setUp(() async {
      root = await Directory.systemTemp.createTemp('onetoolkit-archive-test');
    });
    tearDown(() async {
      await root.delete(recursive: true);
    });
    Future<String> zip(List<ArchiveFile> entries) async {
      final archive = Archive();
      for (final entry in entries) {
        archive.add(entry);
      }
      final input = File(p.join(root.path, 'input.zip'));
      await input.writeAsBytes(ZipEncoder().encode(archive));
      return input.path;
    }

    test(
      'same basenames in separate folders preserve their distinct bytes',
      () async {
        final input = await zip([
          ArchiveFile.string('one/report.txt', 'first'),
          ArchiveFile.string('two/report.txt', 'second'),
        ]);
        final paths = await ArchiveOperations.extract(input, root.path);
        expect(paths, hasLength(2));
        expect(await File(paths[0]).readAsString(), 'first');
        expect(await File(paths[1]).readAsString(), 'second');
        expect(paths[0], endsWith('one/report.txt'));
        expect(paths[1], endsWith('two/report.txt'));
      },
    );
    test(
      'create and extract empty, binary and renamed files without changing originals',
      () async {
        final source = File(p.join(root.path, 'source.bin'));
        final bytes = List.generate(70000, (i) => i % 256);
        await source.writeAsBytes(bytes);
        final empty = File(p.join(root.path, 'empty'));
        await empty.writeAsBytes([]);
        final output = await ArchiveOperations.create([
          ArchiveInput(source.path, 'renamed.bin'),
          ArchiveInput(empty.path, 'empty'),
        ], root.path);
        final paths = await ArchiveOperations.extract(output, root.path);
        expect(await File(paths[0]).readAsBytes(), bytes);
        expect(await File(paths[1]).length(), 0);
        expect(await source.readAsBytes(), bytes);
      },
    );
    for (final names in [
      ['../escape.txt'],
      ['/absolute.txt'],
      [r'C:\escape.txt'],
      ['Report.txt', 'report.txt'],
      ['folder', 'folder/file.txt'],
    ]) {
      test('rejects conflicting or escaping archive names: $names', () async {
        final input = await zip([
          for (final name in names) ArchiveFile.string(name, 'content'),
        ]);
        await expectLater(
          ArchiveOperations.extract(input, root.path),
          throwsFormatException,
        );
        expect(root.listSync().whereType<Directory>(), isEmpty);
      });
    }
    test(
      'duplicate entries are rejected before a decoder can collapse them',
      () async {
        final input = await zip([
          ArchiveFile.string('a.txt', 'first'),
          ArchiveFile.string('b.txt', 'second'),
        ]);
        final bytes = await File(input).readAsBytes();
        final marker = utf8.encode('b.txt');
        for (var i = 0; i <= bytes.length - marker.length; i++) {
          if (List.generate(marker.length, (j) => bytes[i + j]).join(',') ==
              marker.join(',')) {
            bytes[i] = 'a'.codeUnitAt(0);
          }
        }
        await File(input).writeAsBytes(bytes);
        await expectLater(
          ArchiveOperations.extract(input, root.path),
          throwsFormatException,
        );
        expect(root.listSync().whereType<Directory>(), isEmpty);
      },
    );

    test('rejects links without following them', () async {
      final input = await zip([
        ArchiveFile.string('link', '../outside')..mode = 0xa1ff,
      ]);
      await expectLater(
        ArchiveOperations.extract(input, root.path),
        throwsFormatException,
      );
    });
    test(
      'applies expanded size and file-count limits before extracting',
      () async {
        final input = await zip([
          ArchiveFile.string('a.txt', '123456'),
          ArchiveFile.string('b.txt', 'abcdef'),
        ]);
        await expectLater(
          ArchiveOperations.extract(
            input,
            root.path,
            limits: const ArchiveLimits(maxExpandedBytes: 10),
          ),
          throwsFormatException,
        );
        await expectLater(
          ArchiveOperations.extract(
            input,
            root.path,
            limits: const ArchiveLimits(maxEntries: 1),
          ),
          throwsFormatException,
        );
        expect(root.listSync().whereType<Directory>(), isEmpty);
      },
    );
    test(
      'checks actual expansion against declared size and cleans partial outputs',
      () async {
        final input = await zip([
          ArchiveFile.string('a.txt', 'repeated ' * 10000),
        ]);
        final bytes = await File(input).readAsBytes();
        // Alter the central uncompressed-size field without changing compressed data.
        for (var i = 0; i < bytes.length - 28; i++) {
          if (bytes[i] == 0x50 &&
              bytes[i + 1] == 0x4b &&
              bytes[i + 2] == 1 &&
              bytes[i + 3] == 2) {
            ByteData.sublistView(bytes).setUint32(i + 24, 10, Endian.little);
            break;
          }
        }
        await File(input).writeAsBytes(bytes);
        await expectLater(
          ArchiveOperations.extract(input, root.path),
          throwsFormatException,
        );
        expect(root.listSync().whereType<Directory>(), isEmpty);
      },
    );
    test(
      'checks CRC instead of reporting corrupt content as extracted',
      () async {
        final input = await zip([ArchiveFile.string('a.txt', 'content')]);
        final bytes = await File(input).readAsBytes();
        for (var i = 0; i < bytes.length - 20; i++) {
          if (bytes[i] == 0x50 &&
              bytes[i + 1] == 0x4b &&
              bytes[i + 2] == 1 &&
              bytes[i + 3] == 2) {
            bytes[i + 16] ^= 0xff;
            break;
          }
        }
        await File(input).writeAsBytes(bytes);
        await expectLater(
          ArchiveOperations.extract(input, root.path),
          throwsFormatException,
        );
        expect(root.listSync().whereType<Directory>(), isEmpty);
      },
    );
    test(
      'oversized created archives are removed instead of producing an unextractable result',
      () async {
        final source = File(p.join(root.path, 'source.txt'));
        await source.writeAsString('original');
        await expectLater(
          ArchiveOperations.create(
            [ArchiveInput(source.path, 'source.txt')],
            root.path,
            limits: const ArchiveLimits(maxInputBytes: 10),
          ),
          throwsFormatException,
        );
        expect(root.listSync().whereType<Directory>(), isEmpty);
        expect(await source.readAsString(), 'original');
      },
    );

    test('duplicate output names fail before archive creation', () async {
      final source = File(p.join(root.path, 'source.txt'));
      await source.writeAsString('untouched');
      await expectLater(
        ArchiveOperations.create([
          ArchiveInput(source.path, 'same.txt'),
          ArchiveInput(source.path, 'SAME.txt'),
        ], root.path),
        throwsFormatException,
      );
      expect(await source.readAsString(), 'untouched');
      expect(root.listSync().whereType<Directory>(), isEmpty);
    });
  });

  group('PDF preservation and size outcomes', () {
    late Directory root;
    setUp(() async {
      root = await Directory.systemTemp.createTemp('onetoolkit-pdf-test');
    });
    tearDown(() async {
      await root.delete(recursive: true);
    });
    Future<String> fixture({bool signature = false}) async {
      final doc = PdfDocument()..compressionLevel = PdfCompressionLevel.none;
      final first = doc.sections!.add();
      first.pageSettings.size = const Size(595, 842);
      final page = first.pages.add();
      page.graphics.drawString(
        'Preserve this text. ' * 100,
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: const Rect.fromLTWH(20, 20, 500, 700),
      );
      doc.form.fields.add(
        PdfTextBoxField(
          page,
          'reference',
          const Rect.fromLTWH(20, 760, 100, 20),
        )..text = 'ABC-123',
      );
      if (signature) {
        doc.form.fields.add(
          PdfSignatureField(
            page,
            'signature',
            bounds: const Rect.fromLTWH(200, 760, 100, 20),
          ),
        );
      }
      final second = doc.sections!.add();
      second.pageSettings.orientation = PdfPageOrientation.landscape;
      second.pageSettings.size = const Size(900, 400);
      second.pages.add().graphics.drawString(
        'Landscape page',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
      );
      final file = File(p.join(root.path, 'original.pdf'));
      await file.writeAsBytes(doc.saveSync());
      doc.dispose();
      return file.path;
    }

    test(
      'preserves text, mixed page sizes and form values; never returns a larger output',
      () async {
        final input = await fixture();
        final original = await File(input).readAsBytes();
        final result = await PdfCompression.optimize(input, root.path);
        expect(result.outputBytes, lessThanOrEqualTo(result.originalBytes));
        final doc = PdfDocument(
          inputBytes: await File(result.path).readAsBytes(),
        );
        final source = PdfDocument(inputBytes: original);
        try {
          expect(
            PdfTextExtractor(doc).extractText(),
            PdfTextExtractor(source).extractText(),
          );
          expect(doc.pages.count, 2);
          expect(doc.pages[0].size, source.pages[0].size);
          expect(doc.pages[1].size, source.pages[1].size);
          expect((doc.form.fields[0] as PdfTextBoxField).text, 'ABC-123');
        } finally {
          doc.dispose();
          source.dispose();
        }
        expect(await File(input).readAsBytes(), original);
        final repeated = await PdfCompression.optimize(result.path, root.path);
        expect(repeated.outputBytes, lessThanOrEqualTo(repeated.originalBytes));
        if (!repeated.reduced) expect(repeated.path, result.path);
      },
    );
    test(
      'scanned assembly retains portrait and landscape page geometry',
      () async {
        final image = File(p.join(root.path, 'page.jpg'));
        await image.writeAsBytes(
          img.encodeJpg(img.Image(width: 20, height: 10)),
        );
        final output = p.join(root.path, 'scanned.pdf');
        PdfCompression.assembleScannedPages(
          [image.path, image.path],
          [const Size(595, 842), const Size(900, 400)],
          output,
        );
        final doc = PdfDocument(inputBytes: await File(output).readAsBytes());
        try {
          expect(doc.pages.count, 2);
          expect(doc.pages[0].size, const Size(595, 842));
          expect(doc.pages[1].size, const Size(900, 400));
        } finally {
          doc.dispose();
        }
      },
    );

    test(
      'signature-enabled PDFs are rejected before output creation',
      () async {
        final input = await fixture(signature: true);
        await expectLater(
          PdfCompression.optimize(input, root.path),
          throwsFormatException,
        );
        expect(root.listSync().whereType<Directory>(), isEmpty);
      },
    );
    test(
      'scanned mode rejects interactive forms before invoking native renderers',
      () async {
        final input = await fixture();
        await expectLater(
          PdfCompression.optimize(input, root.path, scannedCopy: true),
          throwsFormatException,
        );
        expect(root.listSync().whereType<Directory>(), isEmpty);
      },
    );
    test('invalid PDF does not leave an output directory', () async {
      final input = File(p.join(root.path, 'broken.pdf'));
      await input.writeAsString('not a pdf');
      await expectLater(
        PdfCompression.optimize(input.path, root.path),
        throwsA(anything),
      );
      expect(root.listSync().whereType<Directory>(), isEmpty);
    });
  });
}
