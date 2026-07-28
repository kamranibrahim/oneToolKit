import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../widgets/tool_scaffold.dart';

class WifiQrView extends StatefulWidget {
  const WifiQrView({super.key});

  @override
  State<WifiQrView> createState() => _WifiQrViewState();
}

class _WifiQrViewState extends State<WifiQrView> {
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  String _security = 'WPA';
  bool _hidden = false;

  String get _payload {
    final ssid = _escape(_ssid.text);
    final pass = _escape(_password.text);
    final hidden = _hidden ? 'H:true;' : '';
    if (_security == 'nopass') {
      return 'WIFI:T:nopass;S:$ssid;$hidden;';
    }
    return 'WIFI:T:$_security;S:$ssid;P:$pass;$hidden;';
  }

  String _escape(String value) =>
      value.replaceAll('\\', '\\\\').replaceAll(';', '\\;').replaceAll(',', '\\,').replaceAll(':', '\\:');

  bool get _ready => _ssid.text.trim().isNotEmpty;

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'wifi_qr',
      title: 'WiFi QR',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _ssid,
            decoration: const InputDecoration(labelText: 'Network name (SSID)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _security,
            decoration: const InputDecoration(labelText: 'Security'),
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('None')),
            ],
            onChanged: (v) => setState(() => _security = v ?? 'WPA'),
          ),
          const SizedBox(height: 12),
          if (_security != 'nopass')
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onChanged: (_) => setState(() {}),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hidden network'),
            value: _hidden,
            onChanged: (v) => setState(() => _hidden = v),
          ),
          const SizedBox(height: 16),
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
