import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/pages/user/rekamAktivitasPage/rekam_aktivitas_detail_page.dart';
import 'package:myabsensi_mobile/utils/formatter_util.dart';
import 'package:myabsensi_mobile/bindings/rekam_aktivitas_binding.dart';
import 'package:myabsensi_mobile/controllers/rekam_aktivitas_controller.dart';
import 'rekam_aktivitas_form_page.dart';

class RekamAktivitasPage extends GetView<RekamAktivitasController> {
  const RekamAktivitasPage({super.key});

  // ── Warna tema ─────────────────────────────────────────────────────────
  static const _gradientStart = Color(0xFF1565C0);
  static const _gradientMid = Color(0xFF1E88E5);
  static const _gradientEnd = Color(0xFF42A5F5);
  static const _accent = Color(0xFF1E88E5);
  static const _bg = Color(0xFFF2F4F7);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: _bg,
      body: Obx(() {
        return RefreshIndicator(
          onRefresh: () async => controller.fetchAktivitas(),
          color: _accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header biru ──────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader(authController)),
              // ── Konten putih ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
                  child: Column(
                    children: [
                      _buildCalendarSection(),
                      const SizedBox(height: 12),
                      _buildToolbar(),
                      const SizedBox(height: 12),
                      _buildActivityContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        final isToday = controller.isSameDay(
          controller.selectedDate.value,
          DateTime.now(),
        );
        if (!isToday) return const SizedBox.shrink();
        return FloatingActionButton(
          onPressed: () => Get.to(
            () => const RekamAktivitasFormPage(),
            binding: RekamAktivitasFormBinding(),
            transition: Transition.rightToLeft,
          ),
          backgroundColor: _accent,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        );
      }),
    );
  }

  // ── ACTIVITY CONTENT (dipakai portrait & landscape) ─────────────────
  Widget _buildActivityContent() {
    if (controller.isLoadingAktivitas.value) {
      return Center(child: CircularProgressIndicator(color: _accent));
    }
    if (controller.activities.isEmpty) {
      return _buildEmptyState();
    }
    if (controller.isGridView.value) {
      return _buildGridView();
    }
    return _buildTimelineView();
  }

