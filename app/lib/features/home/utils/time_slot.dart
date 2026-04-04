import 'package:flutter/material.dart';
import 'package:tempra/shared/utils/api_service.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/time_slot.dart';

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
        final startIndex = _timeStringToCellIndex(startRaw);
        final endIndex = _timeStringToCellIndex(endRaw);
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

  Future<void> saveSlots(List<TimeSlot> slots) async {
    final entries = _groupIntoEntries(slots);
    for (final entry in entries) {
      await ApiService.post('/entry', entry);
    }
  }

  List<Map<String, dynamic>> _groupIntoEntries(List<TimeSlot> slots) {
    final entries = <Map<String, dynamic>>[];
    int i = 0;
    while (i < slots.length) {
      final slot = slots[i];
      if (slot.category == null) {
        i++;
        continue;
      }
      int j = i + 1;
      while (j < slots.length && slots[j].category == slot.category) {
        j++;
      }
      entries.add({
        'start_time': _toTimeString(slots[i].time),
        'end_time': _toTimeString(slots[j - 1].time.add(const Duration(minutes: 15))),
        'category': slot.category,
      });
      i = j;
    }
    return entries;
  }

  int _timeStringToCellIndex(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return (hour * 4) + (minute ~/ 15);
  }

  String _toTimeString(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
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