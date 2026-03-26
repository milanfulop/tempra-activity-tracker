import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/time_slot_provider.dart';
import '../widgets/time_grid.dart';
import '../widgets/category_selector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();   // ← owned here now

  Color _selectedCategoryColor = Colors.blue;
  String _selectedCategoryName = '';

  static const double _categorySelectorBottomOffset = 24.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ChangeNotifierProvider(
      create: (_) => TimeSlotProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Today'),
          actions: [
            Consumer<TimeSlotProvider>(
              builder: (context, provider, _) {
                if (provider.selectedIndices.isEmpty) return const SizedBox();
                return TextButton(
                  onPressed: provider.clearSelection,
                  child: const Text('Cancel'),
                );
              },
            ),
          ],
        ),
        body: Consumer<TimeSlotProvider>(
          builder: (context, provider, _) {
            final safeBottomPadding = MediaQuery.of(context).padding.bottom;
            final showSelector =
                provider.selectedIndices.isNotEmpty && !provider.isDragging;

            // Leave space at the end of the scroll so the fixed selector doesn't
            // cover the bottom of the grid.
            const selectorHeight = 150.0;
            final listBottomPadding =
                showSelector ? (selectorHeight + _categorySelectorBottomOffset + safeBottomPadding) : 0.0;

            return Stack(
              children: [
                ListView(
                  controller: _scrollController, // ← attached here
                  physics: provider.isDragging
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: listBottomPadding),
                  children: [
                    SizedBox(height: screenHeight * 0.4),
                    TimeGrid(scrollController: _scrollController), // ← passed down
                    SizedBox(height: screenHeight * 0.4),
                  ],
                ),
                if (showSelector)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _categorySelectorBottomOffset + safeBottomPadding,
                    child: CategorySelector(
                      selectedColor: _selectedCategoryColor,
                      selectedName: _selectedCategoryName,
                      onCategorySelected: (cat) {
                        setState(() {
                          _selectedCategoryColor = cat.color;
                          _selectedCategoryName = cat.name;
                        });
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}