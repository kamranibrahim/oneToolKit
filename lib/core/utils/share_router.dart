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
