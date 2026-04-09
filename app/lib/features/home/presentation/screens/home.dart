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
  double _scrollOffset = 0;
  static const double _categorySelectorBottomOffset = 24.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
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
      backgroundColor: const Color(0xFF12121A), // dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Today',
            style: TextStyle(color: Colors.white70)),
        actions: [
          Consumer<TimeSlotProvider>(
            builder: (context, provider, _) {
              if (provider.selectedIndices.isEmpty) return const SizedBox();
              return TextButton(
                onPressed: provider.clearSelection,
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70)),
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
                  SizedBox(height: screenHeight * 0.4), // empty, no watermark here
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: TimeGrid(scrollController: _scrollController),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.4),
                ],
              ),

              // watermark — fixed position, fades as user scrolls
              Positioned(
                top: screenHeight * 0.15,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: (1 - (_scrollOffset / (screenHeight * 0.25))).clamp(0.0, 1.0),
                    child: Text(
                      'Tempra',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.06),
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
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