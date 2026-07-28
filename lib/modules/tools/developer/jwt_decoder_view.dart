import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class JwtDecoderView extends StatefulWidget {
  const JwtDecoderView({super.key});

  @override
  State<JwtDecoderView> createState() => _JwtDecoderViewState();
}

class _JwtDecoderViewState extends State<JwtDecoderView> {
  final _controller = TextEditingController();
  String? _header;
  String? _payload;
  String? _error;

  void _decode() {
    final token = _controller.text.trim();
    final parts = token.split('.');
    if (parts.length < 2) {
      setState(() {
        _error = 'Invalid JWT (expected 3 parts)';
        _header = null;
        _payload = null;
      });
      return;
    }
    try {
      String normalize(String s) {
        var out = s.replaceAll('-', '+').replaceAll('_', '/');
        switch (out.length % 4) {
          case 2:
            out += '==';
          case 3:
            out += '=';
        }
        return out;
      }

      final headerJson = utf8.decode(base64Decode(normalize(parts[0])));
      final payloadJson = utf8.decode(base64Decode(normalize(parts[1])));
      setState(() {
        _header = const JsonEncoder.withIndent('  ').convert(jsonDecode(headerJson));
        _payload = const JsonEncoder.withIndent('  ').convert(jsonDecode(payloadJson));
        _error = null;
      });
      ToolScaffold.logAction(
        toolId: 'jwt_decoder',
        toolName: 'JWT Decoder',
        action: 'Decoded',
      );
    } catch (_) {
      setState(() {
        _error = 'Could not decode token';
        _header = null;
        _payload = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'jwt_decoder',
      title: 'JWT Decoder',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Paste JWT…',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _decode, child: const Text('Decode')),
          if (_header != null) ...[
            const SizedBox(height: 16),
            Text('Header', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            SelectableText(_header!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: 12),
            Text('Payload', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            SelectableText(_payload!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
