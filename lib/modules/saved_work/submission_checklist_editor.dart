import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/saved_work/saved_job.dart';
import '../../data/saved_work/submission_checklist.dart';

class SubmissionChecklistEditor extends StatefulWidget {
  const SubmissionChecklistEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.files = const [],
    this.enabled = true,
    this.allowLinking = false,
  });
  final List<SubmissionChecklistItem> items;
  final List<SavedArtifact> files;
  final Future<void> Function(List<SubmissionChecklistItem>) onChanged;
  final bool enabled, allowLinking;
  @override
  State<SubmissionChecklistEditor> createState() =>
      _SubmissionChecklistEditorState();
}

class _SubmissionChecklistEditorState extends State<SubmissionChecklistEditor> {
  bool _busy = false;
  String? _error;
  Future<void> _action(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e
              .toString()
              .replaceFirst('FormatException: ', '')
              .replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _label([SubmissionChecklistItem? item]) async {
    var draft = item?.label ?? '';
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item == null ? 'Add document to checklist' : 'Edit document name',
        ),
        content: TextFormField(
          initialValue: draft,
          onChanged: (value) => draft = value,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Document name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, draft),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null || !mounted) return;
    final next = item == null
        ? SubmissionChecklistItem(id: const Uuid().v4(), label: value)
        : item.copy(label: value);
    await widget.onChanged([
      for (final existing in widget.items)
        if (existing.id == item?.id) next else existing,
      if (item == null) next,
    ]);
  }

  Future<void> _links(SubmissionChecklistItem item) async {
    final selected = item.artifactIds.toSet();
    final ids = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Link files: ${item.label}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Choose saved files that contain this document. Review their contents yourself.',
                ),
                for (final file in widget.files)
                  CheckboxListTile(
                    title: Text(file.name),
                    subtitle: Text(
                      file.sourceIds.isEmpty
                          ? 'Original import'
                          : 'Processed result',
                    ),
                    value: selected.contains(file.id),
                    onChanged: (value) => update(() {
                      if (value == true) {
                        selected.add(file.id);
                      } else {
                        selected.remove(file.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected.toList()),
              child: const Text('Save links'),
            ),
          ],
        ),
      ),
    );
    if (ids == null || !mounted) return;
    await widget.onChanged([
      for (final existing in widget.items)
        existing.id == item.id ? existing.copy(artifactIds: ids) : existing,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_busy;
    final reviewed = widget.items.where((item) => item.reviewed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document checklist',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          widget.allowLinking
              ? '$reviewed/${widget.items.length} reviewed by you. Linked files are checked for changes; contents need your review.'
              : 'Edit this list to match your instructions. Link saved files and review them after processing.',
        ),
        for (final item in widget.items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.label)),
                      IconButton(
                        tooltip: 'Edit ${item.label}',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: enabled
                            ? () => _action(() => _label(item))
                            : null,
                      ),
                      IconButton(
                        tooltip: 'Remove ${item.label}',
                        icon: const Icon(Icons.close),
                        onPressed: enabled
                            ? () => _action(
                                () => widget.onChanged(
                                  widget.items
                                      .where((i) => i.id != item.id)
                                      .toList(),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  if (widget.allowLinking) ...[
                    Text(
                      item.artifactIds.isEmpty
                          ? 'Missing: link a saved file'
                          : '${item.artifactIds.length} saved file(s) linked',
                    ),
                    TextButton(
                      onPressed: enabled
                          ? () => _action(() => _links(item))
                          : null,
                      child: const Text('Link saved files'),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('I reviewed the linked document'),
                      value: item.reviewed,
                      onChanged: enabled && item.artifactIds.isNotEmpty
                          ? (value) => _action(
                              () => widget.onChanged([
                                for (final existing in widget.items)
                                  existing.id == item.id
                                      ? existing.copy(reviewed: value ?? false)
                                      : existing,
                              ]),
                            )
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add document'),
          onPressed: enabled && widget.items.length < 30
              ? () => _action(() => _label())
              : null,
        ),
        if (_error != null) Text(_error!),
      ],
    );
  }
}
