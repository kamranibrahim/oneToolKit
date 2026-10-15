import 'dart:convert';
import 'dart:isolate';

/// Strict CSV records: embedded newlines/quotes and significant spaces survive.
abstract final class CsvTableCodec {
  static const maxInputCharacters = 2000000;

  static Future<String> convert(String input, {required bool toJson}) =>
      Isolate.run(
        () => toJson
            ? CsvTableCodec.toJson(input)
            : CsvTableCodec.fromJson(input),
      );
  static void _checkSize(String input) {
    if (input.length > maxInputCharacters) {
      throw const FormatException('Use input up to 2 million characters.');
    }
  }

  static List<List<String>> parse(String input) {
    _checkSize(input);
    if (input.startsWith('\uFEFF')) input = input.substring(1);
    if (input.isEmpty) throw const FormatException('Enter CSV with a header.');
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    var closed = false;
    var recordStarted = false;
    void endField() {
      row.add(field.toString());
      field = StringBuffer();
      closed = false;
    }

    void endRow() {
      endField();
      rows.add(row);
      row = [];
      recordStarted = false;
    }

    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (quoted) {
        if (c == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
            closed = true;
          }
        } else {
          field.write(c);
        }
        continue;
      }
      if (closed && c != ',' && c != '\r' && c != '\n') {
        throw const FormatException('Unexpected text after a closing quote.');
      }
      if (c == ',') {
        endField();
        recordStarted = true;
      } else if (c == '\n' || c == '\r') {
        endRow();
        if (c == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
      } else if (c == '"') {
        if (field.isNotEmpty) {
          throw const FormatException('Quote inside an unquoted field.');
        }
        quoted = true;
        recordStarted = true;
      } else {
        field.write(c);
        recordStarted = true;
      }
    }
    if (quoted) throw const FormatException('A quoted field is not closed.');
    if (recordStarted || row.isNotEmpty || field.isNotEmpty || closed) endRow();
    return rows;
  }

  static String toJson(String input) {
    final records = parse(input);
    final headers = records.first;
    if (headers.any((h) => h.isEmpty) ||
        headers.toSet().length != headers.length) {
      throw const FormatException('Column names must be non-empty and unique.');
    }
    final rows = <Map<String, String>>[];
    for (var i = 1; i < records.length; i++) {
      if (records[i].length != headers.length) {
        throw FormatException(
          'Row ${i + 1} has ${records[i].length} fields; expected ${headers.length}.',
        );
      }
      rows.add(Map.fromIterables(headers, records[i]));
    }
    return const JsonEncoder.withIndent('  ').convert(rows);
  }

  static String fromJson(String input) {
    _checkSize(input);
    final decoded = jsonDecode(input);
    if (decoded is! List || decoded.isEmpty || decoded.any((r) => r is! Map)) {
      throw const FormatException(
        'Use a non-empty JSON array containing only objects.',
      );
    }
    final rows = decoded.cast<Map<String, dynamic>>();
    final headers = <String>{for (final row in rows) ...row.keys}.toList();
    if (headers.isEmpty || headers.any((h) => h.isEmpty)) {
      throw const FormatException('Objects need non-empty column names.');
    }
    String cell(dynamic value) {
      if (value is Map || value is List) {
        throw const FormatException(
          'Nested objects and arrays cannot be represented as CSV cells.',
        );
      }
      return value?.toString() ?? '';
    }

    return [
      headers.map(escape).join(','),
      ...rows.map((row) => headers.map((h) => escape(cell(row[h]))).join(',')),
    ].join('\r\n');
  }

  static String escape(String value) => RegExp('[,"\r\n]').hasMatch(value)
      ? '"${value.replaceAll('"', '""')}"'
      : value;
}
