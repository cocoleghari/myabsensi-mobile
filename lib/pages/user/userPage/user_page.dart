import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/rekam_aktivitas_controller.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/riwayat_absensi_page.dart';
import 'package:myabsensi_mobile/pages/user/cutiPage/cuti_page.dart';
import 'package:myabsensi_mobile/pages/user/rekamAktivitasPage/rekam_aktivitas_page.dart';
import 'package:get/get.dart';
import '../absenPage/absen_page.dart';
import '../profilPage/profil_page.dart';

// Tema warna biru konsisten
class _AppColors {
  static const primary = Color(0xFF1565C0);
  static const activeBackground = Color(0xFFEBF3FF);
  static const activeDot = Color(0xFF1565C0);
  static const inactiveIcon = Color(0xFF9CA3AF);
  static const navBackground = Colors.white;
  static const navBorder = Color(0xFFE5E7EB);
}

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RekamAktivitasController(), permanent: true);
    Get.find<AuthController>();

    if (!Get.isRegistered<UserLokasiController>()) {
      Get.put(UserLokasiController());
    }

    final bottomNavController = Get.put(UserBottomNavController());

    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: bottomNavController.currentIndex.value,
          children: const [
            AbsenPage(),
            RiwayatAbsensiPage(),
            RekamAktivitasPage(),
            CutiPage(),
            ProfilPage(),
          ],
        ),
        bottomNavigationBar: _ModernNavBar(controller: bottomNavController),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final Widget icon; // icon nonaktif
  final Widget activeIcon; // icon aktif (warna primary)

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

// Daftar item dengan icon SVG path kustom lebih modern
List<_NavItemData> _buildNavItems(Color active, Color inactive) {
  return [
    // Absen — icon fingerprint scan modern
    _NavItemData(
      label: 'Absen',
      icon: _SvgIcon(color: inactive, child: _IconAbsen()),
      activeIcon: _SvgIcon(color: active, child: _IconAbsen()),
    ),
    // Riwayat — clipboard search
    _NavItemData(
      label: 'Riwayat',
      icon: _SvgIcon(color: inactive, child: _IconRiwayat()),
      activeIcon: _SvgIcon(color: active, child: _IconRiwayat()),
    ),
    // Rekam — video camera modern
    _NavItemData(
      label: 'Rekam',
      icon: _SvgIcon(color: inactive, child: _IconRekam()),
      activeIcon: _SvgIcon(color: active, child: _IconRekam()),
    ),
    // Cuti — calendar plus
    _NavItemData(
      label: 'Cuti',
      icon: _SvgIcon(color: inactive, child: _IconCuti()),
      activeIcon: _SvgIcon(color: active, child: _IconCuti()),
    ),
    // Profil — user circle
    _NavItemData(
      label: 'Profil',
      icon: _SvgIcon(color: inactive, child: _IconProfil()),
      activeIcon: _SvgIcon(color: active, child: _IconProfil()),
    ),
  ];
}

class _ModernNavBar extends StatelessWidget {
  final UserBottomNavController controller;

  const _ModernNavBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = _buildNavItems(_AppColors.primary, _AppColors.inactiveIcon);

    return Obx(
      () => Container(
        decoration: const BoxDecoration(
          color: _AppColors.navBackground,
          border: Border(
            top: BorderSide(color: _AppColors.navBorder, width: 0.8),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isActive = controller.currentIndex.value == index;
                return _NavBarTile(
                  item: items[index],
                  isActive: isActive,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.changePage(index);
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarTile extends StatelessWidget {
  final _NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _AppColors.activeBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon dengan animasi switch
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isActive
                  ? KeyedSubtree(
                      key: const ValueKey('active'),
                      child: item.activeIcon,
                    )
                  : KeyedSubtree(
                      key: const ValueKey('inactive'),
                      child: item.icon,
                    ),
            ),
            const SizedBox(height: 5),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? _AppColors.primary : _AppColors.inactiveIcon,
                letterSpacing: isActive ? 0.2 : 0,
              ),
              child: Text(item.label),
            ),
            const SizedBox(height: 3),
            // Dot indikator aktif
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              height: 3,
              width: isActive ? 18 : 0,
              decoration: BoxDecoration(
                color: _AppColors.activeDot,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wrapper icon dengan warna ───────────────────────────────────────────────

class _SvgIcon extends StatelessWidget {
  final Color color;
  final Widget child;
  const _SvgIcon({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: color, size: 22),
      child: child,
    );
  }
}

// ─── Custom Icons (menggunakan CustomPainter untuk stroke SVG path) ───────────

class _IconAbsen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color!;
    return CustomPaint(size: const Size(22, 22), painter: _AbsenPainter(color));
  }
}

class _AbsenPainter extends CustomPainter {
  final Color color;
  _AbsenPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final s = size.width / 24;
    // Oval tengah (jari)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(12 * s, 10 * s),
        width: 7 * s,
        height: 9 * s,
      ),
      p,
    );
    // Lingkaran scan putus-putus
    final pd = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(12 * s, 10 * s), 8 * s, pd);
    // Garis bawah scan
    canvas.drawLine(Offset(4 * s, 19 * s), Offset(8 * s, 19 * s), p);
    canvas.drawLine(Offset(16 * s, 19 * s), Offset(20 * s, 19 * s), p);
  }

  @override
  bool shouldRepaint(_AbsenPainter old) => old.color != color;
}

