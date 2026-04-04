import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/time_slot_provider.dart';
import '../widgets/time_grid.dart';
import '../widgets/category_selector.dart';
import '../../../../shared/provider/category_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimeSlotProvider(),
      child: const _HomePageContent(),
    );
  }
}

class _HomePageContent extends StatefulWidget {
  const _HomePageContent();

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent> {
  final _scrollController = ScrollController();
  Color _selectedCategoryColor = Colors.blue;
  String _selectedCategoryName = '';
  static const double _categorySelectorBottomOffset = 24.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final categoryProvider = context.read<CategoryProvider>();
      final timeSlotProvider = context.read<TimeSlotProvider>();
      await categoryProvider.fetch();
      await timeSlotProvider.loadSlots(categoryProvider.categories);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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

          const selectorHeight = 150.0;
          final listBottomPadding = showSelector
              ? (selectorHeight + _categorySelectorBottomOffset + safeBottomPadding)
              : 0.0;

          return Stack(
            children: [
              ListView(
                controller: _scrollController,
                physics: provider.isDragging
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: listBottomPadding),
                children: [
                  SizedBox(height: screenHeight * 0.4),
                  TimeGrid(scrollController: _scrollController),
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
                      provider.applyActivity(
                        activity: '',
                        category: cat.id,
                        color: cat.color,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}