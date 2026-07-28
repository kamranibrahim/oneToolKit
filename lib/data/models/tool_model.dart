import 'package:flutter/material.dart';

enum ToolCategory {
  pdf,
  images,
  documents,
  qr,
  text,
  developer,
  files,
  ai;

  String get label => switch (this) {
        ToolCategory.pdf => 'PDF',
        ToolCategory.images => 'Images',
        ToolCategory.documents => 'Documents',
        ToolCategory.qr => 'QR & Barcode',
        ToolCategory.text => 'Text Tools',
        ToolCategory.developer => 'Developer',
        ToolCategory.files => 'File Tools',
        ToolCategory.ai => 'AI Tools',
      };

  String get subtitle => switch (this) {
        ToolCategory.pdf => 'Merge, split, compress & more',
        ToolCategory.images => 'Compress, convert, edit',
        ToolCategory.documents => 'Word, Excel, Markdown & more',
        ToolCategory.qr => 'Generate & scan codes',
        ToolCategory.text => 'Count, convert, format',
        ToolCategory.developer => 'JWT, UUID, timestamps',
        ToolCategory.files => 'ZIP, rename, checksum',
        ToolCategory.ai => 'Coming soon',
      };

  IconData get icon => switch (this) {
        ToolCategory.pdf => Icons.picture_as_pdf_rounded,
        ToolCategory.images => Icons.image_rounded,
        ToolCategory.documents => Icons.description_rounded,
        ToolCategory.qr => Icons.qr_code_2_rounded,
        ToolCategory.text => Icons.text_fields_rounded,
        ToolCategory.developer => Icons.code_rounded,
        ToolCategory.files => Icons.folder_zip_rounded,
        ToolCategory.ai => Icons.auto_awesome_rounded,
      };

  Color get accent => switch (this) {
        ToolCategory.pdf => const Color(0xFFE11D48),
        ToolCategory.images => const Color(0xFF2563EB),
        ToolCategory.documents => const Color(0xFF7C3AED),
        ToolCategory.qr => const Color(0xFF059669),
        ToolCategory.text => const Color(0xFFD97706),
        ToolCategory.developer => const Color(0xFF0891B2),
        ToolCategory.files => const Color(0xFF64748B),
        ToolCategory.ai => const Color(0xFFDB2777),
      };
}

enum ToolStatus { available, comingSoon }

class ToolModel {
  const ToolModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.route,
    this.keywords = const [],
    this.aliases = const [],
    this.status = ToolStatus.available,
    this.isTrending = false,
    this.isRecommended = false,
  });

  final String id;
  final String name;
  final String description;
  final ToolCategory category;
  final IconData icon;
  final String route;
  final List<String> keywords;
  final List<String> aliases;
  final ToolStatus status;
  final bool isTrending;
  final bool isRecommended;

  bool get isAvailable => status == ToolStatus.available;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    if (description.toLowerCase().contains(q)) return true;
    if (category.label.toLowerCase().contains(q)) return true;
    if (keywords.any((k) => k.toLowerCase().contains(q))) return true;
    if (aliases.any((a) => a.toLowerCase().contains(q))) return true;
    return false;
  }
}
