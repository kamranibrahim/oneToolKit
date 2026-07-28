import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../widgets/tool_scaffold.dart';

class TimestampView extends StatefulWidget {
  const TimestampView({super.key});

  @override
  State<TimestampView> createState() => _TimestampViewState();
}

class _TimestampViewState extends State<TimestampView> {
  final _unix = TextEditingController();
  final _fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
  DateTime _now = DateTime.now();
  String? _converted;
  String? _error;

  @override
  void initState() {
    super.initState();
    _unix.text = '${_now.millisecondsSinceEpoch ~/ 1000}';
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _tick();
    });
  }

  void _fromUnix() {
    final raw = _unix.text.trim();
    final value = int.tryParse(raw);
    if (value == null) {
      setState(() {
        _error = 'Enter a number';
        _converted = null;
      });
      return;
    }
    // Support seconds or milliseconds
    final ms = raw.length > 11 ? value : value * 1000;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    setState(() {
      _converted = _fmt.format(dt.toLocal());
      _error = null;
    });
  }

  @override
  void dispose() {
    _unix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final epoch = _now.millisecondsSinceEpoch ~/ 1000;

    return ToolScaffold(
      toolId: 'timestamp',
      title: 'Timestamp',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Current Unix time'),
              subtitle: Text('$epoch'),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => ToolScaffold.copy('$epoch'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _fmt.format(_now.toLocal()),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _unix,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Unix timestamp',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _fromUnix, child: const Text('Convert to date')),
          if (_converted != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Local date'),
                subtitle: Text(_converted!),
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () => ToolScaffold.copy(_converted!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
