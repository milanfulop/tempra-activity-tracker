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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CategoryProvider>();
      if (provider.categories.isEmpty && !provider.isLoading) {
        provider.fetch();
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ── Create ───────────────────────────────────────────────────────────────

  Future<void> _openCreatePanel() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CategoryEditorPanel(),
    );

    if (result == null || !mounted) return;

    try {
      await context.read<CategoryProvider>().add(Category(
            id: '',
            name: result['name'] as String,
            color: result['color'] as Color,
            isProductive: result['isProductive'] as bool? ?? false,
          ));
    } catch (e) {
      _showError('Failed to create category: $e');
    }
  }

  // ── Edit ─────────────────────────────────────────────────────────────────

  Future<void> _onCategoryEdited(
      String categoryId, Map<String, dynamic> result) async {
    try {
      await context.read<CategoryProvider>().update(Category(
            id: categoryId,
            name: result['name'] as String,
            color: result['color'] as Color,
            isProductive: result['isProductive'] as bool? ?? false,
          ));
    } catch (e) {
      _showError('Failed to update category: $e');
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  Future<void> _onCategoryDeleted(String categoryId) async {
    try {
      await context.read<CategoryProvider>().delete(categoryId);
    } catch (e) {
      _showError('Failed to delete category: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category editor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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