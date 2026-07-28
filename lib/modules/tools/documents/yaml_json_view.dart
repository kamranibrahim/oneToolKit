import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import '../../../widgets/tool_scaffold.dart';

class YamlJsonView extends StatefulWidget {
  const YamlJsonView({super.key});

  @override
  State<YamlJsonView> createState() => _YamlJsonViewState();
}

class _YamlJsonViewState extends State<YamlJsonView> {
  final _input = TextEditingController(text: 'name: OneToolkit\nversion: 1.0\nfeatures:\n  - pdf\n  - qr');
  final _output = TextEditingController();
  String? _error;

  dynamic _yamlToDart(dynamic node) {
    if (node is YamlMap) {
      return {for (final e in node.entries) '${e.key}': _yamlToDart(e.value)};
    }
    if (node is YamlList) {
      return node.map(_yamlToDart).toList();
    }
    return node;
  }

  void _yamlToJson() {
    try {
      final parsed = loadYaml(_input.text);
      final dart = _yamlToDart(parsed);
      _output.text = const JsonEncoder.withIndent('  ').convert(dart);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'yaml_json',
        toolName: 'YAML ↔ JSON',
        action: 'YAML → JSON',
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _jsonToYaml() {
    try {
      final decoded = jsonDecode(_input.text);
      _output.text = _toYaml(decoded);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'yaml_json',
        toolName: 'YAML ↔ JSON',
        action: 'JSON → YAML',
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  String _toYaml(dynamic value, {int indent = 0}) {
    final pad = '  ' * indent;
    if (value is Map) {
      if (value.isEmpty) return '{}';
      final buf = StringBuffer();
      value.forEach((k, v) {
        if (v is Map || v is List) {
          buf.writeln('$pad$k:');
          buf.write(_toYaml(v, indent: indent + 1));
        } else {
          buf.writeln('$pad$k: ${_scalar(v)}');
        }
      });
      return buf.toString();
    }
    if (value is List) {
      if (value.isEmpty) return '$pad[]\n';
      final buf = StringBuffer();
      for (final item in value) {
        if (item is Map || item is List) {
          buf.writeln('$pad-');
          buf.write(_toYaml(item, indent: indent + 1));
        } else {
          buf.writeln('$pad- ${_scalar(item)}');
        }
      }
      return buf.toString();
    }
    return '$pad${_scalar(value)}\n';
  }

  String _scalar(dynamic v) {
    if (v is String) {
      if (v.contains(':') || v.contains('#') || v.contains('\n')) {
        return '"${v.replaceAll('"', r'\"')}"';
      }
      return v;
    }
    return '$v';
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
      toolId: 'yaml_json',
      title: 'YAML ↔ JSON',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _input,
            maxLines: 10,
            decoration: InputDecoration(labelText: 'Input', errorText: _error),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _yamlToJson,
                  child: const Text('YAML → JSON'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _jsonToYaml,
                  child: const Text('JSON → YAML'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _output,
            maxLines: 12,
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
