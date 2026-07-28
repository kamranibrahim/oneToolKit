import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../widgets/tool_scaffold.dart';

class ContactQrView extends StatefulWidget {
  const ContactQrView({super.key});

  @override
  State<ContactQrView> createState() => _ContactQrViewState();
}

class _ContactQrViewState extends State<ContactQrView> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _org = TextEditingController();

  String get _payload {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final org = _org.text.trim();
    return 'BEGIN:VCARD\n'
        'VERSION:3.0\n'
        'FN:$name\n'
        '${org.isEmpty ? '' : 'ORG:$org\n'}'
        '${phone.isEmpty ? '' : 'TEL:$phone\n'}'
        '${email.isEmpty ? '' : 'EMAIL:$email\n'}'
        'END:VCARD';
  }

  bool get _ready => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _org.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'contact_qr',
      title: 'Contact QR',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _org,
            decoration: const InputDecoration(labelText: 'Organization'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
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
