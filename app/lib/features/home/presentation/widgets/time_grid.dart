import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/time_slot_provider.dart';
import '../widgets/time_slot_cell.dart';

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
  static const double _spacing = 8.0;
  static const double _aspectRatio = 1.0;
  static const double _labelColumnWidth = 36.0;

  static const _minuteLabels = [':00', ':15', ':30', ':45'];

  int _getIndexFromOffset(Offset localPosition) {
    final col = (localPosition.dx / (_cellWidth + _spacing))
        .floor()
        .clamp(0, _crossAxisCount - 1);
    final row = (localPosition.dy / (_cellHeight + _spacing)).floor();
    final provider = context.read<TimeSlotProvider>();
    return (row * _crossAxisCount + col).clamp(0, provider.slots.length - 1);
  }

  void _handleEdgeScroll(Offset globalPosition) {
    final screenHeight = MediaQuery.of(context).size.height;
    const edgeThreshold = 80.0;
    const scrollSpeed = 6.0;

    if (globalPosition.dy < edgeThreshold) {
      widget.scrollController.animateTo(
        (widget.scrollController.offset - scrollSpeed)
            .clamp(0, double.infinity),
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
    final totalRows = (provider.slots.length / _crossAxisCount).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        _cellWidth = (constraints.maxWidth -
                (_labelColumnWidth * 2) -
                _spacing * (_crossAxisCount - 1)) /
            _crossAxisCount;
        _cellHeight = _cellWidth / _aspectRatio;

        return Column(
          children: [
            // ── minute header row ────────────────────────────────────
            Row(
              children: [
                SizedBox(width: _labelColumnWidth),
                ...List.generate(
                  _crossAxisCount,
                  (i) => Expanded(
                    child: Center(
                      child: Text(
                        _minuteLabels[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.35),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: _labelColumnWidth),
              ],
            ),
            const SizedBox(height: 6),

            // ── grid with hour labels ────────────────────────────────
            Listener(
              onPointerDown: (e) {
                final localOffset = Offset(
                    e.localPosition.dx - _labelColumnWidth,
                    e.localPosition.dy);
                final index = _getIndexFromOffset(localOffset);
                provider.onDragStart(index);
              },
              onPointerMove: (e) {
                if (provider.isDragging) {
                  final localOffset = Offset(
                      e.localPosition.dx - _labelColumnWidth,
                      e.localPosition.dy);
                  final index = _getIndexFromOffset(localOffset);
                  provider.onDragUpdate(index);
                  _handleEdgeScroll(e.position);
                }
              },
              onPointerUp: (_) => provider.onDragEnd(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── hour labels ────────────────────────────────────
                  SizedBox(
                    width: _labelColumnWidth,
                    child: Column(
                      children: List.generate(totalRows, (row) {
                        final showLabel = row % 4 == 0;
                        final isLastRow = row == totalRows - 1;
                        return SizedBox(
                          height: _cellHeight + (isLastRow ? 0 : _spacing),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: showLabel
                                ? Text(
                                    '${row}h',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.35),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }),
                    ),
                  ),

                  // ── grid cells ─────────────────────────────────────
                  Expanded(
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
                        color: provider.cellColorMap[index],
                        isSelected: provider.selectedIndices.contains(index),
                      ),
                    ),
                  ),

                  // ── balancing spacer ───────────────────────────────
                  SizedBox(width: _labelColumnWidth),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}