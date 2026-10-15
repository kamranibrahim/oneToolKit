import '../processing/file_names.dart';
import 'submission_requirements.dart';

enum InstructionField { maxBytes, maxPages, format, exactName, document }

class InstructionSuggestion {
  const InstructionSuggestion(
    this.field,
    this.value,
    this.source,
    this.explanation,
  );
  final InstructionField field;
  final Object value;
  final String source, explanation;
  String get label => switch (field) {
    InstructionField.maxBytes => 'Maximum export size: $value bytes',
    InstructionField.maxPages => 'Maximum PDF pages: $value',
    InstructionField.format =>
      'Export format: ${value.toString().toUpperCase()}',
    InstructionField.exactName => 'Required filename: $value',
    InstructionField.document => 'Document: $value',
  };
}

class InstructionSelection {
  InstructionSelection(this.requirements, List<String> documents)
    : documents = List.unmodifiable(documents);
  final SubmissionRequirements requirements;
  final List<String> documents;
}

class InstructionAnalysis {
  InstructionAnalysis(
    List<InstructionSuggestion> suggestions,
    List<String> unresolved,
  ) : suggestions = List.unmodifiable(suggestions),
      unresolved = List.unmodifiable(unresolved);
  final List<InstructionSuggestion> suggestions;

  /// Full lines that could not be safely turned into an editable rule.
  final List<String> unresolved;
  InstructionSelection select(Set<int> indices) {
    final fields = <InstructionField, Object>{};
    final documents = <String>[];
    final seenDocuments = <String>{};
    for (final index in indices.toList()..sort()) {
      if (index < 0 || index >= suggestions.length) {
        throw const FormatException('Review the instructions again.');
      }
      final suggestion = suggestions[index];
      if (suggestion.field == InstructionField.document) {
        final label = suggestion.value as String;
        if (seenDocuments.add(label.toLowerCase())) documents.add(label);
      } else {
        if (fields.containsKey(suggestion.field) &&
            fields[suggestion.field] != suggestion.value) {
          throw const FormatException(
            'Choose only one value for each export rule. Conflicting instructions need your review.',
          );
        }
        fields[suggestion.field] = suggestion.value;
      }
    }
    if (documents.length > 30) {
      throw const FormatException(
        'Choose at most 30 document checklist items.',
      );
    }
    return InstructionSelection(
      SubmissionRequirements(
        maxBytes: fields[InstructionField.maxBytes] as int?,
        maxPages: fields[InstructionField.maxPages] as int?,
        format: fields[InstructionField.format] as String?,
        exactName: fields[InstructionField.exactName] as String?,
      ),
      documents,
    );
  }
}

