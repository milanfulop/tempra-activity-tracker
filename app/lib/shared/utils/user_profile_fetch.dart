import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/utils/api_service.dart';

// used to persist [createdAt] on the statistics screen
class UserProfileService {
  static const _keyCreatedAt = 'profile_created_at';

  static Future<DateTime> getCreatedAt() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_keyCreatedAt);
    if (cached != null) {
      return DateTime.parse(cached);
    }

    //   GET /profile  →  { "created_at": "<ISO-8601 string>" }
    final data = await ApiService.get('/user') as Map<String, dynamic>;
    final createdAtStr = data['created_at'] as String;

    await prefs.setString(_keyCreatedAt, createdAtStr);

    return DateTime.parse(createdAtStr);
  }

  // call this on sign-out
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCreatedAt);
  }
}