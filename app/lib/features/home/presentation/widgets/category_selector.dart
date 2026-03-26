import 'package:flutter/material.dart';
import '../../utils/category_utils.dart';
import '../../../../shared/models/category.dart';

class CategorySelector extends StatefulWidget {
  final Color selectedColor;
  final String selectedName;
  final ValueChanged<Category>? onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedColor,
    required this.selectedName,
    this.onCategorySelected,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  late Future<List<Category>> _categoriesFuture;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: SizedBox(
        width: screenWidth * 0.90,
        height: 100,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: widget.selectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.selectedName.isEmpty
                          ? 'Select a category'
                          : widget.selectedName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.selectedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Scrollable chip row ──────────────────────────────────
                Expanded(
                  child: FutureBuilder<List<Category>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Failed to load categories',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        );
                      }

                      final categories = snapshot.data ?? [];

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = _selectedId == cat.id;

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedId = cat.id);
                              widget.onCategorySelected?.call(cat);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cat.color
                                    : cat.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: cat.color,
                                  width: isSelected ? 0 : 1.2,
                                ),
                              ),
                              child: Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : cat.color,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}