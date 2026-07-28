import 'package:get/get.dart';

import '../../data/models/tool_model.dart';
import '../../data/services/favorites_service.dart';
import '../../data/services/history_service.dart';
import '../../modules/categories/category_detail_view.dart';
import '../../modules/search/search_view.dart';
import '../../modules/shell/shell_binding.dart';
import '../../modules/shell/shell_view.dart';
import '../../modules/tools/coming_soon_view.dart';
import '../../modules/tools/ai/ocr_view.dart';
import '../../modules/tools/ai/summarize_view.dart';
import '../../modules/tools/ai/translate_view.dart';
import '../../modules/tools/developer/color_converter_view.dart';
import '../../modules/tools/developer/http_status_view.dart';
import '../../modules/tools/developer/jwt_decoder_view.dart';
import '../../modules/tools/developer/mime_types_view.dart';
import '../../modules/tools/developer/timestamp_view.dart';
import '../../modules/tools/developer/uuid_generator_view.dart';
import '../../modules/tools/documents/csv_json_view.dart';
import '../../modules/tools/documents/yaml_json_view.dart';
import '../../modules/tools/files/duplicate_finder_view.dart';
import '../../modules/tools/files/file_checksum_view.dart';
import '../../modules/tools/files/zip_tool_view.dart';
import '../../modules/tools/images/background_remove_view.dart';
import '../../modules/tools/images/color_picker_view.dart';
import '../../modules/tools/images/image_compress_view.dart';
import '../../modules/tools/images/image_crop_view.dart';
import '../../modules/tools/images/image_format_convert_view.dart';
import '../../modules/tools/images/image_metadata_view.dart';
import '../../modules/tools/images/image_resize_view.dart';
import '../../modules/tools/images/image_rotate_view.dart';
import '../../modules/tools/images/images_to_pdf_view.dart';
import '../../modules/tools/pdf/pdf_compress_view.dart';
import '../../modules/tools/pdf/pdf_delete_pages_view.dart';
import '../../modules/tools/pdf/pdf_extract_view.dart';
import '../../modules/tools/pdf/pdf_merge_view.dart';
import '../../modules/tools/pdf/pdf_organize_view.dart';
import '../../modules/tools/pdf/pdf_protect_view.dart';
import '../../modules/tools/pdf/pdf_rotate_view.dart';
import '../../modules/tools/pdf/pdf_split_view.dart';
import '../../modules/tools/pdf/pdf_to_images_view.dart';
import '../../modules/tools/pdf/pdf_unlock_view.dart';
import '../../modules/tools/pdf/pdf_watermark_view.dart';
import '../../modules/tools/scanner/document_scanner_view.dart';
import '../../modules/tools/qr/contact_qr_view.dart';
import '../../modules/tools/qr/email_qr_view.dart';
import '../../modules/tools/qr/qr_generate_view.dart';
import '../../modules/tools/qr/qr_scan_view.dart';
import '../../modules/tools/qr/wifi_qr_view.dart';
import '../../modules/tools/text/base64_view.dart';
import '../../modules/tools/text/case_converter_view.dart';
import '../../modules/tools/text/diff_checker_view.dart';
import '../../modules/tools/text/hash_generator_view.dart';
import '../../modules/tools/text/json_formatter_view.dart';
import '../../modules/tools/text/lorem_ipsum_view.dart';
import '../../modules/tools/text/markdown_preview_view.dart';
import '../../modules/tools/text/regex_tester_view.dart';
import '../../modules/tools/text/url_encoder_view.dart';
import '../../modules/tools/text/word_counter_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.shell,
      page: () => const ShellView(),
      binding: ShellBinding(),
    ),
    GetPage(name: AppRoutes.search, page: () => const SearchView()),
    GetPage(
      name: AppRoutes.categoryDetail,
      page: () => CategoryDetailView(category: Get.arguments as ToolCategory),
    ),
    GetPage(name: AppRoutes.comingSoon, page: () => const ComingSoonView()),

    // Text
    GetPage(name: AppRoutes.wordCounter, page: () => const WordCounterView()),
    GetPage(name: AppRoutes.caseConverter, page: () => const CaseConverterView()),
    GetPage(name: AppRoutes.loremIpsum, page: () => const LoremIpsumView()),
    GetPage(name: AppRoutes.jsonFormatter, page: () => const JsonFormatterView()),
    GetPage(name: AppRoutes.base64, page: () => const Base64View()),
    GetPage(name: AppRoutes.hashGenerator, page: () => const HashGeneratorView()),
    GetPage(name: AppRoutes.urlEncoder, page: () => const UrlEncoderView()),
    GetPage(name: AppRoutes.diffChecker, page: () => const DiffCheckerView()),
    GetPage(
      name: AppRoutes.markdownPreview,
      page: () => const MarkdownPreviewView(),
    ),
    GetPage(name: AppRoutes.regexTester, page: () => const RegexTesterView()),

    // Documents
    GetPage(name: AppRoutes.csvJson, page: () => const CsvJsonView()),
    GetPage(name: AppRoutes.yamlJson, page: () => const YamlJsonView()),

    // QR
    GetPage(name: AppRoutes.qrGenerate, page: () => const QrGenerateView()),
    GetPage(name: AppRoutes.qrScan, page: () => const QrScanView()),
    GetPage(name: AppRoutes.wifiQr, page: () => const WifiQrView()),
    GetPage(name: AppRoutes.contactQr, page: () => const ContactQrView()),
    GetPage(name: AppRoutes.emailQr, page: () => const EmailQrView()),

    // Images
    GetPage(name: AppRoutes.imageCompress, page: () => const ImageCompressView()),
    GetPage(name: AppRoutes.imageResize, page: () => const ImageResizeView()),
    GetPage(name: AppRoutes.imageRotate, page: () => const ImageRotateView()),
    GetPage(name: AppRoutes.imagesToPdf, page: () => const ImagesToPdfView()),
    GetPage(name: AppRoutes.heicConvert, page: () => const HeicConvertView()),
    GetPage(name: AppRoutes.webpConvert, page: () => const WebpConvertView()),
    GetPage(name: AppRoutes.imageCrop, page: () => const ImageCropView()),
    GetPage(name: AppRoutes.colorPicker, page: () => const ColorPickerView()),
    GetPage(name: AppRoutes.imageMetadata, page: () => const ImageMetadataView()),
    GetPage(name: AppRoutes.bgRemove, page: () => const BackgroundRemoveView()),

    // PDF
    GetPage(name: AppRoutes.pdfMerge, page: () => const PdfMergeView()),
    GetPage(name: AppRoutes.pdfToImages, page: () => const PdfToImagesView()),
    GetPage(name: AppRoutes.pdfSplit, page: () => const PdfSplitView()),
    GetPage(name: AppRoutes.pdfCompress, page: () => const PdfCompressView()),
    GetPage(name: AppRoutes.pdfProtect, page: () => const PdfProtectView()),
    GetPage(name: AppRoutes.pdfUnlock, page: () => const PdfUnlockView()),
    GetPage(name: AppRoutes.pdfRotate, page: () => const PdfRotateView()),
    GetPage(name: AppRoutes.docScanner, page: () => const DocumentScannerView()),
    GetPage(name: AppRoutes.pdfWatermark, page: () => const PdfWatermarkView()),
    GetPage(name: AppRoutes.pdfExtract, page: () => const PdfExtractView()),
    GetPage(name: AppRoutes.pdfDeletePages, page: () => const PdfDeletePagesView()),
    GetPage(name: AppRoutes.pdfOrganize, page: () => const PdfOrganizeView()),

    // Files
    GetPage(name: AppRoutes.zipTool, page: () => const ZipToolView()),
    GetPage(name: AppRoutes.checksum, page: () => const FileChecksumView()),
    GetPage(name: AppRoutes.duplicateFinder, page: () => const DuplicateFinderView()),

    // AI
    GetPage(name: AppRoutes.ocr, page: () => const OcrView()),
    GetPage(name: AppRoutes.translate, page: () => const TranslateView()),
    GetPage(name: AppRoutes.summarize, page: () => const SummarizeView()),

    // Developer
    GetPage(name: AppRoutes.jwtDecoder, page: () => const JwtDecoderView()),
    GetPage(name: AppRoutes.uuidGenerator, page: () => const UuidGeneratorView()),
    GetPage(
      name: AppRoutes.colorConverter,
      page: () => const ColorConverterView(),
    ),
    GetPage(name: AppRoutes.timestamp, page: () => const TimestampView()),
    GetPage(name: AppRoutes.httpStatus, page: () => const HttpStatusView()),
    GetPage(name: AppRoutes.mimeTypes, page: () => const MimeTypesView()),
  ];
}

/// Opens a tool and records it in recent history.
Future<void> openTool(ToolModel tool) async {
  final history = Get.find<HistoryService>();
  await history.recordToolOpen(tool.id);

  if (!tool.isAvailable || tool.route == AppRoutes.comingSoon) {
    Get.toNamed(AppRoutes.comingSoon, arguments: tool);
    return;
  }
  Get.toNamed(tool.route, arguments: tool);
}

void toggleFavorite(ToolModel tool) {
  Get.find<FavoritesService>().toggleFavorite(tool.id);
}
