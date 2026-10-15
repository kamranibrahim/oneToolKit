import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart' hide ZLibDecoder;
import 'package:path/path.dart' as p;

import 'file_names.dart';

class ArchiveInput {
  const ArchiveInput(this.path, this.name);
  final String path;
  final String name;
}

class ArchiveLimits {
  const ArchiveLimits({
    this.maxEntries = 1000,
    this.maxInputBytes = 100 * 1024 * 1024,
    this.maxExpandedBytes = 256 * 1024 * 1024,
    this.maxFileBytes = 128 * 1024 * 1024,
  });
  final int maxEntries;
  final int maxInputBytes;
  final int maxExpandedBytes;
  final int maxFileBytes;
}

abstract final class ArchiveOperations {
  static Future<String> create(
    List<ArchiveInput> inputs,
    String temporaryRoot, {
    ArchiveLimits limits = const ArchiveLimits(),
  }) => Isolate.run(() => _create(inputs, temporaryRoot, limits));

  static Future<String> _create(
    List<ArchiveInput> inputs,
    String root,
    ArchiveLimits limits,
  ) async {
    if (inputs.isEmpty || inputs.length > limits.maxEntries) {
      throw FormatException('Choose between 1 and ${limits.maxEntries} files.');
    }
    FileNames.requireUnique(inputs.map((f) => f.name));
    var total = 0;
    for (final input in inputs) {
      final stat = await File(input.path).stat();
      if (stat.type != FileSystemEntityType.file) {
        throw const FormatException('A selected file is unavailable.');
      }
      total += stat.size;
      if (stat.size > limits.maxFileBytes || total > limits.maxExpandedBytes) {
        throw const FormatException(
          'Selected files exceed the archive size limit.',
        );
      }
    }
    final work = await Directory(root).createTemp('archive_');
    final output = p.join(work.path, 'archive.zip');
    try {
      final encoder = ZipFileEncoder()..create(output);
      try {
        for (final input in inputs) {
          await encoder.addFile(File(input.path), input.name);
        }
      } finally {
        await encoder.close();
      }
      if (await File(output).length() > limits.maxInputBytes) {
        throw const FormatException(
          'Created ZIP exceeds the supported archive size limit.',
        );
      }
      return output;
    } catch (_) {
      await work.delete(recursive: true);
      rethrow;
    }
  }

  // Bound directory parsing before constructing all archive entries. ZIP64 and
  // multi-volume archives are deliberately outside this mobile tool's contract.
  static Future<void> _checkDirectoryBounds(
    String path,
    ArchiveLimits limits,
  ) async {
    final file = await File(path).open();
    try {
      final size = await file.length();
      final start = (size - 65557).clamp(0, size);
      await file.setPosition(start);
      final tail = await file.read(size - start);
      final data = ByteData.sublistView(tail);
      for (var i = tail.length - 22; i >= 0; i--) {
        if (data.getUint32(i, Endian.little) != 0x06054b50 ||
            i + 22 + data.getUint16(i + 20, Endian.little) != tail.length) {
          continue;
        }
        final count = data.getUint16(i + 10, Endian.little);
        final directoryBytes = data.getUint32(i + 12, Endian.little);
        final offset = data.getUint32(i + 16, Endian.little);
        if (data.getUint16(i + 4, Endian.little) != 0 ||
            data.getUint16(i + 6, Endian.little) != 0 ||
            data.getUint16(i + 8, Endian.little) != count ||
            count == 0xffff ||
            count > limits.maxEntries ||
            directoryBytes > 4 * 1024 * 1024 ||
            offset + directoryBytes > start + i) {
          throw const FormatException(
            'ZIP exceeds supported limits or uses ZIP64/multiple volumes.',
          );
        }
        return;
      }
      throw const FormatException('Invalid or incomplete ZIP file.');
    } finally {
      await file.close();
    }
  }

  static Future<List<String>> extract(
    String input,
    String temporaryRoot, {
    ArchiveLimits limits = const ArchiveLimits(),
  }) => Isolate.run(() => _extract(input, temporaryRoot, limits));

