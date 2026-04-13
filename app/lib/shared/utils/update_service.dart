import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';

class AppUpdateService {
  static const _releasesUrl =
      'https://github.com/milanfulop/tempra-activity-tracker/releases';

  static String get releasesUrl => _releasesUrl;

  // returns true if the app is up to date, false if an update is required.
static Future<bool> isUpToDate() async {
  final data = await ApiService.get('/config/version') as Map<String, dynamic>;
  final remoteVersion = data['version'] as String;

  final info = await PackageInfo.fromPlatform();
  final localVersion = info.version;

  return localVersion == remoteVersion;
}
}