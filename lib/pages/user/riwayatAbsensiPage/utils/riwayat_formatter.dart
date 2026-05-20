class RiwayatFormatter {
  // ── Format tanggal YYYY-MM-DD → DD-MM-YYYY ──────────────────────────────────
  static String formatTanggal(String tanggal) {
    try {
      final parts = tanggal.split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
      return tanggal;
    } catch (_) {
      return tanggal;
    }
  }

  // ── Format jam dari datetime string ke HH:mm WIB ────────────────────────────
  //
  // waktu_absen dari backend adalah UTC datetime.
  // Konversi ke WIB (+7) agar konsisten dengan card & detail dialog.
  static String formatJam(String waktuStr) {
    try {
      final dt = DateTime.parse(waktuStr);
      final utc = dt.isUtc ? dt : dt.toUtc();
      final wib = utc.add(const Duration(hours: 7));
      final jam = wib.hour.toString().padLeft(2, '0');
      final menit = wib.minute.toString().padLeft(2, '0');
      return '$jam:$menit';
    } catch (_) {
      return '-';
    }
  }

  // ── Format waktu lengkap: "DD-MM-YYYY HH:mm" ────────────────────────────────
  static String formatWaktuLengkap(String waktuStr) {
    try {
      final dt = DateTime.parse(waktuStr);
      final utc = dt.isUtc ? dt : dt.toUtc();
      final wib = utc.add(const Duration(hours: 7));

      final tgl = wib.day.toString().padLeft(2, '0');
      final bln = wib.month.toString().padLeft(2, '0');
      final thn = wib.year;
      final jam = wib.hour.toString().padLeft(2, '0');
      final mnt = wib.minute.toString().padLeft(2, '0');

      return '$tgl-$bln-$thn $jam:$mnt';
    } catch (_) {
      return waktuStr;
    }
  }

  // ── Group by tanggal_absen (field logis dari backend) ───────────────────────
  //
  // FIX: sebelumnya groupByDate memakai field waktu_absen (datetime UTC)
  // sebagai kunci tanggal. Masalahnya:
  //   - waktu_absen bisa berbeda format antar record
  //   - waktu shift malam (jam 23:xx UTC = jam 06:xx WIB hari berikutnya)
  //     menyebabkan record masuk & pulang jatuh ke tanggal UTC berbeda
  //
  // Solusi: pakai tanggal_absen yang sudah dihitung backend via
  // $shift->tanggalLogisAbsensi($sekarang) — selalu berupa "YYYY-MM-DD".
  // Fallback ke waktu_absen hanya jika tanggal_absen tidak ada (data lama).
  static Map<String, List<Map<String, dynamic>>> groupByDate(
    List<Map<String, dynamic>> data,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in data) {
      String tanggal = '';

      // Prioritas 1: tanggal_absen (field logis dari backend, selalu date)
      final tanggalAbsen = item['tanggal_absen']?.toString() ?? '';
      if (tanggalAbsen.isNotEmpty) {
        // Pastikan hanya ambil bagian date (YYYY-MM-DD), buang time jika ada
        tanggal = tanggalAbsen.split('T')[0].split(' ')[0];
      }

      // Fallback: ekstrak dari waktu_absen jika tanggal_absen tidak ada
      if (tanggal.isEmpty) {
        final waktuAbsen = item['waktu_absen']?.toString() ?? '';
        if (waktuAbsen.isNotEmpty) {
          if (waktuAbsen.contains('T')) {
            tanggal = waktuAbsen.split('T')[0];
          } else if (waktuAbsen.contains(' ')) {
            tanggal = waktuAbsen.split(' ')[0];
          }
        }
      }

      if (tanggal.isEmpty) continue;

      grouped.putIfAbsent(tanggal, () => []).add(item);
    }

    return grouped;
  }

  // ── URL foto lengkap ─────────────────────────────────────────────────────────
  static String getFullImageUrl(String path, String baseUrl) {
    if (path.isEmpty) return '';

    if (path.startsWith('http')) {
      if (path.contains('localhost')) {
        return path.replaceFirst('localhost', '192.168.0.100:8000');
      }
      return path;
    }
    if (path.startsWith('/storage')) {
      return baseUrl + path;
    }
    return '$baseUrl/storage/foto_absensi/$path';
  }
}
