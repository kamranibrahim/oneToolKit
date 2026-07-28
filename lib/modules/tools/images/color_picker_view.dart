import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../widgets/tool_scaffold.dart';

class ColorPickerView extends StatefulWidget {
  const ColorPickerView({super.key});

  @override
  State<ColorPickerView> createState() => _ColorPickerViewState();
}

class _ColorPickerViewState extends State<ColorPickerView> {
  final _picker = ImagePicker();
  img.Image? _decoded;
  ui.Image? _preview;
  Color _color = const Color(0xFF0D9488);
  Offset? _tap;
  String? _path;

  Future<void> _pick() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      ToolScaffold.copy('', message: 'Unsupported image');
      return;
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _path = file.path;
      _decoded = decoded;
      _preview = frame.image;
      _tap = null;
      _color = Color.fromARGB(
        255,
        decoded.getPixel(decoded.width ~/ 2, decoded.height ~/ 2).r.toInt(),
        decoded.getPixel(decoded.width ~/ 2, decoded.height ~/ 2).g.toInt(),
        decoded.getPixel(decoded.width ~/ 2, decoded.height ~/ 2).b.toInt(),
      );
    });
  }

  void _sample(Offset local, Size boxSize) {
    final image = _decoded;
    final preview = _preview;
    if (image == null || preview == null) return;

    final scale = _fitScale(preview.width.toDouble(), preview.height.toDouble(), boxSize);
    final displayW = preview.width * scale;
    final displayH = preview.height * scale;
    final dx = (boxSize.width - displayW) / 2;
    final dy = (boxSize.height - displayH) / 2;

    final x = ((local.dx - dx) / scale).round().clamp(0, image.width - 1);
    final y = ((local.dy - dy) / scale).round().clamp(0, image.height - 1);
    final pixel = image.getPixel(x, y);
    setState(() {
      _tap = Offset(local.dx, local.dy);
      _color = Color.fromARGB(255, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    });
  }

  double _fitScale(double iw, double ih, Size box) {
    return (box.width / iw < box.height / ih) ? box.width / iw : box.height / ih;
  }

  String get _hex {
    final r = (_color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (_color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (_color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  String get _rgb {
    final r = (_color.r * 255).round();
    final g = (_color.g * 255).round();
    final b = (_color.b * 255).round();
    return 'rgb($r, $g, $b)';
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'color_picker',
      title: 'Color Picker',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.photo_library_rounded),
            label: Text(_path == null ? 'Choose image' : 'Change image'),
          ),
          const SizedBox(height: 16),
          if (_preview != null)
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (d) => _sample(
                      d.localPosition,
                      Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RawImage(image: _preview, fit: BoxFit.contain),
                        if (_tap != null)
                          Positioned(
                            left: _tap!.dx - 12,
                            top: _tap!.dy - 12,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(blurRadius: 4, color: Colors.black26),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Tap an image pixel to sample its color'),
            ),
          const SizedBox(height: 16),
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('HEX'),
            subtitle: Text(_hex),
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () => ToolScaffold.copy(_hex),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('RGB'),
            subtitle: Text(_rgb),
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () => ToolScaffold.copy(_rgb),
            ),
          ),
        ],
      ),
    );
  }
}
