import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/catalog/tool_catalog.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          decoration: const InputDecoration(
            hintText: 'Search tools…',
            border: InputBorder.none,
            filled: false,
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
          return _RecentSearches(
            searches: _history.recentSearches.toList(),
            onSelect: (s) {
              _controller.text = s;
              _query.value = s;
              _history.addSearch(s);
            },
            onClear: () => _history.clearRecentSearches(),
          );
        }

        final results = ToolCatalog.search(q);
        if (results.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No tools found',
            message: 'Nothing matched "$q". Try another keyword.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: results.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tool = results[index];
            return ToolCard(tool: tool);
          },
        );
      }),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.searches,
    required this.onSelect,
    required this.onClear,
  });

  final List<String> searches;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (searches.isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'Search tools',
        message: 'Try "pdf", "qr", "compress", "json", or "uuid".',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searches
                .map(
                  (s) => ActionChip(
                    label: Text(s),
                    onPressed: () => onSelect(s),
                    avatar: const Icon(Icons.history_rounded, size: 16),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
