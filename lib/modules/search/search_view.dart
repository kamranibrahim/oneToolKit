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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          decoration: const InputDecoration(
            hintText: 'Search everything',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textInputAction: TextInputAction.search,
          onChanged: (v) => _query.value = v,
          onSubmitted: (v) => _history.addSearch(v),
        ),
        actions: [
          Obx(() {
            if (_query.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: () {
                _controller.clear();
                _query.value = '';
              },
              icon: const Icon(Icons.close_rounded),
            );
          }),
        ],
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
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions
                    .map(
                      (s) => ActionChip(
                        label: Text(s),
                        avatar: const Icon(Icons.north_west_rounded, size: 14),
                        onPressed: () => _apply(s),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpace.lg),
              if (_history.recentSearches.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Recent',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _history.clearRecentSearches,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ..._history.recentSearches.map(
                  (s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded),
                    title: Text(s),
                    onTap: () => _apply(s),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              Text(
                'Popular',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              ...ToolCatalog.recommended.take(5).map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ToolCard(tool: t, compact: true),
                    ),
                  ),
            ],
          );
        }

        final results = ToolCatalog.search(q);
        if (results.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No tools found',
            message: 'Nothing matched "$q". Try PDF, QR, compress, or OCR.',
          );
        }

        // Group lightly by category for Photos-like organization feel.
        final byCat = <ToolCategory, List<ToolModel>>{};
        for (final t in results) {
          byCat.putIfAbsent(t.category, () => []).add(t);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              '${results.length} result${results.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final entry in byCat.entries) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  entry.key.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: entry.key.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...entry.value.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ToolCard(tool: t),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
