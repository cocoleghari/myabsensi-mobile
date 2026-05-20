import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/pages/user/absenPage/modals/my_calendar_page.dart';
import 'package:myabsensi_mobile/pages/user/absenPage/modals/kehadiran_saya_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL KALENDER PAGE
// Muncul ketika tanggal di MyCalendarPage diklik.
// Menampilkan 3 menu: Kehadiran Saya, Daftar Ketidakhadiran, Daftar Cuti
// ─────────────────────────────────────────────────────────────────────────────

class DetailKalenderPage extends StatelessWidget {
  final DateTime tanggal;
  final AbsensiHarian? absensi;

  const DetailKalenderPage({super.key, required this.tanggal, this.absensi});

  static void show(DateTime tanggal, {AbsensiHarian? absensi}) {
    Get.to(
      () => DetailKalenderPage(tanggal: tanggal, absensi: absensi),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 260),
    );
  }

  String get _formattedDate {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${tanggal.day} ${monthNames[tanggal.month - 1]} ${tanggal.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF1A1F36),
            ),
          ),
          title: Text(
            'Detail Kalender ($_formattedDate)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F36),
            ),
          ),
          centerTitle: false,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          ),
        ),
        body: Column(
          children: [const SizedBox(height: 16), _buildMenuList(context)],
        ),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    final menus = [
      _MenuData(
        icon: Icons.receipt_long_outlined,
        label: 'Kehadiran Saya',
        onTap: () => _goKehadiranSaya(),
      ),
      _MenuData(
        icon: Icons.highlight_off_outlined,
        label: 'Daftar Ketidakhadiran',
        onTap: () => _goKetidakhadiran(),
      ),
      _MenuData(
        icon: Icons.event_note_outlined,
        label: 'Daftar Cuti',
        onTap: () => _goCuti(),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: menus.asMap().entries.map((entry) {
          final i = entry.key;
          final menu = entry.value;
          final isLast = i == menus.length - 1;
          return _buildMenuItem(menu, isLast: isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuData menu, {required bool isLast}) {
    return InkWell(
      onTap: menu.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(menu.icon, size: 20, color: const Color(0xFF8A94A6)),
            ),
            const SizedBox(width: 14),
            // Label
            Expanded(
              child: Text(
                menu.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1F36),
                ),
              ),
            ),
            // Chevron
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFFB0B8C9),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigasi ke sub-halaman ───────────────────────────────────────────────

  void _goKehadiranSaya() {
    Map<String, dynamic>? raw;

    if (absensi != null) {
      final tgl =
          '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
      raw = {
        'tanggal_absen': tgl,
        if (absensi!.rawMasuk != null) 'masuk': absensi!.rawMasuk!,
        if (absensi!.rawPulang != null) 'pulang': absensi!.rawPulang!,
        // shift dari rawMasuk/rawPulang sudah ikut otomatis
      };
    }

    KehadiranSayaPage.show(tanggal, rawAbsensi: raw);
  }

  void _goKetidakhadiran() {
    Get.to(
      () => KetidakhadiranPage(tanggal: tanggal),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 260),
    );
  }

  void _goCuti() {
    Get.to(
      () => CutiPage(tanggal: tanggal),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 260),
    );
  }
}

class _MenuData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// KETIDAKHADIRAN PAGE (placeholder — sesuaikan dengan API)
// ─────────────────────────────────────────────────────────────────────────────

class KetidakhadiranPage extends StatelessWidget {
  final DateTime tanggal;

  const KetidakhadiranPage({super.key, required this.tanggal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar('Daftar Ketidakhadiran'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.highlight_off_outlined,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data ketidakhadiran',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUTI PAGE (placeholder — sesuaikan dengan API)
// ─────────────────────────────────────────────────────────────────────────────

class CutiPage extends StatelessWidget {
  final DateTime tanggal;

  const CutiPage({super.key, required this.tanggal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar('Daftar Cuti'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data cuti',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED APP BAR BUILDER
// ─────────────────────────────────────────────────────────────────────────────

AppBar _buildAppBar(String title) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(
      onPressed: () => Get.back(),
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 20,
        color: Color(0xFF1A1F36),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1F36),
      ),
    ),
    centerTitle: false,
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
    ),
  );
}