  static Future<List<String>> _extract(
    String input,
    String root,
    ArchiveLimits limits,
  ) async {
    if (await File(input).length() > limits.maxInputBytes) {
      throw const FormatException('This ZIP exceeds the input size limit.');
    }
    await _checkDirectoryBounds(input, limits);
    final stream = InputFileStream(input);
    Directory? work;
    try {
      // Read headers directly: ZipDecoder collapses identical filenames before
      // callers can detect them, and may eagerly expand symlink targets.
      final directory = ZipDirectory()..read(stream);
      if (directory.filePosition < 0 ||
          directory.fileHeaders.length !=
              directory.totalCentralDirectoryEntries ||
          directory.fileHeaders.length > limits.maxEntries) {
        throw const FormatException('Invalid ZIP or too many archive entries.');
      }
      final names = <String, bool>{};
      final paths = <String>[];
      var total = 0;
      for (final header in directory.fileHeaders) {
        final raw = header.filename.replaceAll('\\', '/');
        final isDirectory = raw.endsWith('/');
        final name = isDirectory ? raw.substring(0, raw.length - 1) : raw;
        final parts = name.split('/');
        for (final part in parts) {
          FileNames.validate(part);
        }
        final key = parts.join('/').toLowerCase();
        if (names.containsKey(key)) {
          throw const FormatException('ZIP contains conflicting filenames.');
        }
        names[key] = isDirectory;
        paths.add(parts.join('/'));
        final type = (header.externalFileAttributes >> 16) & 0xf000;
        if (type != 0 && type != 0x8000 && type != 0x4000) {
          throw const FormatException(
            'ZIP links and special files are not supported.',
          );
        }
        if (header.generalPurposeBitFlag & 1 != 0) {
          throw const FormatException('Encrypted ZIP files are not supported.');
        }
        if (header.compressionMethod != 0 && header.compressionMethod != 8) {
          throw const FormatException(
            'This ZIP compression method is not supported.',
          );
        }
        total += header.uncompressedSize;
        if (header.uncompressedSize < 0 ||
            header.uncompressedSize > limits.maxFileBytes ||
            total > limits.maxExpandedBytes) {
          throw const FormatException(
            'Expanded ZIP exceeds the extraction size limit.',
          );
        }
        if (header.file == null) {
          throw const FormatException('A ZIP entry is unreadable.');
        }
      }
      for (final name in names.keys) {
        final parts = name.split('/');
        for (var i = 1; i < parts.length; i++) {
          if (names[parts.take(i).join('/')] == false) {
            throw const FormatException(
              'A ZIP file conflicts with a folder path.',
            );
          }
        }
      }
      work = await Directory(root).createTemp('unzip_');
      final outputs = <String>[];
      for (var i = 0; i < directory.fileHeaders.length; i++) {
        final header = directory.fileHeaders[i];
        final dest = p.joinAll([work.path, ...paths[i].split('/')]);
        if (!p.isWithin(work.path, dest)) {
          throw const FormatException('Invalid archive path.');
        }
        if (names[paths[i].toLowerCase()] == true) {
          await Directory(dest).create(recursive: true);
          continue;
        }
        await Directory(p.dirname(dest)).create(recursive: true);
        if (await FileSystemEntity.type(dest, followLinks: false) !=
            FileSystemEntityType.notFound) {
          throw const FormatException(
            'ZIP filenames resolve to the same destination.',
          );
        }
        final output = _CheckedOutput(dest, header.uncompressedSize);
        try {
          final raw = header.file!.getStream(decompress: false);
          if (header.compressionMethod == 8) {
            // The archive package's native decoder buffers all decoded chunks;
            // use a streaming sink so actual-size limits apply during inflate.
            final decoder = ZLibDecoder(
              raw: true,
            ).startChunkedConversion(_OutputSink(output));
            try {
              while (!raw.isEOS) {
                decoder.add(
                  raw.readBytes(raw.length.clamp(0, 65536)).toUint8List(),
                );
              }
            } finally {
              decoder.close();
            }
          } else {
            output.writeStream(raw);
          }
        } finally {
          output.closeSync();
        }
        if (output.length != header.uncompressedSize ||
            output.checksum != header.crc32) {
          throw const FormatException(
            'ZIP content failed its size or checksum check.',
          );
        }
        outputs.add(dest);
      }
      return outputs;
    } catch (_) {
      if (work != null && await work.exists()) {
        await work.delete(recursive: true);
      }
      rethrow;
    } finally {
      await stream.close();
    }
  }
}

/// Enforce actual output sizes as well as header sizes, and verify streamed CRC.
class _CheckedOutput extends OutputFileStream {
  _CheckedOutput(String path, this.limit)
    : super.withFileHandle(FileHandle(path, mode: FileAccess.write));
  final int limit;
  int _crc = 0;
  int get checksum => _crc;

  void _check(int count) {
    if (length + count > limit) {
      throw const FormatException(
        'ZIP entry expands beyond its declared size.',
      );
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    _crc = getCrc32([value], _crc);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    final count = length ?? bytes.length;
    _check(count);
    _crc = getCrc32(
      count == bytes.length ? bytes : bytes.sublist(0, count),
      _crc,
    );
    super.writeBytes(bytes, length: count);
  }
}

class _OutputSink implements Sink<List<int>> {
  _OutputSink(this.output);
  final OutputFileStream output;
  @override
  void add(List<int> data) => output.writeBytes(data);
  @override
  void close() => output.flush();
}
