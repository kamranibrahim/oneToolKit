import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../widgets/tool_scaffold.dart';

class UuidGeneratorView extends StatefulWidget {
  const UuidGeneratorView({super.key});

  @override
  State<UuidGeneratorView> createState() => _UuidGeneratorViewState();
}

class _UuidGeneratorViewState extends State<UuidGeneratorView> {
  final _uuid = const Uuid();
  final _items = <String>[];
  int _count = 1;

  void _generate() {
    setState(() {
      _items
        ..clear()
        ..addAll(List.generate(_count, (_) => _uuid.v4()));
    });
    ToolScaffold.logAction(
      toolId: 'uuid_generator',
      toolName: 'UUID Generator',
      action: 'Generated',
      detail: '$_count UUID(s)',
    );
  }

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'uuid_generator',
      title: 'UUID Generator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Count: $_count'),
          Slider(
            value: _count.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: '$_count',
            onChanged: (v) => setState(() => _count = v.round()),
          ),
          FilledButton(onPressed: _generate, child: const Text('Generate')),
          const SizedBox(height: 16),
          ..._items.map(
            (id) => Card(
              child: ListTile(
                title: SelectableText(id, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () => ToolScaffold.copy(id),
                ),
              ),
            ),
          ),
          if (_items.length > 1) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ToolScaffold.copy(_items.join('\n')),
              icon: const Icon(Icons.copy_all_rounded),
              label: const Text('Copy all'),
            ),
          ],
        ],
      ),
    );
  }
}
