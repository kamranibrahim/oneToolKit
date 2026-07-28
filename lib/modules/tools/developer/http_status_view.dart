import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class HttpStatusView extends StatefulWidget {
  const HttpStatusView({super.key});

  @override
  State<HttpStatusView> createState() => _HttpStatusViewState();
}

class _HttpStatusViewState extends State<HttpStatusView> {
  final _query = TextEditingController();
  String _filter = '';

  static const _codes = <(int, String, String)>[
    (100, 'Continue', 'Informational'),
    (101, 'Switching Protocols', 'Informational'),
    (200, 'OK', 'Success'),
    (201, 'Created', 'Success'),
    (202, 'Accepted', 'Success'),
    (204, 'No Content', 'Success'),
    (301, 'Moved Permanently', 'Redirection'),
    (302, 'Found', 'Redirection'),
    (304, 'Not Modified', 'Redirection'),
    (400, 'Bad Request', 'Client Error'),
    (401, 'Unauthorized', 'Client Error'),
    (403, 'Forbidden', 'Client Error'),
    (404, 'Not Found', 'Client Error'),
    (405, 'Method Not Allowed', 'Client Error'),
    (408, 'Request Timeout', 'Client Error'),
    (409, 'Conflict', 'Client Error'),
    (422, 'Unprocessable Entity', 'Client Error'),
    (429, 'Too Many Requests', 'Client Error'),
    (500, 'Internal Server Error', 'Server Error'),
    (501, 'Not Implemented', 'Server Error'),
    (502, 'Bad Gateway', 'Server Error'),
    (503, 'Service Unavailable', 'Server Error'),
    (504, 'Gateway Timeout', 'Server Error'),
  ];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _codes.where((c) {
      final q = _filter.trim().toLowerCase();
      if (q.isEmpty) return true;
      return '${c.$1}'.contains(q) ||
          c.$2.toLowerCase().contains(q) ||
          c.$3.toLowerCase().contains(q);
    }).toList();

    return ToolScaffold(
      toolId: 'http_status',
      title: 'HTTP Status Codes',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              decoration: const InputDecoration(
                hintText: 'Search code or name…',
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
                    leading: CircleAvatar(
                      child: Text(
                        '${item.$1}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(item.$2),
                    subtitle: Text(item.$3),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () => ToolScaffold.copy('${item.$1} ${item.$2}'),
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
