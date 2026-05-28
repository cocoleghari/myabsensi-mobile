import 'package:intl/intl.dart';

class FormatterUtil {
  // Parse string waktu ke DateTime lokal
  static DateTime? _parseWaktu(String waktuStr) {
    try {
      return DateTime.parse(waktuStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String formatWaktuSimple(String waktuStr) {
    try {
      final dt = _parseWaktu(waktuStr);
      if (dt == null) return '-';
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '-';
    }
  }

  static String formatTanggal(String tanggalStr) {
    try {
      final dt = _parseWaktu(tanggalStr);
      if (dt == null) return tanggalStr;
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (e) {
      return tanggalStr;
    }
  }

  static String formatJam(String waktuStr) => formatWaktuSimple(waktuStr);

  static String formatWaktuLengkap(String waktuStr) {
    try {
      final dt = _parseWaktu(waktuStr);
      if (dt == null) return '-';
      return DateFormat('dd-MM-yyyy HH:mm').format(dt);
    } catch (e) {
      return '-';
    }
  }

  static String formatBulanTahun(String tanggalStr) {
    try {
      final dt = _parseWaktu(tanggalStr);
      if (dt == null) return tanggalStr;
      return DateFormat('MMMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return tanggalStr;
    }
  }

  // ── URL helpers tetap sama ──────────────────────────────────────────────

  static String getFullImageUrl(String path, String baseUrl) {
    if (path.isEmpty) return '';
    String cleanBaseUrl = baseUrl.replaceAll('/api', '');
    if (path.startsWith('http')) {
      if (path.contains('localhost')) {
        String ip = cleanBaseUrl.replaceAll('http://', '');
        return path.replaceFirst('localhost', ip);
      }
      return path;
    }
    if (path.startsWith('/storage')) return cleanBaseUrl + path;
    if (path.contains('wajah')) return '$cleanBaseUrl/storage/wajah/$path';
    return '$cleanBaseUrl/storage/foto_absensi/$path';
  }

  static String getWajahImageUrl(String path) {
    if (path.isEmpty) return '';
    const String baseUrl = 'https://karyaone.tech';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/storage')) return baseUrl + path;
    return '$baseUrl/storage/wajah/$path';
  }

  static String getWajahAdminImageUrl(String path, {String? baseUrl}) {
    if (path.isEmpty) return '';
    const String defaultBaseUrl = 'https://karyaone.tech';
    final String finalBaseUrl = baseUrl ?? defaultBaseUrl;
    String cleanBaseUrl = finalBaseUrl.replaceAll('/api', '');
    if (path.startsWith('http')) return path;
    if (path.startsWith('/storage')) return cleanBaseUrl + path;
    return '$cleanBaseUrl/storage/wajah/$path';
  }
}
