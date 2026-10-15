import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';
import '../../../data/processing/csv_codec.dart';

class CsvJsonView extends StatefulWidget {
  const CsvJsonView({super.key});

  @override
  State<CsvJsonView> createState() => _CsvJsonViewState();
}

class _CsvJsonViewState extends State<CsvJsonView> {
  final _input = TextEditingController(text: 'name,age\nAda,36\nGrace,45');
  final _output = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _convert({required bool toJson}) async {
    final input = _input.text;
    setState(() {
      _busy = true;
      _error = null;
      _output.clear();
    });
    try {
      final result = await CsvTableCodec.convert(input, toJson: toJson);
      if (!mounted) return;
      setState(() => _output.text = result);
      await ToolScaffold.logAction(
        toolId: 'csv_json',
        toolName: 'CSV ↔ JSON',
        action: toJson ? 'CSV → JSON' : 'JSON → CSV',
      );
    } catch (e) {
      if (mounted) {
        _output.clear();
        setState(
          () => _error = e.toString().replaceFirst('FormatException: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          const Text(
            'CSV stores values as text. JSON null and missing values become empty cells. Nested objects and arrays are not supported.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _input,
            enabled: !_busy,
            maxLines: 8,
            decoration: InputDecoration(labelText: 'Input', errorText: _error),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _convert(toJson: true),
                  child: const Text('CSV → JSON'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _convert(toJson: false),
                  child: const Text('JSON → CSV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(),
          TextField(
            controller: _output,
            maxLines: 10,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Output'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _busy || _output.text.isEmpty
                ? null
                : () => ToolScaffold.copy(_output.text),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy output'),
          ),
        ],
      ),
    );
  }
}
