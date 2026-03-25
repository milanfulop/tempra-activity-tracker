import '../../../shared/models/time_slot.dart';

class TimeSlotRepository {
  final String baseUrl = 'https://your-api.com'; // replace with your base URL

  // stub — replace body with your actual http calls
  Future<List<TimeSlot>> fetchSlots(DateTime date) async {
    // example:
    // final response = await http.get(Uri.parse('$baseUrl/slots?date=$date'));
    // final data = jsonDecode(response.body) as List;
    // return data.map((e) => TimeSlot.fromJson(e)).toList();

    // returns empty slots for now — your API will fill these
    return _generateEmptySlots();
  }

  Future<void> saveSlots(List<TimeSlot> slots) async {
    // example:
    // await http.post(Uri.parse('$baseUrl/slots'),
    //   body: jsonEncode(slots.map((s) => s.toJson()).toList()));
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