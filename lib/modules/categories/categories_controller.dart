import 'package:get/get.dart';

import '../../data/models/tool_model.dart';

class CategoriesController extends GetxController {
  /// Everyday-first order (matches Home discovery).
  final categories = const [
    ToolCategory.pdf,
    ToolCategory.images,
    ToolCategory.ai,
    ToolCategory.qr,
    ToolCategory.files,
    ToolCategory.developer,
    ToolCategory.text,
    ToolCategory.documents,
  ];
}
