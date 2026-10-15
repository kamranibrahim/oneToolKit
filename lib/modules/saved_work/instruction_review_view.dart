import 'package:flutter/material.dart';
import '../../data/saved_work/instruction_proposals.dart';

class InstructionReviewView extends StatefulWidget {
  const InstructionReviewView({super.key});
  @override
  State<InstructionReviewView> createState() => _InstructionReviewViewState();
}

class _InstructionReviewViewState extends State<InstructionReviewView> {
  final _text = TextEditingController();
  InstructionAnalysis? _analysis;
  final _selected = <int>{};
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _analyze() {
    FocusScope.of(context).unfocus();
    setState(() {
      _selected.clear();
      _error = null;
      _analysis = null;
      try {
        _analysis = InstructionReader.analyze(_text.text);
      } catch (e) {
        _error = e.toString().replaceFirst('FormatException: ', '');
      }
    });
  }

  void _apply() {
    try {
      final selection = _analysis!.select(_selected);
      Navigator.pop(context, selection);
    } catch (e) {
      setState(
        () => _error = e.toString().replaceFirst('FormatException: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Read submission instructions')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Local helper. Nothing pasted here is sent online or saved with your task.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Recognises common English instruction patterns and can miss requirements. Read the full instructions and review every suggestion before applying it.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          minLines: 5,
          maxLines: 10,
          maxLength: InstructionReader.maxCharacters,
          decoration: const InputDecoration(
            labelText: 'Paste instructions',
            hintText:
                'Maximum file size: 2 MB\nMaximum pages: 4\nFormat: PDF\nRequired filename: application.pdf\nRequired documents:\n- Application form\n- Supporting document',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {
            _analysis = null;
            _selected.clear();
            _error = null;
          }),
        ),
        FilledButton(
          onPressed: _analyze,
          child: const Text('Find suggestions'),
        ),
        if (_analysis != null) ...[
          const SizedBox(height: 16),
          Text(
            '${_analysis!.suggestions.length} suggestions · choose what to apply',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(
            'Selected rules replace the matching fields in your draft. Document names are added to its checklist. Task steps and filenames stay as you configured them.',
          ),
          const Text(
            'If instructions give different values for one rule, choose only the value that applies to your export.',
          ),
          for (var index = 0; index < _analysis!.suggestions.length; index++)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _selected.contains(index),
              title: Text(_analysis!.suggestions[index].label),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Source: ${_analysis!.suggestions[index].source}'),
                  Text(_analysis!.suggestions[index].explanation),
                ],
              ),
              onChanged: (value) => setState(() {
                if (value == true) {
                  _selected.add(index);
                } else {
                  _selected.remove(index);
                }
                _error = null;
              }),
            ),
          if (_analysis!.unresolved.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Review manually (${_analysis!.unresolved.length} lines)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'These lines were not converted into rules. They may still contain important requirements.',
            ),
            for (final line in _analysis!.unresolved)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(line),
              ),
          ],
          if (_analysis!.suggestions.isEmpty)
            const Text(
              'No supported rules found. Enter requirements and checklist items manually in your task.',
            ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_error!),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _analysis == null || _selected.isEmpty ? null : _apply,
          child: Text('Apply selected suggestions (${_selected.length})'),
        ),
      ],
    ),
  );
}
