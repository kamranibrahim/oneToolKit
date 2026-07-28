import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../../../widgets/tool_scaffold.dart';

class TranslateView extends StatefulWidget {
  const TranslateView({super.key});

  @override
  State<TranslateView> createState() => _TranslateViewState();
}

class _TranslateViewState extends State<TranslateView> {
  static const _langs = [
    TranslateLanguage.english,
    TranslateLanguage.spanish,
    TranslateLanguage.french,
    TranslateLanguage.german,
    TranslateLanguage.italian,
    TranslateLanguage.portuguese,
    TranslateLanguage.dutch,
    TranslateLanguage.russian,
    TranslateLanguage.arabic,
    TranslateLanguage.hindi,
    TranslateLanguage.chinese,
    TranslateLanguage.japanese,
    TranslateLanguage.korean,
    TranslateLanguage.turkish,
    TranslateLanguage.polish,
    TranslateLanguage.swedish,
  ];

  final _input = TextEditingController();
  final _modelManager = OnDeviceTranslatorModelManager();
  TranslateLanguage _source = TranslateLanguage.english;
  TranslateLanguage _target = TranslateLanguage.spanish;
  OnDeviceTranslator? _translator;
  String _output = '';
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _input.dispose();
    _translator?.close();
    super.dispose();
  }

  String _label(TranslateLanguage lang) {
    final code = lang.bcpCode;
    return '${code.toUpperCase()} · ${lang.name}';
  }

  Future<void> _ensureModels() async {
    setState(() => _status = 'Downloading language packs if needed…');
    await _modelManager.downloadModel(_source.bcpCode);
    await _modelManager.downloadModel(_target.bcpCode);
  }

  Future<void> _translate() async {
    final text = _input.text.trim();
    if (text.isEmpty) {
      ToolScaffold.copy('', message: 'Enter text to translate');
      return;
    }
    if (_source == _target) {
      ToolScaffold.copy('', message: 'Pick two different languages');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Preparing…';
      _output = '';
    });
    try {
      await _ensureModels();
      await _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: _source,
        targetLanguage: _target,
      );
      setState(() => _status = 'Translating on device…');
      final result = await _translator!.translateText(text);
      setState(() {
        _output = result;
        _status = 'Done';
      });
      await ToolScaffold.logAction(
        toolId: 'ai_translate',
        toolName: 'Translate',
        action: 'Translated',
        detail: '${_source.bcpCode} → ${_target.bcpCode}',
      );
    } catch (e) {
      setState(() => _status = 'Translate failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _swap() {
    setState(() {
      final tmp = _source;
      _source = _target;
      _target = tmp;
      if (_output.isNotEmpty) {
        _input.text = _output;
        _output = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'ai_translate',
      title: 'Translate',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'On-device ML Kit translation. Language packs download once, then work offline.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TranslateLanguage>(
                  // ignore: deprecated_member_use
                  value: _source,
                  decoration: const InputDecoration(labelText: 'From'),
                  items: _langs
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(_label(l), overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v != null) setState(() => _source = v);
                        },
                ),
              ),
              IconButton(
                onPressed: _busy ? null : _swap,
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
              Expanded(
                child: DropdownButtonFormField<TranslateLanguage>(
                  // ignore: deprecated_member_use
                  value: _target,
                  decoration: const InputDecoration(labelText: 'To'),
                  items: _langs
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(_label(l), overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v != null) setState(() => _target = v);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            minLines: 5,
            maxLines: 10,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Text',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _translate,
            icon: const Icon(Icons.translate_rounded),
            label: Text(_busy ? 'Working…' : 'Translate'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, textAlign: TextAlign.center),
          ],
          if (_output.isNotEmpty) ...[
            const SizedBox(height: 16),
            SelectableText(_output, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _output));
                ToolScaffold.copy(_output, message: 'Translation copied');
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy'),
            ),
          ],
        ],
      ),
    );
  }
}
