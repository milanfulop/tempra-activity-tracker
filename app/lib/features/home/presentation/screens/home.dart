import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/time_slot_provider.dart';
import '../widgets/time_grid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();   // ← owned here now

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
            return ListView(
              controller: _scrollController,       // ← attached here
              physics: provider.isDragging
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: screenHeight * 0.4),
                TimeGrid(scrollController: _scrollController), // ← passed down
                SizedBox(height: screenHeight * 0.4),
              ],
            );
          },
        ),
      ),
    );
  }
}