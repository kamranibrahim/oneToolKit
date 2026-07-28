import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class CsvJsonView extends StatefulWidget {
  const CsvJsonView({super.key});

  @override
  State<CsvJsonView> createState() => _CsvJsonViewState();
}

class _CsvJsonViewState extends State<CsvJsonView> {
  final _input = TextEditingController(
    text: 'name,age\nAda,36\nGrace,45',
  );
  final _output = TextEditingController();
  String? _error;

  void _csvToJson() {
    try {
      final lines = _input.text
          .trim()
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.length < 2) throw Exception('Need a header + at least one row');
      final headers = _splitCsvLine(lines.first);
      final rows = <Map<String, String>>[];
      for (final line in lines.skip(1)) {
        final cols = _splitCsvLine(line);
        final row = <String, String>{};
        for (var i = 0; i < headers.length; i++) {
          row[headers[i]] = i < cols.length ? cols[i] : '';
        }
        rows.add(row);
      }
      _output.text = const JsonEncoder.withIndent('  ').convert(rows);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'csv_json',
        toolName: 'CSV ↔ JSON',
        action: 'CSV → JSON',
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _jsonToCsv() {
    try {
      final decoded = jsonDecode(_input.text);
      if (decoded is! List || decoded.isEmpty) {
        throw Exception('JSON must be a non-empty array of objects');
      }
      final maps = decoded.whereType<Map>().toList();
      if (maps.isEmpty) throw Exception('No objects found');
      final headers = <String>{};
      for (final m in maps) {
        headers.addAll(m.keys.map((k) => k.toString()));
      }
      final headerList = headers.toList();
      final buffer = StringBuffer(headerList.join(','));
      for (final m in maps) {
        buffer.writeln();
        buffer.write(
          headerList.map((h) => _escapeCsv('${m[h] ?? ''}')).join(','),
        );
      }
      _output.text = buffer.toString();
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'csv_json',
        toolName: 'CSV ↔ JSON',
        action: 'JSON → CSV',
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'csv_json',
      title: 'CSV ↔ JSON',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _input,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'Input',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _csvToJson,
                  child: const Text('CSV → JSON'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _jsonToCsv,
                  child: const Text('JSON → CSV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _output,
            maxLines: 10,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Output'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => ToolScaffold.copy(_output.text),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy output'),
          ),
        ],
      ),
    );
  }
}
