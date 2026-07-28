import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../widgets/tool_scaffold.dart';

class EmailQrView extends StatefulWidget {
  const EmailQrView({super.key});

  @override
  State<EmailQrView> createState() => _EmailQrViewState();
}

class _EmailQrViewState extends State<EmailQrView> {
  final _to = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();

  String get _payload {
    final to = _to.text.trim();
    final params = <String, String>{};
    if (_subject.text.trim().isNotEmpty) {
      params['subject'] = _subject.text.trim();
    }
    if (_body.text.trim().isNotEmpty) {
      params['body'] = _body.text.trim();
    }
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return query.isEmpty ? 'mailto:$to' : 'mailto:$to?$query';
  }

  bool get _ready => _to.text.trim().contains('@');

  @override
  void dispose() {
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'email_qr',
      title: 'Email QR',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _to,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'To'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _body,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Body'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          if (_ready)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _payload,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
