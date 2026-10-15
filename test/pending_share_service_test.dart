import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:one_toolkit/data/models/shared_file.dart';
import 'package:one_toolkit/app/routes/app_routes.dart';
import 'package:one_toolkit/data/services/favorites_service.dart';
import 'package:one_toolkit/data/services/history_service.dart';
import 'package:one_toolkit/data/services/pending_share_service.dart';
import 'package:one_toolkit/data/services/storage_service.dart';
import 'package:one_toolkit/modules/tools/ai/ocr_view.dart';
import 'package:one_toolkit/widgets/pending_share_banner.dart';

class MemoryStorage extends StorageService {
  final values = <String, dynamic>{};
  @override
  T? read<T>(String key) => values[key] as T?;
  @override
  List<String> readStringList(String key) => [];
  @override
  Future<void> writeStringList(String key, List<String> value) =>
      write(key, value);
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const shareChannel = MethodChannel(PendingShareService.channelName);
  const ocrChannel = MethodChannel('google_mlkit_text_recognizer');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late PendingShareService service;
  late Directory directory;
  late String imagePath;
  late List<dynamic> nativeRows;
  late List<String> acknowledged;

  SharedFile file(String name, String mime) =>
      SharedFile(path: '${directory.path}/$name', mime: mime);

  setUp(() async {
    Get.testMode = true;
    directory = await Directory.systemTemp.createTemp('onetoolkit-share-test');
    imagePath = '${directory.path}/image.png';
    await File(imagePath).writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      ),
    );
    nativeRows = [];
    acknowledged = [];
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      if (call.method == 'takePending') return nativeRows;
      if (call.method == 'takeInbox') return [];
      if (call.method == 'acknowledge') {
        acknowledged.addAll(List<String>.from(call.arguments as List));
        return null;
      }
      throw MissingPluginException();
    });
    service = Get.put(PendingShareService());
  });

  tearDown(() async {
    Get.reset();
    messenger.setMockMethodCallHandler(shareChannel, null);
    messenger.setMockMethodCallHandler(ocrChannel, null);
    await directory.delete(recursive: true);
  });

  test('mixed batch preserves unmatched files and input order', () {
    service.pending.addAll([
      file('one.pdf', 'application/pdf'),
      file('one.png', 'image/png'),
      file('two.pdf', 'application/pdf'),
    ]);
    expect(service.takeFor('pdf_merge').map((f) => f.path), [
      file('one.pdf', '').path,
      file('two.pdf', '').path,
    ]);
    expect(service.pending.single.path, file('one.png', '').path);
  });

  test('single-image tools consume one and preserve remaining batch', () {
    service.pending.addAll([
      file('one.png', 'image/png'),
      file('two.png', 'image/png'),
      file('three.png', 'image/png'),
    ]);
    expect(
      service.takeFor('image_compress').single.path,
      file('one.png', '').path,
    );
    expect(service.takeFor('ai_ocr').single.path, file('two.png', '').path);
    expect(
      service.takeFor('images_to_pdf').single.path,
      file('three.png', '').path,
    );
  });

  test('unsupported tool does not consume inputs', () {
    service.pending.add(file('one.png', 'image/png'));
    expect(service.takeFor('not_supported'), isEmpty);
    expect(service.pending, hasLength(1));
  });

  test(
    'native delivery acknowledges existing copies and deduplicates retries',
    () async {
      nativeRows = [
        {'path': imagePath, 'mime': 'image/png'},
        {'path': '${directory.path}/missing.png', 'mime': 'image/png'},
        'invalid',
      ];
      await service.pullFromNative();
      await service.pullFromNative();
      expect(service.pending.map((f) => f.path), [imagePath]);
      expect(acknowledged, [imagePath, imagePath]);
    },
  );

  test('concurrent native pulls are serialized', () async {
    final release = Completer<void>();
    var reads = 0;
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      if (call.method == 'takePending') {
        reads++;
        await release.future;
      }
      return [];
    });
    final first = service.pullFromNative();
    final second = service.pullFromNative();
    release.complete();
    await Future.wait([first, second]);
    expect(reads, 1);
  });

  testWidgets(
    'cancelled chooser retains inputs and Review reopens it; discard is explicit',
    (tester) async {
      service.pending.add(SharedFile(path: imagePath, mime: 'image/png'));
      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: PendingShareBanner())),
      );
      unawaited(service.presentIfNeeded());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep for later'));
      await tester.pumpAndSettle();
      expect(service.pending, hasLength(1));
      expect(find.text('1 shared file(s) waiting'), findsOneWidget);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard shared files'));
      await tester.pumpAndSettle();
      expect(service.pending, isEmpty);
      expect(find.text('Review'), findsNothing);
    },
  );

  testWidgets('chooser explains single-file processing and retained inputs', (
    tester,
  ) async {
    service.pending.addAll([
      file('one.png', 'image/png'),
      file('two.png', 'image/png'),
    ]);
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: PendingShareBanner())),
    );
    unawaited(service.presentIfNeeded());
    await tester.pumpAndSettle();
    expect(find.text('Uses 1 file(s) · 1 kept for later'), findsOneWidget);
    await tester.tap(find.text('Keep for later'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'OCR recognizes shared image without a picker and leaves other inputs queued',
    (tester) async {
      final storage = MemoryStorage();
      Get.put(FavoritesService(storage));
      final history = Get.put(HistoryService(storage));
      String? recognizedPath;
      messenger.setMockMethodCallHandler(ocrChannel, (call) async {
        if (call.method == 'vision#startTextRecognizer') {
          recognizedPath =
              (call.arguments['imageData'] as Map)['path'] as String?;
          return {'text': 'Shared document', 'blocks': []};
        }
        return null;
      });
      service.pending.addAll([
        SharedFile(path: imagePath, mime: 'image/png'),
        file('keep.pdf', 'application/pdf'),
      ]);
      await tester.pumpWidget(const GetMaterialApp(home: OcrView()));
      await tester.pumpAndSettle();
      expect(recognizedPath, imagePath);
      expect(find.text('Shared document'), findsOneWidget);
      expect(service.pending.single.path, file('keep.pdf', '').path);
      expect(history.history.single.action, 'Extracted');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'choosing OCR hands the shared image through navigation exactly once',
    (tester) async {
      final storage = MemoryStorage();
      Get.put(FavoritesService(storage));
      final history = Get.put(HistoryService(storage));
      final paths = <String>[];
      messenger.setMockMethodCallHandler(ocrChannel, (call) async {
        if (call.method == 'vision#startTextRecognizer') {
          paths.add((call.arguments['imageData'] as Map)['path'] as String);
          return {'text': 'From share chooser', 'blocks': []};
        }
        return null;
      });
      service.pending.add(SharedFile(path: imagePath, mime: 'image/png'));
      await tester.pumpWidget(
        GetMaterialApp(
          home: const Scaffold(body: PendingShareBanner()),
          getPages: [GetPage(name: AppRoutes.ocr, page: () => const OcrView())],
        ),
      );
      unawaited(service.presentIfNeeded());
      await tester.pumpAndSettle();
      await tester.tap(find.text('OCR'));
      await tester.pumpAndSettle();
      expect(paths, [imagePath]);
      expect(service.pending, isEmpty);
      expect(history.recentToolIds, contains('ai_ocr'));
      expect(find.text('From share chooser'), findsOneWidget);
      // A subsequent share to the tool already open must create a fresh screen.
      service.pending.add(SharedFile(path: imagePath, mime: 'image/png'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OCR').last);
      await tester.pumpAndSettle();
      expect(paths, [imagePath, imagePath]);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  test(
    'redelivery after consumption or discard is acknowledged without requeuing',
    () async {
      nativeRows = [
        {'path': imagePath, 'mime': 'image/png'},
      ];
      await service.pullFromNative();
      service.takeFor('ai_ocr');
      await service.pullFromNative();
      expect(service.pending, isEmpty);
      service.discard();
      await service.pullFromNative();
      expect(service.pending, isEmpty);
      expect(acknowledged, [imagePath, imagePath, imagePath]);
    },
  );

  testWidgets('failed native copy stays visible and Review retries intake', (
    tester,
  ) async {
    nativeRows = [
      {
        'error':
            'Some shared files could not be imported. Tap Review to retry.',
      },
    ];
    await service.pullFromNative();
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: PendingShareBanner())),
    );
    expect(find.textContaining('could not be imported'), findsOneWidget);
    nativeRows = [
      {'path': imagePath, 'mime': 'image/png'},
    ];
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(service.intakeError.value, isNull);
    expect(service.pending.single.path, imagePath);
    await tester.tap(find.text('Keep for later'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'native delivery during an open chooser is picked up after dismissal',
    (tester) async {
      service.pending.add(file('first.pdf', 'application/pdf'));
      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: PendingShareBanner())),
      );
      unawaited(service.presentIfNeeded());
      await tester.pumpAndSettle();
      nativeRows = [
        {'path': imagePath, 'mime': 'image/png'},
      ];
      await service.presentIfNeeded();
      await tester.tap(find.text('Keep for later'));
      await tester.pumpAndSettle();
      expect(service.pending.map((f) => f.path), [
        file('first.pdf', '').path,
        imagePath,
      ]);
    },
  );

  testWidgets('leaving OCR during recognition does not update disposed state', (
    tester,
  ) async {
    final storage = MemoryStorage();
    Get.put(FavoritesService(storage));
    Get.put(HistoryService(storage));
    final result = Completer<Map<String, dynamic>>();
    messenger.setMockMethodCallHandler(ocrChannel, (call) async {
      if (call.method == 'vision#startTextRecognizer') return result.future;
      return null;
    });
    service.pending.add(SharedFile(path: imagePath, mime: 'image/png'));
    await tester.pumpWidget(const GetMaterialApp(home: OcrView()));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    result.complete({'text': 'Late result', 'blocks': []});
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
