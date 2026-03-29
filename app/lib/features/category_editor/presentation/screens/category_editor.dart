import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/category_list_element.dart';
import '../widgets/category_editor_panel.dart';
import '../../../../shared/provider/category_provider.dart';
import '../../../../shared/models/category.dart';

class CategoryEditorPage extends StatefulWidget {
  const CategoryEditorPage({super.key});

  @override
  State<CategoryEditorPage> createState() => _CategoryEditorPageState();
}

class _CategoryEditorPageState extends State<CategoryEditorPage> {
  @override
  void initState() {
    super.initState();
    // Fetch if not already loaded (e.g. deep-linked directly to this page)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CategoryProvider>();
      if (provider.categories.isEmpty && !provider.isLoading) {
        provider.fetch();
      }
    });
  }

  // ── Create ───────────────────────────────────────────────────────────────

  Future<void> _openCreatePanel() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CategoryEditorPanel(),
    );

    if (result != null && mounted) {
      context.read<CategoryProvider>().add(Category(
            id: result['id'] as String,
            name: result['name'] as String,
            color: result['color'] as Color,
            isProductive: result['isProductive'] as bool? ?? false,
          ));
    }
  }

  // ── Edit ─────────────────────────────────────────────────────────────────

  void _onCategoryEdited(String categoryId, Map<String, dynamic> result) {
    context.read<CategoryProvider>().update(Category(
          id: categoryId,
          name: result['name'] as String,
          color: result['color'] as Color,
          isProductive: result['isProductive'] as bool? ?? false,
        ));
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  void _onCategoryDeleted(String categoryId) {
    context.read<CategoryProvider>().delete(categoryId);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category editor'),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Failed to load: ${provider.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: provider.fetch,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final categories = provider.categories;

          return ListView.builder(
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index < categories.length) {
                final category = categories[index];
                return CategoryListElement(
                  key: ValueKey(category.id),
                  name: category.name,
                  color: category.color,
                  categoryId: category.id,
                  isProductive: category.isProductive,
                  onEdited: (result) => _onCategoryEdited(category.id, result),
                  onDelete: () => _onCategoryDeleted(category.id),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _openCreatePanel,
                    child: const Text('Create new category'),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}