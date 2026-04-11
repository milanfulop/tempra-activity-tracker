import 'package:flutter/material.dart';
import '../../../../shared/models/time_slot.dart';
import './time_slot.dart';
import '../../../shared/models/category.dart';
import '../utils/time_slot_utils.dart';

class TimeSlotProvider extends ChangeNotifier {
  final TimeSlotRepository _repository = TimeSlotRepository();

  List<TimeSlot> slots = [];
  Map<int, Color?> cellColorMap = {};
  Set<int> selectedIndices = {};
  bool isDragging = false;
  int? dragStartIndex;

  TimeSlotProvider();

  // ─── Map builder ─────────────────────────────────────────────────────────

  void _rebuildMap() {
    cellColorMap = {
      for (final slot in slots)
        if (slot.color != null) slot.index: slot.color,
    };
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadSlots(List<Category> categories) async {
    slots = await _repository.fetchSlots(DateTime.now(), categories);
    _rebuildMap();
    notifyListeners();
  }

  // ─── Selection ────────────────────────────────────────────────────────────

  void onDragStart(int index) {
    isDragging = true;
    dragStartIndex = index;
    selectedIndices = {index};
    notifyListeners();
  }

  void onDragUpdate(int index) {
    if (!isDragging || dragStartIndex == null) return;
    final lo = dragStartIndex! < index ? dragStartIndex! : index;
    final hi = dragStartIndex! < index ? index : dragStartIndex!;
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

  // ─── Edit ─────────────────────────────────────────────────────────────────

void applyActivity({
  required String activity,
  required String category,
  required Color color,
}) {
    final currentSelection = Set<int>.from(selectedIndices);
    
    for (final i in currentSelection) {
      slots[i] = slots[i].copyWith(
        activity: activity,
        category: category,
        color: color,
      );
    }

    _rebuildMap();
    
    final selectedSlots = currentSelection.map((i) => slots[i]).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    saveSlots(selectedSlots);
    
    clearSelection();
    notifyListeners();
  }
  Future<void> deleteSelected() async {
    final currentSelection = Set<int>.from(selectedIndices);

    // Get slots BEFORE clearing them (needed for API)
    final selectedSlots = currentSelection.map((i) => slots[i]).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    await deleteSlots(selectedSlots);

    for (final i in currentSelection) {
      slots[i] = slots[i].copyWith(
        activity: null,
        category: null,
        color: null,
      );
    }

    _rebuildMap();

    clearSelection();

    notifyListeners();
  }
}