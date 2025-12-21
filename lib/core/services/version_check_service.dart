import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheckService {
  static const String _versionUrl = '/version.json';

  Future<bool> checkUpdateAvailable() async {
    // Only meaningful on web where we can hot-reload/refresh
    if (!kIsWeb) return false;

    try {
      // 1. Get current running version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;

      debugPrint('Local Version: $currentVersion+$currentBuildNumber');

      // 2. Fetch remote version.json
      // Add timestamp to prevent caching of the version check itself
      final response = await http.get(Uri.parse('$_versionUrl?t=${DateTime.now().millisecondsSinceEpoch}'));

      if (response.statusCode == 200) {
        debugPrint('Remote Config: ${response.body}');
        final Map<String, dynamic> remoteConfig = json.decode(response.body);
        final String remoteVersion = remoteConfig['version'] ?? '1.0.0';
        final String remoteBuildNumber = remoteConfig['build_number'] ?? '0';

        // 3. Compare
        if (_isNewer(remoteVersion, remoteBuildNumber, currentVersion, currentBuildNumber)) {
          debugPrint('Update Available: Local: $currentVersion+$currentBuildNumber, Remote: $remoteVersion+$remoteBuildNumber');
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error checking version: $e');
    }
    return false;
  }

  bool _isNewer(String remoteVer, String remoteBuild, String localVer, String localBuild) {
    // Simple comparison logic
    if (remoteVer != localVer) return true;
    if (remoteBuild != localBuild) return true;
    return false;
  }
}