class _IconRiwayat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color!;
    return CustomPaint(
      size: const Size(22, 22),
      painter: _RiwayatPainter(color),
    );
  }
}

class _RiwayatPainter extends CustomPainter {
  final Color color;
  _RiwayatPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final s = size.width / 24;
    // Clipboard body
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3 * s, 4 * s, 18 * s, 16 * s),
      Radius.circular(3 * s),
    );
    canvas.drawRRect(rrect, p);
    // Lines
    canvas.drawLine(Offset(8 * s, 9 * s), Offset(16 * s, 9 * s), p);
    canvas.drawLine(Offset(8 * s, 13 * s), Offset(13 * s, 13 * s), p);
    // Magnifier
    final mp = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(16.5 * s, 15 * s), 2.5 * s, mp);
    canvas.drawLine(Offset(18.5 * s, 17 * s), Offset(20 * s, 18.5 * s), mp);
  }

  @override
  bool shouldRepaint(_RiwayatPainter old) => old.color != color;
}

class _IconRekam extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color!;
    return CustomPaint(size: const Size(22, 22), painter: _RekamPainter(color));
  }
}

class _RekamPainter extends CustomPainter {
  final Color color;
  _RekamPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final s = size.width / 24;
    // Camera body
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2 * s, 7 * s, 14 * s, 10 * s),
      Radius.circular(2.5 * s),
    );
    canvas.drawRRect(rrect, p);
    // Chevron kanan (kamera video)
    final path = Path()
      ..moveTo(16 * s, 10 * s)
      ..lineTo(21 * s, 7.5 * s)
      ..lineTo(21 * s, 16.5 * s)
      ..lineTo(16 * s, 14 * s);
    canvas.drawPath(path, p);
    // Dot rec
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(8 * s, 12 * s), 1.8 * s, dot);
  }

  @override
  bool shouldRepaint(_RekamPainter old) => old.color != color;
}

class _IconCuti extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color!;
    return CustomPaint(size: const Size(22, 22), painter: _CutiPainter(color));
  }
}

class _CutiPainter extends CustomPainter {
  final Color color;
  _CutiPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final s = size.width / 24;
    // Calendar body
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3 * s, 6 * s, 18 * s, 14 * s),
      Radius.circular(2.5 * s),
    );
    canvas.drawRRect(rrect, p);
    // Header line
    canvas.drawLine(Offset(3 * s, 10 * s), Offset(21 * s, 10 * s), p);
    // Pin kiri kanan
    canvas.drawLine(Offset(8 * s, 4 * s), Offset(8 * s, 8 * s), p);
    canvas.drawLine(Offset(16 * s, 4 * s), Offset(16 * s, 8 * s), p);
    // Plus di tengah
    canvas.drawLine(Offset(12 * s, 14 * s), Offset(12 * s, 18 * s), p);
    canvas.drawLine(Offset(10 * s, 16 * s), Offset(14 * s, 16 * s), p);
  }

  @override
  bool shouldRepaint(_CutiPainter old) => old.color != color;
}

class _IconProfil extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color!;
    return CustomPaint(
      size: const Size(22, 22),
      painter: _ProfilPainter(color),
    );
  }
}

class _ProfilPainter extends CustomPainter {
  final Color color;
  _ProfilPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final s = size.width / 24;
    // Kepala
    canvas.drawCircle(Offset(12 * s, 8 * s), 3.5 * s, p);
    // Badan lengkung
    final path = Path()
      ..moveTo(4 * s, 20 * s)
      ..quadraticBezierTo(4 * s, 14 * s, 12 * s, 14 * s)
      ..quadraticBezierTo(20 * s, 14 * s, 20 * s, 20 * s);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ProfilPainter old) => old.color != color;
}

// ─── Controller ──────────────────────────────────────────────────────────────

class UserBottomNavController extends GetxController {
  var currentIndex = 0.obs;
  void changePage(int index) => currentIndex.value = index;
}
