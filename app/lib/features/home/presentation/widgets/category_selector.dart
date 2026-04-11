import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../shared/provider/category_provider.dart';
import '../../../../shared/models/category.dart';
import '../../utils/time_slot_provider.dart';

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
        height: 90,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.selectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.selectedName.isEmpty
                        ? 'select a category'
                        : widget.selectedName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.selectedName.isEmpty
                          ? Colors.white.withOpacity(0.3)
                          : widget.selectedColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── chip row ─────────────────────────────────────────────
              Expanded(
                child: Consumer<CategoryProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      );
                    }

                    if (provider.error != null) {
                      return Center(
                        child: Text(
                          'failed to load',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.withOpacity(0.7),
                          ),
                        ),
                      );
                    }

                    final categories = provider.categories;

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length + 2,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        // ── none button ──────────────────────────────
                        if (index == 0) {
                          return GestureDetector(
                            onTap: () async {
                              final p = context.read<TimeSlotProvider>();
                              if (p.selectedIndices.isEmpty) return;
                              try {
                                await p.deleteSelected();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            child: _Chip(
                              label: 'none',
                              color: Colors.white,
                              isSelected: false,
                            ),
                          );
                        }

                        final adjustedIndex = index - 1;

                        // ── more button ──────────────────────────────
                        if (adjustedIndex == categories.length) {
                          return GestureDetector(
                            onTap: () => context.push('/category-editor'),
                            child: _Chip(
                              label: '+ more',
                              color: Colors.white,
                              isSelected: false,
                            ),
                          );
                        }

                        // ── category chip ────────────────────────────
                        final cat = categories[adjustedIndex];
                        final isSelected = _selectedId == cat.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedId = cat.id);
                            widget.onCategorySelected?.call(cat);
                          },
                          child: _Chip(
                            label: cat.name,
                            color: cat.color,
                            isSelected: isSelected,
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
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;

  const _Chip({
    required this.label,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : color.withOpacity(0.6),
          width: isSelected ? 1.5 : 1.2,
        ),
      ),
      child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ),
    );
  }
}