  // ── HEADER BIRU ───────────────────────────────────────────────────────
  Widget _buildHeader(AuthController authController) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientMid, _gradientEnd],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Stack(
            children: [
              // Dekorasi lingkaran
              Positioned(
                right: -20,
                top: -10,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                right: 60,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul saja — tanpa tombol refresh
                  const Text(
                    'Aktivitas Harian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 20),
                  // User info & stat
                  Obx(() => _buildHeaderUserSection(authController)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderUserSection(AuthController authController) {
    final name = authController.userName;
    final photoUrl = authController.user['photo_url']?.toString() ?? '';
    final jabatan =
        authController.user['jabatan']?.toString() ??
        authController.user['role']?.toString() ??
        'Karyawan'; // fallback jika keduanya null

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white.withOpacity(0.3),
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          onBackgroundImageError: photoUrl.isNotEmpty ? (_, __) {} : null,
          child: photoUrl.isEmpty
              ? Text(
                  _getInitials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                jabatan, // <-- diganti dari hardcoded 'Karyawan'
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        _buildStatChip(
          icon: Icons.assignment_outlined,
          label: 'Aktivitas',
          value: '${controller.activities.length} item',
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.85), size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HELPER ────────────────────────────────────────────────────────────
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ── KALENDER ──────────────────────────────────────────────────────────
  Widget _buildCalendarSection() {
    final weekDays = controller.getWeekDays();
    final monthLabel = FormatterUtil.formatBulanTahun(
      controller.currentMonth.value.toIso8601String(),
    );
    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  _navButton(Icons.chevron_left, controller.previousWeek),
                  const SizedBox(width: 6),
                  _navButton(Icons.chevron_right, controller.nextWeek),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayNames.map((d) {
              return SizedBox(
                width: 36,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final date = weekDays[i];
              final isSelected = controller.isSelected(date);
              final isSunday = controller.isSunday(date);

              return GestureDetector(
                onTap: () => controller.selectDate(date),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: isSelected
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_gradientStart, _gradientMid],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isSunday
                          ? Colors.red[400]
                          : Colors.black87,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black54, size: 18),
      ),
    );
  }

  // ── TOOLBAR ───────────────────────────────────────────────────────────
  // Dipanggil di dalam Obx() dari parent — TIDAK boleh ada nested Obx di sini
  Widget _buildToolbar() {
    final isToday = controller.isSameDay(
      controller.selectedDate.value,
      DateTime.now(),
    );
    final isGrid = controller.isGridView.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: controller.fetchAktivitas,
            icon: Icon(
              Icons.video_camera_back_outlined,
              color: isToday ? _accent : Colors.grey[400],
              size: 18,
            ),
            label: Text(
              'Rekam Aktivitas',
              style: TextStyle(
                color: isToday ? _accent : Colors.grey[400],
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isToday ? _accent : Colors.grey.shade300,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          Row(
            children: [
              _viewToggleButton(
                icon: Icons.view_agenda_outlined,
                active: !isGrid,
                onTap: () => controller.isGridView.value = false,
              ),
              const SizedBox(width: 6),
              _viewToggleButton(
                icon: Icons.grid_view_outlined,
                active: isGrid,
                onTap: () => controller.isGridView.value = true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewToggleButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? _gradientMid : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? _gradientMid : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: active ? Colors.white : Colors.grey[400],
        ),
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFE3EDF8),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.schedule, size: 48, color: _gradientMid),
        ),
        const SizedBox(height: 16),
        Text(
          'Belum ada aktivitas',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap tombol + untuk menambah aktivitas',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── GRID VIEW ─────────────────────────────────────────────────────────
  Widget _buildGridView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.activities.length,
      itemBuilder: (context, index) {
        final activity = controller.activities[index];
        final fotos = activity['fotos'] as List? ?? [];
        final tipeNama =
            (activity['tipe_aktivitas'] is Map
                ? activity['tipe_aktivitas']['nama']
                : activity['tipe_aktivitas']) ??
            '';

        final fotoUrl = fotos.isNotEmpty
            ? controller.getFotoUrl(fotos[0]['foto_path'] ?? '')
            : '';

        return GestureDetector(
          onTap: () => Get.to(
            () => RekamAktivitasDetailPage(activity: activity),
            transition: Transition.rightToLeft,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EDF8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    size: 20,
                    color: _gradientMid,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EDF8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tipeNama,
                          style: TextStyle(
                            fontSize: 10,
                            color: _gradientStart,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['tugas'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${FormatterUtil.formatWaktuSimple(activity['mulai'] ?? '')} - '
                        '${FormatterUtil.formatWaktuSimple(activity['berakhir'] ?? '')}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (fotoUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fotoUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 52,
                            height: 52,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── TIMELINE VIEW ─────────────────────────────────────────────────────
  Widget _buildTimelineView() {
    const int startHour = 0;
    const int endHour = 24;
    const double hourHeight = 80.0;
    final int totalHours = endHour - startHour;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SizedBox(
        height: totalHours * hourHeight + 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Garis jam
            ...List.generate(totalHours + 1, (i) {
              final hour = startHour + i;
              final topPos = i * hourHeight;
              return Positioned(
                top: topPos,
                left: 0,
                right: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(height: 1, color: Colors.grey[200]),
                    ),
                  ],
                ),
              );
            }),

            // Garis setengah jam
            ...List.generate(totalHours, (i) {
              final topPos = i * hourHeight + (hourHeight / 2);
              return Positioned(
                top: topPos,
                left: 48,
                right: 0,
                child: Row(
                  children: List.generate(
                    20,
                    (j) => Expanded(
                      child: Container(
                        height: 1,
                        color: j % 2 == 0
                            ? Colors.grey[100]
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Blok istirahat
            Positioned(
              top: (12 - startHour) * hourHeight,
              left: 48,
              right: 0,
              height: hourHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.06),
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.coffee_outlined,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Waktu Istirahat',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Blok aktivitas
            ...controller.activities
                .map<Widget?>((activity) {
                  final mulai = _parseWib(activity['mulai'] ?? '');
                  final berakhir = _parseWib(activity['berakhir'] ?? '');
                  if (mulai == null || berakhir == null) return null;

                  final startMin = (mulai.hour - startHour) * 60 + mulai.minute;
                  final endMin =
                      (berakhir.hour - startHour) * 60 + berakhir.minute;
                  if (startMin < 0 || startMin >= totalHours * 60) return null;

                  final topPos = startMin * (hourHeight / 60);
                  final rawHeight = (endMin - startMin) * (hourHeight / 60);
                  final blockHeight = rawHeight < 28 ? 28.0 : rawHeight;

                  return Positioned(
                    top: topPos,
                    left: 48,
                    right: 0,
                    height: blockHeight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3EDF8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(color: _gradientMid, width: 3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 14,
                            color: _gradientMid,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${FormatterUtil.formatWaktuSimple(activity['mulai'] ?? '')} - '
                                  '${FormatterUtil.formatWaktuSimple(activity['berakhir'] ?? '')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _gradientStart,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  activity['tugas'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
                .whereType<Widget>()
                .toList(),
          ],
        ),
      ),
    );
  }

  // ── HELPER ────────────────────────────────────────────────────────────
  DateTime? _parseWib(String waktuStr) {
    try {
      final dt = DateTime.parse(waktuStr);
      return dt.toUtc().add(const Duration(hours: 7));
    } catch (_) {
      return null;
    }
  }
}
