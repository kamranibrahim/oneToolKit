import 'package:flutter_test/flutter_test.dart';
import 'package:one_toolkit/data/catalog/tool_catalog.dart';
import 'package:one_toolkit/data/models/tool_model.dart';

void main() {
  group('ToolCatalog', () {
    test('contains Phase 1 tools across categories', () {
      expect(ToolCatalog.all, isNotEmpty);
      expect(ToolCatalog.available, isNotEmpty);
      expect(ToolCatalog.byCategory(ToolCategory.pdf), isNotEmpty);
      expect(ToolCatalog.byCategory(ToolCategory.qr), isNotEmpty);
      expect(ToolCatalog.byCategory(ToolCategory.text), isNotEmpty);
    });

    test('search finds tools by name and keyword', () {
      expect(ToolCatalog.search('qr'), isNotEmpty);
      expect(ToolCatalog.search('json'), isNotEmpty);
      expect(ToolCatalog.search('zzzz-no-match'), isEmpty);
    });

    test('byId returns registered tools', () {
      expect(ToolCatalog.byId('word_counter')?.name, 'Word Counter');
      expect(ToolCatalog.byId('missing'), isNull);
    });
  });
}
