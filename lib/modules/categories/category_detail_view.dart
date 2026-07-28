import 'package:flutter/material.dart';

import '../../data/catalog/tool_catalog.dart';
import '../../data/models/tool_model.dart';
import '../../widgets/tool_card.dart';

class CategoryDetailView extends StatelessWidget {
  const CategoryDetailView({super.key, required this.category});

  final ToolCategory category;

  @override
  Widget build(BuildContext context) {
    final tools = ToolCatalog.byCategory(category);

    return Scaffold(
      appBar: AppBar(
        title: Text(category.label),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: tools.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => ToolCard(tool: tools[index]),
      ),
    );
  }
}
