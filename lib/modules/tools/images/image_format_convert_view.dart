import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';

import '../../../widgets/tool_scaffold.dart';

enum ImageOutFormat { jpg, png, webp }

class ImageFormatConvertView extends StatefulWidget {
  const ImageFormatConvertView({
    super.key,
    this.toolId = 'webp_convert',
    this.title = 'WebP Converter',
    this.initialFormat = ImageOutFormat.webp,
  });

  final String toolId;
  final String title;
  final ImageOutFormat initialFormat;

  @override
  State<ImageFormatConvertView> createState() => _ImageFormatConvertViewState();
}

/// HEIC → JPG/PNG using platform compress (works with iPhone photos).
class HeicConvertView extends StatelessWidget {
  const HeicConvertView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImageFormatConvertView(
      toolId: 'heic_convert',
      title: 'HEIC Converter',
      initialFormat: ImageOutFormat.jpg,
    );
  }
}

class WebpConvertView extends StatelessWidget {
  const WebpConvertView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImageFormatConvertView(
      toolId: 'webp_convert',
      title: 'WebP Converter',
      initialFormat: ImageOutFormat.webp,
    );
  }
}

class _ImageFormatConvertViewState extends State<ImageFormatConvertView> {
  final _picker = ImagePicker();
  XFile? _source;
  late ImageOutFormat _format;
  int _quality = 85;
  bool _busy = false;
  String? _outputPath;
  String? _status;

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat;
  }

  Future<void> _pick() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _source = file;
      _outputPath = null;
      _status = 'Selected ${p.basename(file.path)}';
    });
  }

  Future<void> _convert() async {
    if (_source == null) return;
    setState(() {
      _busy = true;
      _status = 'Converting…';
    });
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ext = switch (_format) {
        ImageOutFormat.jpg => 'jpg',
        ImageOutFormat.png => 'png',
        ImageOutFormat.webp => 'webp',
      };
      final outPath = p.join(dir.path, 'converted_$stamp.$ext');

      final compressFormat = switch (_format) {
        ImageOutFormat.jpg => CompressFormat.jpeg,
        ImageOutFormat.png => CompressFormat.png,
        ImageOutFormat.webp => CompressFormat.webp,
      };

      XFile? compressed;
      try {
        compressed = await FlutterImageCompress.compressAndGetFile(
          _source!.path,
          outPath,
          quality: _quality,
          format: compressFormat,
        );
      } catch (_) {
        compressed = null;
      }

      if (compressed != null) {
        setState(() {
          _outputPath = compressed!.path;
          _status = 'Saved as ${p.basename(compressed.path)}';
        });
      } else {
        final bytes = await _source!.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) throw Exception('Unsupported image format');
        late Uint8List encoded;
        switch (_format) {
          case ImageOutFormat.jpg:
            encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: _quality));
          case ImageOutFormat.png:
            encoded = Uint8List.fromList(img.encodePng(decoded));
          case ImageOutFormat.webp:
            encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: _quality));
            final jpgPath = p.join(dir.path, 'converted_$stamp.jpg');
            await File(jpgPath).writeAsBytes(encoded);
            setState(() {
              _outputPath = jpgPath;
              _status = 'WebP encoder unavailable — exported as JPG';
            });
            await ToolScaffold.logAction(
              toolId: widget.toolId,
              toolName: widget.title,
              action: 'Converted',
              detail: 'JPG fallback',
            );
            return;
        }
        await File(outPath).writeAsBytes(encoded);
        setState(() {
          _outputPath = outPath;
          _status = 'Saved as ${p.basename(outPath)}';
        });
      }

      await ToolScaffold.logAction(
        toolId: widget.toolId,
        toolName: widget.title,
        action: 'Converted',
        detail: ext.toUpperCase(),
      );
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: widget.toolId,
      title: widget.title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Choose image'),
          ),
          if (_source != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(_source!.path),
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: Theme.of(context).cardTheme.color,
                  child: Text(p.basename(_source!.path)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Output format', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ImageOutFormat>(
              segments: const [
                ButtonSegment(value: ImageOutFormat.jpg, label: Text('JPG')),
                ButtonSegment(value: ImageOutFormat.png, label: Text('PNG')),
                ButtonSegment(value: ImageOutFormat.webp, label: Text('WebP')),
              ],
              selected: {_format},
              onSelectionChanged: _busy
                  ? null
                  : (s) => setState(() => _format = s.first),
            ),
            if (_format != ImageOutFormat.png) ...[
              const SizedBox(height: 12),
              Text('Quality: $_quality'),
              Slider(
                value: _quality.toDouble(),
                min: 20,
                max: 100,
                divisions: 16,
                label: '$_quality',
                onChanged: _busy ? null : (v) => setState(() => _quality = v.round()),
              ),
            ],
            FilledButton.tonal(
              onPressed: _busy ? null : _convert,
              child: Text(_busy ? 'Converting…' : 'Convert'),
            ),
          ],
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, textAlign: TextAlign.center),
          ],
          if (_outputPath != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => shareFiles(context, [XFile(_outputPath!)]),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share converted image'),
            ),
          ],
        ],
      ),
    );
  }
}
