class RiwayatFormatter {
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

  // Group data berdasarkan tanggal
  static Map<String, List<Map<String, dynamic>>> groupByDate(
    List<Map<String, dynamic>> data,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in data) {
      if (item['waktu_absen'] != null) {
        String waktu = item['waktu_absen'].toString();
        String tanggal = '';

        if (waktu.contains('T')) {
          tanggal = waktu.split('T')[0];
        } else if (waktu.contains(' ')) {
          tanggal = waktu.split(' ')[0];
        }

        if (tanggal.isNotEmpty) {
          if (!grouped.containsKey(tanggal)) {
            grouped[tanggal] = [];
          }
          grouped[tanggal]!.add(item);
        }
      }
    }

    return grouped;
  }

  // Mendapatkan URL foto lengkap
  // static String getFullImageUrl(String path, String baseUrl) {
  //   if (path.isEmpty) return '';

  //   if (path.startsWith('http')) {
  //     if (path.contains('localhost')) {
  //       return path.replaceFirst(
  //         'localhost',
  //         baseUrl.replaceAll('http://', ''),
  //       );
  //     }
  //     return path;
  //   }
  //   if (path.startsWith('/storage')) {
  //     return baseUrl + path;
  //   }
  //   return baseUrl + '/storage/foto_absensi/' + path;
  // }

  static getFullImageUrl(String path, String baseUrl) {
    if (path.isEmpty) return '';

    if (path.startsWith('http')) {
      if (path.contains('localhost')) {
        // return path.replaceFirst('localhost', '192.168.1.9:8000');
        return path.replaceFirst('localhost', '192.168.0.100:8000');
        // return path.replaceFirst('localhost', '10.0.2.2:8000');
      }
      return path;
    }
    if (path.startsWith('/storage')) {
      return baseUrl + path;
    }
    return baseUrl + '/storage/foto_absensi/' + path;
  }
}
