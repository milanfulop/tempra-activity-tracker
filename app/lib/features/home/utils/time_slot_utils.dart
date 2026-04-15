import '../../../shared/utils/api_service.dart';
import '../../../shared/models/time_slot.dart';

Future<void> saveSlots(List<TimeSlot> slots) async {
  final entries = _groupIntoEntries(slots);

  for (final entry in entries) {
    await ApiService.post('/entry', {
      'start_time': toTimeString(entry['start_time']),
      'end_time': toTimeString(entry['end_time']),
      'category': entry['category'],
    });
  }
}

Future<void> deleteSlots(List<TimeSlot> slots) async {
  final entries = _groupIntoEntries(slots);

  for (final entry in entries) {
    final start = toTimeString(entry['start_time']);
    final end = toTimeString(entry['end_time']);

    print('Deleting: $start → $end');

    await ApiService.delete(
      '/entry',
      body: {
        'start_time': start,
        'end_time': end,
      },
    );
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
      'start_time': slots[i].time,
      'end_time': slots[j - 1].time.add(const Duration(minutes: 15)),
      'category': slot.category,
    });

    i = j;
  }

  return entries;
}

String toTimeString(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  final s = time.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

int timeStringToCellIndex(String time) {
  final parts = time.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  final second = parts.length > 2 ? int.parse(parts[2]) : 0;
  if (hour == 23 && minute == 59 && second == 59) return 96;
  return (hour * 4) + (minute ~/ 15);
}