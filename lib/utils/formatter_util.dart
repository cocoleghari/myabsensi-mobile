import 'package:intl/intl.dart';

class FormatterUtil {
  // Konversi DateTime ke WIB (UTC+7)
  static DateTime _toWIB(DateTime dt) {
    final utc = dt.toUtc();
    return utc.add(const Duration(hours: 7));
  }

  // Parse string waktu ke DateTime
  static DateTime? _parseWaktu(String waktuStr) {
    try {
      return DateTime.parse(waktuStr);
    } catch (_) {
      return null;
    }
  }

  /// Format waktu simple: "HH:mm" dalam WIB
  static String formatWaktuSimple(String waktuStr) {
    try {
      final dt = _parseWaktu(waktuStr);
      if (dt == null) return '-';
      final wib = _toWIB(dt);
      return DateFormat('HH:mm').format(wib);
    } catch (e) {
      return '-';
    }
  }

  /// Format tanggal: "dd-MM-yyyy" dalam WIB
  static String formatTanggal(String tanggalStr) {
    try {
      final dt = _parseWaktu(tanggalStr);
      if (dt == null) return tanggalStr;
      final wib = _toWIB(dt);
      return DateFormat('dd-MM-yyyy').format(wib);
    } catch (e) {
      return tanggalStr;
    }
  }

  /// Format jam: "HH:mm" dalam WIB (alias formatWaktuSimple)
  static String formatJam(String waktuStr) {
    return formatWaktuSimple(waktuStr);
  }

  /// Format lengkap: "dd-MM-yyyy HH:mm" dalam WIB
  static String formatWaktuLengkap(String waktuStr) {
    try {
      final dt = _parseWaktu(waktuStr);
      if (dt == null) return '-';
      final wib = _toWIB(dt);
      return DateFormat('dd-MM-yyyy HH:mm').format(wib);
    } catch (e) {
      return '-';
    }
  }

  // ================= FUNGSI UNTUK URL GAMBAR =================
  static String getFullImageUrl(String path, String baseUrl) {
    if (path.isEmpty) return '';

    // Hapus '/api' dari baseUrl jika ada
    String cleanBaseUrl = baseUrl.replaceAll('/api', '');

    if (path.startsWith('http')) {
      if (path.contains('localhost')) {
        // Ganti localhost dengan IP dari baseUrl
        String ip = cleanBaseUrl.replaceAll('http://', '');
        return path.replaceFirst('localhost', ip);
      }
      return path;
    }

    if (path.startsWith('/storage')) {
      return cleanBaseUrl + path;
    }

    // Cek apakah path untuk wajah atau absensi
    if (path.contains('wajah')) {
      return '$cleanBaseUrl/storage/wajah/$path';
    } else {
      return '$cleanBaseUrl/storage/foto_absensi/$path';
    }
  }

  // Fungsi khusus untuk wajah
  static String getWajahImageUrl(String path) {
    if (path.isEmpty) return '';

    const String baseUrl = 'http://192.168.0.100:8000';

    if (path.startsWith('http')) {
      if (path.contains('localhost')) {
        return path.replaceFirst('localhost', '192.168.0.100:8000');
      }
      return path;
    }

    if (path.startsWith('/storage')) {
      return baseUrl + path;
    }

    return '$baseUrl/storage/wajah/$path';
  }

  // ================= FUNGSI UNTUK URL GAMBAR WAJAH =================
  static String getWajahAdminImageUrl(String path, {String? baseUrl}) {
    if (path.isEmpty) return '';

    // Default base URL
    const String defaultBaseUrl = 'http://192.168.0.100:8000';
    final String finalBaseUrl = baseUrl ?? defaultBaseUrl;

    // Hapus '/api' jika ada
    String cleanBaseUrl = finalBaseUrl.replaceAll('/api', '');

    if (path.startsWith('http')) {
      if (path.contains('localhost')) {
        // Ekstrak IP dari cleanBaseUrl
        String ip = cleanBaseUrl.replaceAll('http://', '');
        return path.replaceFirst('localhost', ip);
      }
      return path;
    }

    if (path.startsWith('/storage')) {
      return cleanBaseUrl + path;
    }

    return '$cleanBaseUrl/storage/wajah/$path';
  }

  /// Format bulan dan tahun: "April 2026" dalam WIB
  static String formatBulanTahun(String tanggalStr) {
    try {
      final dt = _parseWaktu(tanggalStr);
      if (dt == null) return tanggalStr;
      final wib = _toWIB(dt);
      return DateFormat('MMMM yyyy', 'id_ID').format(wib);
    } catch (e) {
      return tanggalStr;
    }
  }
}
