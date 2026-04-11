import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StatsCacheService {
  static Future<File> _fileForDate(String date) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/stats_$date.json');
  }

  static Future<void> save(String date, Map<String, dynamic> json) async {
    final file = await _fileForDate(date);
    await file.writeAsString(jsonEncode(json));
  }

  static Future<Map<String, dynamic>?> load(String date) async {
    final file = await _fileForDate(date);
    if (!await file.exists()) return null;
    final contents = await file.readAsString();
    return jsonDecode(contents) as Map<String, dynamic>;
  }
}