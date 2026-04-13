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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNumberBadge(),
              const SizedBox(width: 14),
              Expanded(child: _buildContent()),
              const SizedBox(width: 8),
              _buildStatusBadge(hasBoth, hasMasukOnly),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF8A94A6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberBadge() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
            color: Color(0xFF1976D2),
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

        // Masuk row
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
              _formatJamWIB(data!['waktu_absen']?.toString() ?? ''),
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

  Widget _buildStatusBadge(bool hasBoth, bool hasMasukOnly) {
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Masuk',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1565C0),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

/// Format jam ke WIB: "08:30 WIB"
String _formatJamWIB(String waktuStr) {
  try {
    final dt = DateTime.parse(waktuStr);
    final wib = dt.toUtc().add(const Duration(hours: 7));
    final jam = wib.hour.toString().padLeft(2, '0');
    final menit = wib.minute.toString().padLeft(2, '0');
    return '$jam:$menit WIB';
  } catch (_) {
    return '-';
  }
}

/// Format tanggal ke Indonesia: "Senin, 07 April 2025"
String _formatTanggalIndonesia(String tanggalStr) {
  try {
    final dt = DateTime.parse(tanggalStr);
    final wib = dt.toUtc().add(const Duration(hours: 7));

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

    final hari = hariList[wib.weekday - 1];
    final tgl = wib.day.toString().padLeft(2, '0');
    final bulan = bulanList[wib.month - 1];
    final tahun = wib.year;

    return '$hari, $tgl $bulan $tahun';
  } catch (_) {
    return tanggalStr;
  }
}
