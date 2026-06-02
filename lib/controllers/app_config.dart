import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class AppConfig {
  // Production
  static const String _productionUrl = 'https://karyaone.tech/api';

  // Development (aktifkan jika perlu testing lokal)
  static const String _localIp = '192.1.172.51';
  static const String _port = '8000';
  static const String _apiPath = '/api';

  // Ganti ke false saat production, true saat development lokal
  static const bool _isDevelopment = false;

  static String? _cachedBaseUrl;

  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    if (!_isDevelopment) {
      _cachedBaseUrl = _productionUrl;
      return _cachedBaseUrl!;
    }

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
      _cachedBaseUrl = 'http://$_localIp:$_port$_apiPath';
    }

    return _cachedBaseUrl!;
  }

  static void resetCache() {
    _cachedBaseUrl = null;
  }
}
