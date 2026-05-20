import 'package:flutter/material.dart';

class RiwayatCardWidget extends StatelessWidget {
  final int index;
  final String tanggal;
  final Map<String, dynamic>? dataMasuk;
  final Map<String, dynamic>? dataPulang;
  final VoidCallback onTap;

  const RiwayatCardWidget({
    super.key,
    required this.index,
    required this.tanggal,
    required this.dataMasuk,
    required this.dataPulang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasBoth = dataMasuk != null && dataPulang != null;
    final bool hasMasukOnly = dataMasuk != null && dataPulang == null;

    // Ambil status dari data masuk (jika terlambat)
    final String statusMasuk = dataMasuk?['status']?.toString() ?? '';
    final int menitTerlambat =
        (dataMasuk?['menit_terlambat'] as num?)?.toInt() ?? 0;

    // Ambil info shift dan lokasi dari data masuk (prioritas) atau pulang
    final dataRef = dataMasuk ?? dataPulang;
    final String namaLokasi =
        dataRef?['pusat_lokasi']?['nama_lokasi']?.toString() ?? '';
    final String namaShift = dataRef?['shift']?['nama']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Baris utama ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNumberBadge(statusMasuk),
                  const SizedBox(width: 14),
                  Expanded(child: _buildContent()),
                  const SizedBox(width: 8),
                  _buildStatusBadge(hasBoth, hasMasukOnly, statusMasuk),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF8A94A6),
                  ),
                ],
              ),

              // ── Info tambahan: lokasi & shift ──
              if (namaLokasi.isNotEmpty || namaShift.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(height: 1, color: const Color(0xFFEEF0F4)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (namaLokasi.isNotEmpty) ...[
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Color(0xFF8A94A6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          namaLokasi,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A94A6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (namaShift.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: Color(0xFF8A94A6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        namaShift,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A94A6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // ── Badge terlambat jika ada ──
              if (statusMasuk == 'terlambat' && menitTerlambat > 0) ...[
                const SizedBox(height: 8),
                _buildTerlambatBadge(menitTerlambat),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberBadge(String status) {
    // Warna badge berubah sesuai status
    final Color bgColor = status == 'terlambat'
        ? const Color(0xFFF44336).withOpacity(0.09)
        : const Color(0xFF1976D2).withOpacity(0.09);
    final Color textColor = status == 'terlambat'
        ? const Color(0xFFC62828)
        : const Color(0xFF1976D2);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$index',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatTanggalIndonesia(tanggal),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1F36),
          ),
        ),
        const SizedBox(height: 8),

        // Masuk row — gunakan waktu_absen (datetime UTC dari backend)
        _buildTimeRow(
          label: 'Masuk',
          data: dataMasuk,
          activeColor: const Color(0xFF2E7D32),
          inactiveColor: const Color(0xFF8A94A6),
        ),
        const SizedBox(height: 4),

        // Pulang row
        _buildTimeRow(
          label: 'Pulang',
          data: dataPulang,
          activeColor: const Color(0xFFE65100),
          inactiveColor: const Color(0xFF8A94A6),
        ),
      ],
    );
  }

  Widget _buildTimeRow({
    required String label,
    required Map<String, dynamic>? data,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool hasData = data != null;
    final color = hasData ? activeColor : inactiveColor;

    // waktu_absen dari backend adalah datetime UTC, konversi ke WIB
    final String jamTampil = hasData
        ? _formatJamWIB(data!['waktu_absen']?.toString() ?? '')
        : '—';

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: hasData ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        if (hasData) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              jamTampil,
              style: TextStyle(
                fontSize: 11,
                color: activeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(width: 6),
          Text('—', style: TextStyle(fontSize: 12, color: inactiveColor)),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(bool hasBoth, bool hasMasukOnly, String status) {
    if (hasBoth) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Lengkap',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    } else if (hasMasukOnly) {
      // Warna berbeda jika terlambat
      final bool isTerlambat = status == 'terlambat';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isTerlambat
              ? const Color(0xFFF44336).withOpacity(0.08)
              : const Color(0xFF1565C0).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          isTerlambat ? 'Terlambat' : 'Masuk',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isTerlambat
                ? const Color(0xFFC62828)
                : const Color(0xFF1565C0),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTerlambatBadge(int menitTerlambat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF44336).withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF44336).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_off_rounded,
            size: 13,
            color: Color(0xFFC62828),
          ),
          const SizedBox(width: 5),
          Text(
            'Terlambat $menitTerlambat menit',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

/// Format datetime UTC dari backend ke WIB: "08:30 WIB"
/// Backend menyimpan waktu_absen sebagai datetime (UTC atau server time).
/// Diasumsikan server menggunakan UTC, konversi +7 untuk WIB.
String _formatJamWIB(String waktuStr) {
  try {
    final dt = DateTime.parse(waktuStr);
    // Jika sudah ada timezone info (contains 'Z' atau '+'), parse langsung
    // Jika tidak ada (format: "2025-04-07 08:30:00"), asumsikan UTC
    final utc = dt.isUtc ? dt : dt.toUtc();
    final wib = utc.add(const Duration(hours: 7));
    final jam = wib.hour.toString().padLeft(2, '0');
    final menit = wib.minute.toString().padLeft(2, '0');
    return '$jam:$menit WIB';
  } catch (_) {
    return '-';
  }
}

/// Format tanggal_absen (date string: "2025-04-07") ke Indonesia: "Senin, 07 April 2025"
/// tanggal_absen adalah tanggal LOGIS dari backend, tidak perlu konversi timezone.
String _formatTanggalIndonesia(String tanggalStr) {
  try {
    // tanggal_absen berformat "YYYY-MM-DD" (date, bukan datetime)
    // Parse sebagai local date tanpa konversi timezone
    final parts = tanggalStr.split('-');
    if (parts.length < 3) return tanggalStr;

    final dt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    const hariList = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulanList = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final hari = hariList[dt.weekday - 1];
    final tgl = dt.day.toString().padLeft(2, '0');
    final bulan = bulanList[dt.month - 1];
    final tahun = dt.year;

    return '$hari, $tgl $bulan $tahun';
  } catch (_) {
    return tanggalStr;
  }
}
