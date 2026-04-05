import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class AppConfig {
  static const String _localIp = '192.168.100.104';
  static const String _port = '8000';
  static const String _apiPath = '/api';

  static String? _cachedBaseUrl;

  /// Mengembalikan baseUrl secara otomatis:
  /// - Emulator Android → http://10.0.2.2:8000/api
  /// - iOS Simulator    → http://localhost:8000/api
  /// - HP Fisik         → http://192.168.1.12:8000/api
  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final isEmulator = !androidInfo.isPhysicalDevice;
        _cachedBaseUrl = isEmulator
            ? 'http://10.0.2.2:$_port$_apiPath'
            : 'http://$_localIp:$_port$_apiPath';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final isSimulator = !iosInfo.isPhysicalDevice;
        _cachedBaseUrl = isSimulator
            ? 'http://localhost:$_port$_apiPath'
            : 'http://$_localIp:$_port$_apiPath';
      } else {
        _cachedBaseUrl = 'http://$_localIp:$_port$_apiPath';
      }
    } catch (e) {
      // Fallback ke IP fisik jika deteksi gagal
      _cachedBaseUrl = 'http://$_localIp:$_port$_apiPath';
    }

    return _cachedBaseUrl!;
  }

  /// Reset cache (berguna saat testing)
  static void resetCache() {
    _cachedBaseUrl = null;
  }
}
