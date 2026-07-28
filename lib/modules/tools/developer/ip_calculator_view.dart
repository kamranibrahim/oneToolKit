import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class IpCalculatorView extends StatefulWidget {
  const IpCalculatorView({super.key});

  @override
  State<IpCalculatorView> createState() => _IpCalculatorViewState();
}

class _IpCalculatorViewState extends State<IpCalculatorView> {
  final _cidr = TextEditingController(text: '192.168.1.10/24');
  Map<String, String> _rows = {};
  String? _error;

  @override
  void dispose() {
    _cidr.dispose();
    super.dispose();
  }

  void _calculate() {
    final raw = _cidr.text.trim();
    final match = RegExp(r'^(\d{1,3}(?:\.\d{1,3}){3})/(\d{1,2})$').firstMatch(raw);
    if (match == null) {
      setState(() {
        _error = 'Use CIDR form like 192.168.1.10/24';
        _rows = {};
      });
      return;
    }
    try {
      final ip = _parseIp(match.group(1)!);
      final prefix = int.parse(match.group(2)!);
      if (prefix < 0 || prefix > 32) throw FormatException('prefix');

      final mask = prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
      final network = ip & mask;
      final broadcast = network | (~mask & 0xFFFFFFFF);
      final hostCount = prefix >= 31 ? (prefix == 32 ? 1 : 2) : (1 << (32 - prefix)) - 2;
      final first = prefix >= 31 ? network : network + 1;
      final last = prefix >= 31 ? broadcast : broadcast - 1;

      setState(() {
        _error = null;
        _rows = {
          'Address': _fmt(ip),
          'Netmask': _fmt(mask),
          'Wildcard': _fmt(~mask & 0xFFFFFFFF),
          'Network': '${_fmt(network)}/$prefix',
          'Broadcast': _fmt(broadcast),
          'First host': _fmt(first),
          'Last host': _fmt(last),
          'Usable hosts': '$hostCount',
          'IP (binary)': _bin(ip),
          'Mask (binary)': _bin(mask),
        };
      });
      ToolScaffold.logAction(
        toolId: 'ip_calculator',
        toolName: 'IP Calculator',
        action: 'Calculated',
        detail: raw,
      );
    } catch (_) {
      setState(() {
        _error = 'Invalid IPv4 address or prefix';
        _rows = {};
      });
    }
  }

  int _parseIp(String value) {
    final parts = value.split('.');
    if (parts.length != 4) throw FormatException('ip');
    var out = 0;
    for (final part in parts) {
      final n = int.parse(part);
      if (n < 0 || n > 255) throw FormatException('octet');
      out = (out << 8) | n;
    }
    return out;
  }

  String _fmt(int value) =>
      '${(value >> 24) & 0xFF}.${(value >> 16) & 0xFF}.${(value >> 8) & 0xFF}.${value & 0xFF}';

  String _bin(int value) {
    final raw = value.toRadixString(2).padLeft(32, '0');
    return [
      raw.substring(0, 8),
      raw.substring(8, 16),
      raw.substring(16, 24),
      raw.substring(24, 32),
    ].join('.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'ip_calculator',
      title: 'IP Calculator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'IPv4 CIDR subnet math — network, broadcast, hosts, and binary masks.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cidr,
            decoration: InputDecoration(
              labelText: 'CIDR',
              hintText: '10.0.0.5/24',
              errorText: _error,
            ),
            onSubmitted: (_) => _calculate(),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _calculate, child: const Text('Calculate')),
          if (_rows.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._rows.entries.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(e.key),
                subtitle: SelectableText(
                  e.value,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                final text =
                    _rows.entries.map((e) => '${e.key}: ${e.value}').join('\n');
                Clipboard.setData(ClipboardData(text: text));
                ToolScaffold.copy(text, message: 'Results copied');
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy all'),
            ),
          ],
        ],
      ),
    );
  }
}
