import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class MimeTypesView extends StatefulWidget {
  const MimeTypesView({super.key});

  @override
  State<MimeTypesView> createState() => _MimeTypesViewState();
}

class _MimeTypesViewState extends State<MimeTypesView> {
  final _query = TextEditingController();
  String _filter = '';

  static const _types = <(String, String)>[
    ('.pdf', 'application/pdf'),
    ('.json', 'application/json'),
    ('.xml', 'application/xml'),
    ('.zip', 'application/zip'),
    ('.gz', 'application/gzip'),
    ('.js', 'text/javascript'),
    ('.css', 'text/css'),
    ('.html', 'text/html'),
    ('.txt', 'text/plain'),
    ('.csv', 'text/csv'),
    ('.md', 'text/markdown'),
    ('.png', 'image/png'),
    ('.jpg', 'image/jpeg'),
    ('.jpeg', 'image/jpeg'),
    ('.gif', 'image/gif'),
    ('.webp', 'image/webp'),
    ('.svg', 'image/svg+xml'),
    ('.ico', 'image/x-icon'),
    ('.heic', 'image/heic'),
    ('.mp3', 'audio/mpeg'),
    ('.wav', 'audio/wav'),
    ('.mp4', 'video/mp4'),
    ('.webm', 'video/webm'),
    ('.woff2', 'font/woff2'),
    ('.ttf', 'font/ttf'),
    ('.doc', 'application/msword'),
    (
      '.docx',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ),
    ('.xls', 'application/vnd.ms-excel'),
    (
      '.xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ),
    ('.ppt', 'application/vnd.ms-powerpoint'),
    (
      '.pptx',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    ),
  ];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _types.where((t) {
      final q = _filter.trim().toLowerCase();
      if (q.isEmpty) return true;
      return t.$1.contains(q) || t.$2.toLowerCase().contains(q);
    }).toList();

    return ToolScaffold(
      toolId: 'mime_types',
      title: 'MIME Types',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              decoration: const InputDecoration(
                hintText: 'Search extension or MIME…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return Card(
                  child: ListTile(
                    title: Text(item.$1),
                    subtitle: SelectableText(item.$2),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () => ToolScaffold.copy(item.$2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
