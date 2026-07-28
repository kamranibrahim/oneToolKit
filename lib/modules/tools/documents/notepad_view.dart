import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/services/storage_service.dart';
import '../../../widgets/tool_scaffold.dart';

class NotepadView extends StatefulWidget {
  const NotepadView({super.key});

  @override
  State<NotepadView> createState() => _NotepadViewState();
}

class _NotepadViewState extends State<NotepadView> {
  final _storage = Get.find<StorageService>();
  final _notes = <_Note>[].obs;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final raw = _storage.read(AppConstants.keyNotes);
    if (raw is! List) return;
    _notes.assignAll(
      raw.whereType<Map>().map((e) {
        final map = Map<String, dynamic>.from(e);
        return _Note(
          id: map['id']?.toString() ?? _uuid.v4(),
          title: map['title']?.toString() ?? '',
          body: map['body']?.toString() ?? '',
          updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
        );
      }),
    );
  }

  Future<void> _persist() async {
    await _storage.write(
      AppConstants.keyNotes,
      _notes
          .map(
            (n) => {
              'id': n.id,
              'title': n.title,
              'body': n.body,
              'updatedAt': n.updatedAt.toIso8601String(),
            },
          )
          .toList(),
    );
  }

  Future<void> _edit({_Note? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    final saved = await Get.dialog<bool>(
      AlertDialog(
        title: Text(existing == null ? 'New note' : 'Edit note'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: body,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    final note = _Note(
      id: existing?.id ?? _uuid.v4(),
      title: title.text.trim().isEmpty ? 'Untitled' : title.text.trim(),
      body: body.text.trim(),
      updatedAt: DateTime.now(),
    );
    if (existing == null) {
      _notes.insert(0, note);
    } else {
      final i = _notes.indexWhere((n) => n.id == existing.id);
      if (i >= 0) _notes[i] = note;
    }
    await _persist();
    await ToolScaffold.logAction(
      toolId: 'notepad',
      toolName: 'Notepad',
      action: existing == null ? 'Created' : 'Updated',
      detail: note.title,
    );
  }

  Future<void> _delete(_Note note) async {
    _notes.removeWhere((n) => n.id == note.id);
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'notepad',
      title: 'Notepad',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add_rounded),
      ),
      body: Obx(() {
        if (_notes.isEmpty) {
          return Center(
            child: Text(
              'Notes stay on this device only.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          itemCount: _notes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final note = _notes[index];
            return Material(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _edit(existing: note),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _delete(note),
                          ),
                        ],
                      ),
                      if (note.body.isNotEmpty)
                        Text(
                          note.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _Note {
  _Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;
}
