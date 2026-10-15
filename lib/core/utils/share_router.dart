class ShareKind {
  static const pdf = 'pdf';
  static const image = 'image';
  static const other = 'other';
}

String shareKind(String mime) {
  final m = mime.toLowerCase();
  if (m == 'application/pdf' || m.endsWith('/pdf')) return ShareKind.pdf;
  if (m.startsWith('image/')) return ShareKind.image;
  return ShareKind.other;
}

/// Suggested tool ids, first is the default.
List<String> suggestedToolIds(Iterable<String> mimes) {
  var pdf = 0;
  var image = 0;
  for (final m in mimes) {
    final k = shareKind(m);
    if (k == ShareKind.pdf) pdf++;
    if (k == ShareKind.image) image++;
  }
  if (pdf == 0 && image == 0) return const [];
  if (pdf > 0 && image == 0) return const ['pdf_merge'];
  if (image > 0 && pdf == 0) {
    if (image == 1) return const ['image_compress', 'images_to_pdf', 'ai_ocr'];
    return const ['images_to_pdf', 'image_compress'];
  }
  return const ['pdf_merge', 'images_to_pdf'];
}

/// Explicit input contracts prevent single-image tools dropping a batch.
bool acceptsSharedMime(String toolId, String mime) {
  final kind = shareKind(mime);
  return switch (toolId) {
    'pdf_merge' => kind == ShareKind.pdf,
    'image_compress' || 'images_to_pdf' || 'ai_ocr' => kind == ShareKind.image,
    _ => false,
  };
}

int sharedInputLimit(String toolId) => switch (toolId) {
  'image_compress' || 'ai_ocr' => 1,
  'pdf_merge' || 'images_to_pdf' => 0x7fffffff,
  _ => 0,
};
