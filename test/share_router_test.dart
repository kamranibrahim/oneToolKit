import 'package:flutter_test/flutter_test.dart';
import 'package:one_toolkit/core/utils/share_router.dart';

void main() {
  group('suggestedToolIds', () {
    test('empty mimes yields empty list', () {
      expect(suggestedToolIds(const []), isEmpty);
    });

    test('one application/pdf suggests pdf_merge', () {
      expect(suggestedToolIds(const ['application/pdf']), ['pdf_merge']);
    });

    test('two PDFs suggest pdf_merge', () {
      expect(
        suggestedToolIds(const ['application/pdf', 'application/pdf']),
        ['pdf_merge'],
      );
    });

    test('one image/jpeg prefers compress then images_to_pdf and ocr', () {
      final ids = suggestedToolIds(const ['image/jpeg']);
      expect(ids.first, 'image_compress');
      expect(ids, contains('images_to_pdf'));
      expect(ids, contains('ai_ocr'));
    });

    test('two image/png prefers images_to_pdf and omits ocr', () {
      final ids = suggestedToolIds(const ['image/png', 'image/png']);
      expect(ids.first, 'images_to_pdf');
      expect(ids, isNot(contains('ai_ocr')));
    });

    test('mixed pdf and image suggests merge and images_to_pdf', () {
      expect(
        suggestedToolIds(const ['application/pdf', 'image/jpeg']),
        ['pdf_merge', 'images_to_pdf'],
      );
    });

    test('text/plain only yields empty list', () {
      expect(suggestedToolIds(const ['text/plain']), isEmpty);
    });
  });
}
