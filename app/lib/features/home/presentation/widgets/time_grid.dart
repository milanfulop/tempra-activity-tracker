import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/time_slot_provider.dart';
import '../widgets/time_slot_cell.dart';
// import '../widgets/activity_bottom_sheet.dart';

class TimeGrid extends StatefulWidget {
  final ScrollController scrollController;

  const TimeGrid({super.key, required this.scrollController});

  @override
  State<TimeGrid> createState() => _TimeGridState();
}

class _TimeGridState extends State<TimeGrid> {
  double _cellHeight = 0;
  double _cellWidth = 0;

  static const int _crossAxisCount = 4;
  static const double _spacing = 4.0;
  static const double _aspectRatio = 1.4;
  static const double _widthFactor = 0.65;

  void _openBottomSheet() {
    /*final provider = context.read<TimeSlotProvider>();
    if (provider.selectedIndices.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const ActivityBottomSheet(),
      ),
    ).then((_) {
      // clear selection if user dismisses without saving
      if (provider.selectedIndices.isNotEmpty) {
        provider.clearSelection();
      }
    });*/
  }

  int _getIndexFromOffset(Offset localPosition) {
    // localPosition is already in the grid's coordinate space (Listener child).
    final adjustedY = localPosition.dy;
    final col = (localPosition.dx / (_cellWidth + _spacing))
        .floor()
        .clamp(0, _crossAxisCount - 1);
    final row = (adjustedY / (_cellHeight + _spacing)).floor();
    final provider = context.read<TimeSlotProvider>();
    return (row * _crossAxisCount + col).clamp(0, provider.slots.length - 1);
  }

  void _handleEdgeScroll(Offset globalPosition) {
    final screenHeight = MediaQuery.of(context).size.height;
    const edgeThreshold = 80.0;
    const scrollSpeed = 6.0;

    if (globalPosition.dy < edgeThreshold) {
      widget.scrollController.animateTo(
        (widget.scrollController.offset - scrollSpeed).clamp(0, double.infinity),
        duration: const Duration(milliseconds: 16),
        curve: Curves.linear,
      );
    } else if (globalPosition.dy > screenHeight - edgeThreshold) {
      widget.scrollController.animateTo(
        widget.scrollController.offset + scrollSpeed,
        duration: const Duration(milliseconds: 16),
        curve: Curves.linear,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimeSlotProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth * _widthFactor;
        _cellWidth =
            (gridWidth - _spacing * (_crossAxisCount - 1)) / _crossAxisCount;
        _cellHeight = _cellWidth / _aspectRatio;

        return Center(
          child: FractionallySizedBox(
            widthFactor: _widthFactor,
            child: Listener(
              onPointerDown: (e) {
                final index = _getIndexFromOffset(e.localPosition);
                provider.onDragStart(index);
              },
              onPointerMove: (e) {
                if (provider.isDragging) {
                  final index = _getIndexFromOffset(e.localPosition);
                  provider.onDragUpdate(index);
                  _handleEdgeScroll(e.position);
                }
              },
              onPointerUp: (_) {
                provider.onDragEnd();
                _openBottomSheet();
              },
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), 
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  childAspectRatio: _aspectRatio,
                  crossAxisSpacing: _spacing,
                  mainAxisSpacing: _spacing,
                ),
                itemCount: provider.slots.length,
                itemBuilder: (context, index) => TimeSlotCell(
                  slot: provider.slots[index],
                  isSelected: provider.selectedIndices.contains(index),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}