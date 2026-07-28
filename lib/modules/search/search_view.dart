import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/catalog/tool_catalog.dart';
import '../../data/models/tool_model.dart';
import '../../data/services/history_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tool_card.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _query = ''.obs;
  final _history = Get.find<HistoryService>();

  static const _suggestions = [
    'PDF',
    'Compress',
    'QR',
    'HEIC',
    'OCR',
    'ZIP',
    'JSON',
    'UUID',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _apply(String value) {
    _controller.text = value;
    _query.value = value;
    _history.addSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.brightness == Brightness.dark
        ? AppColors.fillDark
        : AppColors.fillLight;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CupertinoSearchTextField(
            controller: _controller,
            focusNode: _focus,
            placeholder: 'Search',
            backgroundColor: fill,
            borderRadius: BorderRadius.circular(12),
            style: theme.textTheme.bodyLarge,
            onChanged: (v) => _query.value = v,
            onSubmitted: (v) => _history.addSearch(v),
          ),
        ),
      ),
      body: Obx(() {
        final q = _query.value.trim();
        if (q.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                'Suggestions',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions
                    .map(
                      (s) => ActionChip(
                        label: Text(s),
                        onPressed: () => _apply(s),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
              if (_history.recentSearches.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Recents',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _history.clearRecentSearches,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                Material(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(AppSpace.radius),
                  child: Column(
                    children: [
                      for (var i = 0; i < _history.recentSearches.length; i++) ...[
                        if (i > 0) const Divider(height: 0.5, indent: 52),
                        ListTile(
                          leading: Icon(
                            Icons.history_rounded,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          title: Text(_history.recentSearches[i]),
                          trailing: Icon(
                            Icons.north_west_rounded,
                            size: 18,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          onTap: () => _apply(_history.recentSearches[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Popular',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(AppSpace.radius),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final t in ToolCatalog.recommended.take(5))
                      ToolCard(tool: t, compact: true),
                  ],
                ),
              ),
            ],
          );
        }

        final results = ToolCatalog.search(q);
        if (results.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No Results',
            message: 'Nothing matched "$q".',
          );
        }

        final byCat = <ToolCategory, List<ToolModel>>{};
        for (final t in results) {
          byCat.putIfAbsent(t.category, () => []).add(t);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            for (final entry in byCat.entries) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Text(
                  entry.key.label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Material(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(AppSpace.radius),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < entry.value.length; i++) ...[
                      if (i > 0) const Divider(height: 0.5, indent: 58),
                      ToolCard(tool: entry.value[i], compact: true),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
