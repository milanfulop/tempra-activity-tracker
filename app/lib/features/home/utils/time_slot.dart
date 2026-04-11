import 'package:flutter/material.dart';
import 'package:tempra/shared/utils/api_service.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/time_slot.dart';
import '../utils/time_slot_utils.dart';

class TimeSlotRepository {
  Future<List<TimeSlot>> fetchSlots(DateTime date, List<Category> categories) async {
    final categoryColorMap = {
      for (final cat in categories) cat.id: cat.color,
    };

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final decoded = await ApiService.get('/entry?date=$dateStr');
      if (decoded is! List) return _generateEmptySlots();

      final slots = _generateEmptySlots();
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final startRaw = entry['start_time']?.toString();
        final endRaw = entry['end_time']?.toString();
        if (startRaw == null || endRaw == null) continue;
        final startIndex = timeStringToCellIndex(startRaw);
        final endIndex = timeStringToCellIndex(endRaw);
        if (startIndex < 0 || endIndex > 96 || startIndex >= endIndex) continue;
        final categoryId = entry['category_id']?.toString();
        final entryId = entry['id']?.toString();
        final color = categoryId != null ? categoryColorMap[categoryId] : null;

        for (int i = startIndex; i < endIndex; i++) {
          slots[i] = TimeSlot(
            index: i,
            time: slots[i].time,
            category: categoryId,
            activity: entryId,
            color: color,
          );
        }
      }
      return slots;
    } catch (e) {
      debugPrint('fetchSlots(): $e');
      return _generateEmptySlots();
    }
  }

  List<TimeSlot> _generateEmptySlots() {
    final slots = <TimeSlot>[];
    var time = DateTime(2024, 1, 1, 0, 0);
    int index = 0;
    while (index < 96) {
      slots.add(TimeSlot(index: index, time: time));
      time = time.add(const Duration(minutes: 15));
      index++;
    }
    return slots;
  }
}