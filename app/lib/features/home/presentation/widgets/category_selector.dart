import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../shared/provider/category_provider.dart';
import '../../../../shared/models/category.dart';
import '../../utils/time_slot_provider.dart';
import '../../utils/time_slot_utils.dart';

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
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    // Fetch only if the provider list is empty (avoids redundant network calls)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CategoryProvider>();
      if (provider.categories.isEmpty && !provider.isLoading) {
        provider.fetch();
      }
    });
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
                  child: Consumer<CategoryProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (provider.error != null) {
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

                      final categories = provider.categories;

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length + 2, // +1 for "uncategorized", +1 for "more"
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          // ─── 1. UNCATEGORIZED BUTTON ─────────────────────────────
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () async {
                              final provider = context.read<TimeSlotProvider>();

                              if (provider.selectedIndices.isEmpty) return;

                              try {
                                await provider.deleteSelected();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  'uncategorized',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }

                          // shift index because of "uncategorized"
                          final adjustedIndex = index - 1;

                          // ─── 2. MORE BUTTON ───────────────────────────────────────
                          if (adjustedIndex == categories.length) {
                            return GestureDetector(
                              onTap: () => context.push('/category-editor'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  'more',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }

                          // ─── 3. NORMAL CATEGORY ───────────────────────────────────
                          final cat = categories[adjustedIndex];
                          final isSelected = _selectedId == cat.id;

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedId = cat.id);
                              widget.onCategorySelected?.call(cat);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                                  color: isSelected ? Colors.white : cat.color,
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