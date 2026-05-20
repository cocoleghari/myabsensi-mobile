class AdminFormatter {
  // Format tanggal dari YYYY-MM-DD ke DD-MM-YYYY
  static String formatTanggal(String tanggal) {
    try {
      final parts = tanggal.split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
      return tanggal;
    } catch (e) {
      return tanggal;
    }
  }

  // Format jam dari datetime string
  static String formatJam(String waktuStr) {
    try {
      if (waktuStr.contains('T')) {
        final parts = waktuStr.split('T');
        String jam = parts[1];
        jam = jam.replaceAll(RegExp(r'\..*$'), '');
        jam = jam.replaceAll(RegExp(r'Z$'), '');
        if (jam.contains(':')) {
          final jamParts = jam.split(':');
          if (jamParts.length >= 2) {
            return '${jamParts[0]}:${jamParts[1]}';
          }
        }
        return jam;
      }
      if (waktuStr.contains(' ')) {
        final parts = waktuStr.split(' ');
        if (parts.length >= 2) {
          String jam = parts[1];
          if (jam.contains(':')) {
            final jamParts = jam.split(':');
            if (jamParts.length >= 2) {
              return '${jamParts[0]}:${jamParts[1]}';
            }
          }
          return jam;
        }
      }
      return waktuStr;
    } catch (e) {
      return '-';
    }
  }

  // Format waktu lengkap dengan tanggal
  static String formatWaktuLengkap(String waktuStr) {
    try {
      if (waktuStr.contains('T')) {
        final parts = waktuStr.split('T');
        String tanggal = formatTanggal(parts[0]);
        String jam = formatJam(waktuStr);
        return '$tanggal $jam';
      }
      if (waktuStr.contains(' ')) {
        final parts = waktuStr.split(' ');
        String tanggal = formatTanggal(parts[0]);
        String jam = formatJam(waktuStr);
        return '$tanggal $jam';
      }
      return waktuStr;
    } catch (e) {
      return waktuStr;
    }
  }

  // Mendapatkan URL foto lengkap
  static String getFullImageUrl(String path, String baseUrl) {
    if (path.isEmpty) return '';

    String result = '';

    if (path.startsWith('http')) {
      result = path;
    } else if (path.startsWith('/storage')) {
      result = baseUrl + path;
    } else {
      result = baseUrl + '/storage/foto_absensi/' + path;
    }

    // if (result.contains('192.168.1.10') && !result.contains(':8000')) {
    //   result = result.replaceFirst('192.168.1.10', '192.168.1.10:8000');
    // }

    // if (result.contains('localhost')) {
    //   result = result.replaceFirst('localhost', '192.168.1.10:8000');
    // }

    if (result.contains('192.168.0.100') && !result.contains(':8000')) {
      result = result.replaceFirst('192.168.0.100', '192.168.0.100:8000');
    }

    if (result.contains('localhost')) {
      result = result.replaceFirst('localhost', '192.168.0.100:8000');
    }

    return result;
  }

  // Group data by user and date
  static Map<String, Map<String, List<Map<String, dynamic>>>>
  groupByUserAndDate(
    List<Map<String, dynamic>> data,
    Function(int) getUserNameById,
  ) {
    final Map<String, Map<String, List<Map<String, dynamic>>>> result = {};

    for (var item in data) {
      // Ambil userId dari item
      String userId = item['user_id']?.toString() ?? '0';

      // Dapatkan userName berdasarkan userId
      String userName = getUserNameById(int.tryParse(userId) ?? 0);

      // Inisialisasi jika belum ada
      if (!result.containsKey(userName)) {
        result[userName] = {};
      }

      // Parse tanggal dari waktu_absen
      if (item['waktu_absen'] != null) {
        String waktu = item['waktu_absen'].toString();
        String tanggal = '';

        if (waktu.contains('T')) {
          tanggal = waktu.split('T')[0];
        } else if (waktu.contains(' ')) {
          tanggal = waktu.split(' ')[0];
        }

        if (tanggal.isNotEmpty) {
          if (!result[userName]!.containsKey(tanggal)) {
            result[userName]![tanggal] = [];
          }
          result[userName]![tanggal]!.add(item);
        }
      }
    }

    return result;
  }
}