/// A bounded, local pattern reader. It never executes instructions or claims to
/// understand an arbitrary document. Unsupported lines stay visible for review.
abstract final class InstructionReader {
  static const maxCharacters = 12000;
  static const maxLines = 200;
  static InstructionAnalysis analyze(String text) {
    if (text.trim().isEmpty || text.length > maxCharacters) {
      throw const FormatException(
        'Paste 1–12,000 characters of submission instructions.',
      );
    }
    final lines = text.split(RegExp(r'\r\n|\n|\r'));
    if (lines.length > maxLines) {
      throw const FormatException('Use at most 200 lines of instructions.');
    }
    final suggestions = <InstructionSuggestion>[];
    final unresolved = <String>[];
    var documents = false;
    for (final raw in lines) {
      final source = raw.trim();
      if (source.isEmpty) {
        documents = false;
        continue;
      }
      if (RegExp(
        r'^(required documents|document checklist)\s*:\s*$',
        caseSensitive: false,
      ).hasMatch(source)) {
        documents = true;
        continue;
      }
      final bullet = RegExp(r'^(?:[-*•]|\d+[.)])\s+(.+)$').firstMatch(source);
      final line = (bullet?.group(1) ?? source)
          .replaceFirst(RegExp(r'\.$'), '')
          .trim();
      // Do not turn conditional, optional, negative, per-item or alternative
      // instructions into unconditional final-export constraints.
      final uncertain = RegExp(
        r'\b(if|unless|except|either|or|optional|recommended|example|may|minimum|least|each|per)\b|\bdo not\b|\bdon.t\b|\bnot required\b',
        caseSensitive: false,
      ).hasMatch(line);
      if (documents && bullet != null) {
        if (!uncertain &&
            line.length <= 120 &&
            suggestions
                    .where((s) => s.field == InstructionField.document)
                    .length <
                30) {
          suggestions.add(
            InstructionSuggestion(
              InstructionField.document,
              line,
              source,
              'Suggested from the Required documents list. You still need to link and review the actual file.',
            ),
          );
        } else {
          unresolved.add(source);
        }
        continue;
      }
      documents = false;
      if (uncertain) {
        unresolved.add(source);
        continue;
      }
      final size = RegExp(
        r'^(?:maximum (?:file |export )?size\s*:?|(?:file|export) size must not exceed|(?:file|export) size up to)\s*(\d+(?:\.\d+)?)\s*(bytes?|kb|mb|kib|mib)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (size != null) {
        final unit = size.group(2)!.toLowerCase();
        final factor = switch (unit) {
          'kb' => 1000,
          'mb' => 1000000,
          'kib' => 1024,
          'mib' => 1048576,
          _ => 1,
        };
        final parts = size.group(1)!.split('.');
        final bytes = size.group(1)!.length > 24
            ? 0
            : (BigInt.parse(parts.join()) *
                      BigInt.from(factor) ~/
                      BigInt.from(
                        10,
                      ).pow(parts.length == 1 ? 0 : parts.last.length))
                  .toInt();
        if (bytes >= 1 && bytes <= 500 * 1024 * 1024) {
          suggestions.add(
            InstructionSuggestion(
              InstructionField.maxBytes,
              bytes,
              source,
              'Applies to the final export. KB/MB use 1,000-based units; KiB/MiB use 1,024-based units. Confirm the destination uses this meaning.',
            ),
          );
        } else {
          unresolved.add(source);
        }
        continue;
      }
      final pages = RegExp(
        r'^(?:maximum (?:pdf )?pages\s*:?\s*(\d+)|(?:pdf |document )?(?:must have )?(?:no more than|at most|up to)\s*(\d+)\s+pages)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (pages != null) {
        final count = int.tryParse((pages.group(1) ?? pages.group(2))!);
        if (count != null && count >= 1 && count <= 100) {
          suggestions.add(
            InstructionSuggestion(
              InstructionField.maxPages,
              count,
              source,
              'Maximum pages in the final PDF. A ZIP export cannot satisfy this page-count check.',
            ),
          );
        } else {
          unresolved.add(source);
        }
        continue;
      }
      final format = RegExp(
        r'^(?:(?:required |export |file )?format\s*:\s*(pdf|zip)|submit as (pdf|zip)|(pdf|zip) only)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (format != null) {
        suggestions.add(
          InstructionSuggestion(
            InstructionField.format,
            (format.group(1) ?? format.group(2) ?? format.group(3))!
                .toLowerCase(),
            source,
            'Checks the final export type. This does not change your task operation or package settings.',
          ),
        );
        continue;
      }
      final name = RegExp(
        r'^(?:required filename|file name|filename)\s*:\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (name != null) {
        var value = name.group(1)!.trim();
        if (value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length - 1);
        }
        try {
          FileNames.validate(value);
          if (!RegExp(r'\.(pdf|zip)$', caseSensitive: false).hasMatch(value) ||
              RegExp(r'[{}<>\[\]]').hasMatch(value)) {
            throw const FormatException();
          }
          suggestions.add(
            InstructionSuggestion(
              InstructionField.exactName,
              value,
              source,
              'Treated as a literal, case-sensitive filename including its extension. Edit personalised names yourself.',
            ),
          );
        } catch (_) {
          unresolved.add(source);
        }
        continue;
      }
      unresolved.add(source);
    }
    return InstructionAnalysis(suggestions, unresolved);
  }
}
