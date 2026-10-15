import 'dart:convert';
import 'package:path/path.dart' as p;

abstract final class FileNames {
  static void validate(String name) {
    if (name.isEmpty ||
        name.trim() != name ||
        name == '.' ||
        name == '..' ||
        name.endsWith('.') ||
        utf8.encode(name).length > 240 ||
        RegExp(r'[\x00-\x1f\x7f/\\:*?"<>|]').hasMatch(name) ||
        RegExp(
          r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
          caseSensitive: false,
        ).hasMatch(name)) {
      throw FormatException(
        'Invalid filename: "$name". Use a plain filename without folders or reserved characters.',
      );
    }
  }

  static List<String> rename(List<String> names, String pattern, int start) {
    if (start < 0) {
      throw const FormatException('Start number must not be negative.');
    }
    final remainder = pattern.replaceAll(RegExp(r'\{[^{}]+\}'), '');
    if (pattern.trim().isEmpty ||
        remainder.contains('{') ||
        remainder.contains('}')) {
      throw const FormatException('Enter a valid naming pattern.');
    }
    final result = <String>[];
    for (var i = 0; i < names.length; i++) {
      final ext = p.extension(names[i]);
      var output = pattern.replaceAllMapped(RegExp(r'\{([^{}]+)\}'), (match) {
        return switch (match[1]) {
          'name' => p.basenameWithoutExtension(names[i]),
          'n' => (start + i).toString().padLeft(2, '0'),
          'ext' => ext.replaceFirst('.', ''),
          _ => throw FormatException('Unknown placeholder: ${match[0]}'),
        };
      });
      if (!pattern.contains('{ext}') &&
          ext.isNotEmpty &&
          !output.toLowerCase().endsWith(ext.toLowerCase())) {
        output += ext;
      }
      validate(output);
      result.add(output);
    }
    requireUnique(result);
    return result;
  }

  static void requireUnique(Iterable<String> names) {
    final seen = <String>{};
    for (final name in names) {
      validate(name);
      if (!seen.add(name.toLowerCase())) {
        throw FormatException(
          'More than one file would be named "$name". Add {n} or choose unique names.',
        );
      }
    }
  }
}
