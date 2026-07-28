import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../../widgets/tool_scaffold.dart';

class XmlFormatterView extends StatefulWidget {
  const XmlFormatterView({super.key});

  @override
  State<XmlFormatterView> createState() => _XmlFormatterViewState();
}

class _XmlFormatterViewState extends State<XmlFormatterView> {
  final _controller = TextEditingController();
  String? _error;

  void _beautify() {
    try {
      final doc = XmlDocument.parse(_controller.text);
      _controller.text = doc.toXmlString(pretty: true, indent: '  ');
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'xml_formatter',
        toolName: 'XML Formatter',
        action: 'Beautified',
      );
    } catch (_) {
      setState(() => _error = 'Invalid XML');
    }
  }

  void _minify() {
    try {
      final doc = XmlDocument.parse(_controller.text);
      _controller.text = doc.toXmlString(pretty: false);
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'xml_formatter',
        toolName: 'XML Formatter',
        action: 'Minified',
      );
    } catch (_) {
      setState(() => _error = 'Invalid XML');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'xml_formatter',
      title: 'XML Formatter',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Paste XML…',
                  errorText: _error,
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _beautify,
                    child: const Text('Beautify'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _minify,
                    child: const Text('Minify'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Copy',
                  onPressed: () =>
                      ToolScaffold.copy(_controller.text, message: 'Copied'),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
