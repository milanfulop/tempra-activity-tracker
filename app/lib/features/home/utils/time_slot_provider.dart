import 'package:flutter/material.dart';
import '../../../../shared/models/time_slot.dart';
import './time_slot.dart';

class TimeSlotProvider extends ChangeNotifier {
  final TimeSlotRepository _repository = TimeSlotRepository();

  List<TimeSlot> slots = [];
  Set<int> selectedIndices = {};
  bool isDragging = false;
  int? dragStartIndex;

  TimeSlotProvider() {
    loadSlots();
  }

  // ─── Load ────────────────────────────────────────────────────────────────
  Future<void> loadSlots() async {
    slots = await _repository.fetchSlots(DateTime.now());
    notifyListeners();
  }

  // ─── Selection ───────────────────────────────────────────────────────────
  void onDragStart(int index) {
    isDragging = true;
    dragStartIndex = index;
    selectedIndices = {index};
    notifyListeners();
  }

  void onDragUpdate(int index) {
    if (!isDragging || dragStartIndex == null) return;
    final start = dragStartIndex!;
    final end = index;
    final lo = start < end ? start : end;
    final hi = start < end ? end : start;
    selectedIndices = Set.from(List.generate(hi - lo + 1, (i) => lo + i));
    notifyListeners();
  }

  void onDragEnd() {
    isDragging = false;
    notifyListeners();
  }

  void clearSelection() {
    selectedIndices.clear();
    dragStartIndex = null;
    notifyListeners();
  }

  // ─── Edit ────────────────────────────────────────────────────────────────
  void applyActivity({
    required String activity,
    required String category,
    required Color color,
  }) {
    for (final i in selectedIndices) {
      slots[i] = slots[i].copyWith(
        activity: activity,
        category: category,
        color: color,
      );
    }
    _repository.saveSlots(slots); // fire and forget — add error handling as needed
    clearSelection();
    notifyListeners();
  }
}