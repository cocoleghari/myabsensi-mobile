import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/notification_controller.dart';
import 'package:myabsensi_mobile/controllers/offline_absensi_controller.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/user/absenPage/info_card_widget.dart';
import 'package:myabsensi_mobile/pages/user/absenPage/modals/search_employee_modal.dart';
import 'package:myabsensi_mobile/pages/user/absenPage/offline_queue_page.dart';
import 'package:myabsensi_mobile/pages/user/absenPage/modals/my_calendar_page.dart';
import 'package:myabsensi_mobile/pages/user/userPage/notification_page.dart';
import 'package:myabsensi_mobile/utils/formatter_util.dart';
import 'package:get/get.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  late final UserLokasiController _c;
  late final AuthController _auth;
  bool _showDetail = true;

  @override
  void initState() {
    super.initState();
    _c = Get.find<UserLokasiController>();
    _auth = Get.find<AuthController>();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1565C0),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _c.cekStatusHariIni(),
      _c.fetchRiwayatAbsensi(),
      _c.fetchUserLokasi(),
      _auth.fetchProfile(),
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    final double maxWidth = isWeb ? 500 : double.infinity;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: RefreshIndicator(
              onRefresh: _refreshAllData,
              color: const Color(0xFFFF7A30),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildGreetingWithHeader()),
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOfflineBanner(),
                          const SizedBox(height: 12),
                          _buildMainCard(),
                          const SizedBox(height: 16),
                          const InfoCardWidget(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── GREETING + HEADER ────────────────────────────────────────────────────

  Widget _buildGreetingWithHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    if (hour < 11) {
      greeting = 'Selamat Pagi';
      emoji = '☀️';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
      emoji = '🌤️';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
      emoji = '🌅';
    } else {
      greeting = 'Selamat Malam';
      emoji = '🌙';
    }

    return Obx(() {
      final displayName = _auth.employeeNickname.isNotEmpty
          ? _auth.employeeNickname
          : _auth.employeeFullName.isNotEmpty
          ? _auth.employeeFullName
          : _auth.userName;

      final firstName = displayName.split(' ').first;

      final jabatan = _auth.positionName.isNotEmpty
          ? _auth.positionName
          : _auth.departmentName.isNotEmpty
          ? _auth.departmentName
          : _auth.userRole;

      final photoUrl = _auth.photoUrl;
      final fullName = _auth.employeeFullName.isNotEmpty
          ? _auth.employeeFullName
          : _auth.userName;
      final nameParts = fullName.trim().split(' ');
      final initial = fullName.isEmpty
          ? 'U'
          : nameParts.length == 1
          ? nameParts[0][0].toUpperCase()
          : (nameParts[0][0] + nameParts[1][0]).toUpperCase();

      final sudahMasuk = _c.sudahMasuk.value;
      final sudahPulang = _c.sudahPulang.value;

      String statusText;
      if (sudahPulang) {
        statusText = 'Absensi hari ini sudah selesai 🎉';
      } else if (sudahMasuk) {
        statusText = 'Jangan lupa absen pulang ya!';
      } else {
        statusText = 'Belum absen masuk hari ini';
      }

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: 0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  right: 50,
                  bottom: -20,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting, $firstName $emoji',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _searchIconBtn(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildHeaderAvatar(
                          photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
                          initial: initial,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _auth.employeeFullName.isNotEmpty
                                    ? _auth.employeeFullName
                                    : _auth.userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (jabatan.isNotEmpty)
                                Text(
                                  jabatan,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.75),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        _calendarIconBtn(),
                        const SizedBox(width: 3),
                        _notificationIconBtn(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _notificationIconBtn() {
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController());
    }
    final nc = Get.find<NotificationController>();

    return GestureDetector(
      onTap: () => NotificationPage.show(),
      child: Obx(() {
        final unread = nc.unreadCount.value;
        return SizedBox(
          width:
              50, // ← lebih lebar dari container 42 agar badge tidak terpotong
          height: 50, // ← lebih tinggi
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _calendarIconBtn() {
    return GestureDetector(
      onTap: () {
        // Pastikan MyCalendarController terdaftar
        if (!Get.isRegistered<MyCalendarController>()) {
          Get.put(MyCalendarController());
        }
        MyCalendarPage.show();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: const Icon(
          Icons.calendar_today_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Map<String, String> _getDoneMessage() {
    final masuk = _c.dataMasuk.value?['waktu_absen']?.toString() ?? '';
    final pulang = _c.dataPulang.value?['waktu_absen']?.toString() ?? '';

    if (masuk.isEmpty || pulang.isEmpty) {
      return {
        'emoji': '🌟',
        'title': 'Kamu luar biasa hari ini!',
        'sub': 'Semua absensi tercatat · Sampai besok 👋',
      };
    }

    try {
      final jamMasuk = DateTime.parse(masuk).toLocal();
      final jamPulang = DateTime.parse(pulang).toLocal();
      final durasi = jamPulang.difference(jamMasuk);
      final jam = durasi.inMinutes / 60;
      final h = durasi.inHours;

      if (jam >= 15) {
        return {
          'emoji': '🔱',
          'title': '$h jam?! Kamu bukan manusia biasa!',
          'sub': 'Istirahat sekarang, kamu sudah lebih dari cukup 🙏',
        };
      } else if (jam >= 14) {
        return {
          'emoji': '💎',
          'title': '$h jam tanpa henti, luar biasa!',
          'sub': 'Dedikasi sepertimu yang menggerakkan dunia 🌍',
        };
      } else if (jam >= 13) {
        return {
          'emoji': '🦅',
          'title': '$h jam terbang tinggi hari ini!',
          'sub': 'Semangat sepertimu tidak ternilai harganya ✨',
        };
      } else if (jam >= 12) {
        return {
          'emoji': '🦾',
          'title': '$h jam penuh, kamu pahlawan sejati!',
          'sub': 'Kerja keras hari ini pasti terbayar lunas 💪',
        };
      } else if (jam >= 11) {
        return {
          'emoji': '🏆',
          'title': 'Wow, $h jam dedikasi tinggi!',
          'sub': 'Kamu membuktikan bahwa kerja keras itu nyata 🌠',
        };
      } else if (jam >= 10) {
        return {
          'emoji': '🚀',
          'title': '$h jam produktif penuh prestasi!',
          'sub': 'Performa luar biasa, terus pertahankan! ✨',
        };
      } else if (jam >= 9) {
        return {
          'emoji': '⚡',
          'title': '$h jam penuh semangat membara!',
          'sub': 'Konsistensi adalah kunci kesuksesanmu 🔑',
        };
      } else {
        return {
          'emoji': '🌟',
          'title': 'Kerja keras hari ini terbayar!',
          'sub': 'Istirahat yang cukup ya, sampai besok 👋',
        };
      }
    } catch (_) {
      return {
        'emoji': '🌟',
        'title': 'Kerja keras hari ini terbayar!',
        'sub': 'Istirahat yang cukup ya, sampai besok 👋',
      };
    }
  }

  Widget _searchIconBtn() {
    return GestureDetector(
      onTap: () => SearchEmployeeModal.show(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: const Icon(Icons.search, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildHeaderAvatar({
    required String? photoUrl,
    required String initial,
  }) {
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    // Tidak ada foto → avatar initial biasa tanpa border
    if (!hasPhoto) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Ada foto → dengan gradient border
    return CustomPaint(
      painter: _GradientBorderPainter(
        gradient: const SweepGradient(
          colors: [
            Color(0xFF42A5F5),
            Color.fromARGB(255, 241, 245, 31),
            Color.fromARGB(255, 228, 38, 38),
            Color.fromARGB(255, 30, 161, 223),
            Color(0xFF42A5F5),
          ],
        ),
        strokeWidth: 2,
        gap: 2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipOval(
          child: SizedBox(
            width: 42,
            height: 42,
            child: Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _headerInitial(initial),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return _headerInitial(initial);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerInitial(String initial) {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _whiteIconBtn(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // ─── MAIN CARD ────────────────────────────────────────────────────────────

  Widget _buildMainCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDateShiftHeader(),
          _buildTimeRow(),
          _buildRecordButton(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          StatefulBuilder(
            builder: (context, setInner) => Column(
              children: [
                if (_showDetail) _buildRiwayatList(),
                _buildViewMore(),
                _buildHideDetail(setInner),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DATE & SHIFT HEADER ──────────────────────────────────────────────────
  //
  // Shift dibaca dari 3 sumber berbeda dengan prioritas:
  //
  //   SUMBER 1 — _c.shiftHariIni (level atas response cekStatusHariIni):
  //     { "shift": { "nama": "Pagi", "jam_masuk": "08:00", "jam_pulang": "17:00" } }
  //     → Paling lengkap, ada jam_masuk & jam_pulang
  //     → Ada meskipun karyawan belum absen
  //
  //   SUMBER 2 — dataMasuk['shift'] / dataPulang['shift'] (eager-load Absensi→Shift):
  //     { "shift": { "id": 1, "nama": "Pagi", "kode": "P" } }
  //     → Hanya nama & kode, TIDAK ada jam_masuk/jam_pulang
  //     → Hanya ada setelah karyawan absen
  //
  // Bug sebelumnya: kode hanya membaca Sumber 2, yang tidak ada saat karyawan
  // belum absen → tampil "Tidak ada shift" padahal shift sudah di-assign.

  Widget _buildDateShiftHeader() {
    final now = DateTime.now();
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
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateStr =
        'Today (${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]} ${now.year})';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 3),
          Obx(() {
            final shiftLabel = _buildShiftLabel();
            final lokasiLabel = _buildLokasiLabel();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shift: $shiftLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A94A6),
                  ),
                ),
                if (lokasiLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 11,
                          color: Color(0xFF8A94A6),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            lokasiLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A94A6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Obx(() {
      final offline = Get.find<OfflineAbsensiController>();
      final isOnline = offline.isOnline.value;
      final count = offline.pendingCount;
      final isSyncing = offline.isSyncing.value;

      if (isOnline && count == 0) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => OfflineQueuePage.show(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline
                          ? 'Kamu memiliki absensi offline'
                          : 'Kamu tidak terkoneksi ke Internet',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isOnline
                          ? '$count absensi menunggu dikirim. Tap untuk detail.'
                          : 'Jangan khawatir! Kamu masih dapat merekam kehadiran dalam mode offline.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF97316),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOnline && count > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isSyncing ? null : () => offline.syncQueue(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isSyncing
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kirim',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFFFB923C),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  /// FIX: Baca shift dari shiftHariIni (level atas) lebih dulu,
  /// baru fallback ke relasi di dataMasuk/dataPulang.
  String _buildShiftLabel() {
    // Prioritas 1: dari level atas cekStatusHariIni — paling lengkap
    final shiftTop = _c.shiftHariIni.value;
    if (shiftTop != null && shiftTop.isNotEmpty) {
      final nama = shiftTop['nama']?.toString() ?? '';
      final jamMasuk = shiftTop['jam_masuk']?.toString() ?? '';
      final jamPulang = shiftTop['jam_pulang']?.toString() ?? '';
      if (nama.isNotEmpty) {
        return (jamMasuk.isNotEmpty && jamPulang.isNotEmpty)
            ? '$nama [$jamMasuk - $jamPulang]'
            : nama;
      }
    }

    // Prioritas 2: dari relasi eager-load Absensi→Shift (setelah absen)
    final shiftAbsen =
        _c.dataMasuk.value?['shift'] as Map<String, dynamic>? ??
        _c.dataPulang.value?['shift'] as Map<String, dynamic>?;
    if (shiftAbsen != null && shiftAbsen.isNotEmpty) {
      final nama = shiftAbsen['nama']?.toString() ?? '';
      final jamMasuk = shiftAbsen['jam_masuk']?.toString() ?? '';
      final jamPulang = shiftAbsen['jam_pulang']?.toString() ?? '';
      if (nama.isNotEmpty) {
        return (jamMasuk.isNotEmpty && jamPulang.isNotEmpty)
            ? '$nama [$jamMasuk - $jamPulang]'
            : nama;
      }
    }

    return 'Tidak ada shift';
  }

  /// Nama lokasi dari absensi hari ini (eager-load pusatLokasi).
  String _buildLokasiLabel() {
    final lokasi =
        _c.dataMasuk.value?['pusat_lokasi'] as Map<String, dynamic>? ??
        _c.dataPulang.value?['pusat_lokasi'] as Map<String, dynamic>?;
    return lokasi?['nama_lokasi']?.toString() ?? '';
  }

  // ─── TIME ROW ─────────────────────────────────────────────────────────────
  //
  // FIX foto absen:
  //   foto_absen_path berisi nama file saja, misal "masuk_john_1748000000.jpg"
  //   URL = "{origin}/storage/foto_absensi/{namaFile}"
  //   origin didapat dari base_url dengan strip '/api' di akhir.
  //
  //   Contoh: base_url = "http://192.168.1.1:8000/api"
  //           origin   = "http://192.168.1.1:8000"
  //           result   = "http://192.168.1.1:8000/storage/foto_absensi/masuk_john_123.jpg"

  bool _isOfflineData(Map<String, dynamic>? data) {
    return data != null && data['offline'] == true;
  }

  Widget _buildOfflinePendingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFF97316),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Menunggu sync',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFEA580C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Obx(() {
        final _ = _auth.employee.value;

        final masuk = _c.dataMasuk.value;
        final pulang = _c.dataPulang.value;

        final isMasukOffline = _isOfflineData(masuk);
        final isPulangOffline = _isOfflineData(pulang);

        final waktuMasuk = masuk != null && !isMasukOffline
            ? FormatterUtil.formatWaktuSimple(
                masuk['waktu_absen']?.toString() ?? '',
              )
            : '--:--';
        final waktuPulang = pulang != null && !isPulangOffline
            ? FormatterUtil.formatWaktuSimple(
                pulang['waktu_absen']?.toString() ?? '',
              )
            : '--:--';

        final fotoMasuk = !isMasukOffline
            ? _resolveAbsenFotoUrl(masuk) // ← hapus ?? _auth.photoUrl
            : null;
        final fotoPulang = !isPulangOffline
            ? _resolveAbsenFotoUrl(pulang) // ← hapus ?? _auth.photoUrl
            : null;
        final initial = _buildInitial();

        return Row(
          children: [
            // ── Start Time ──
            Expanded(
              child: Row(
                children: [
                  _buildNetworkAvatar(
                    fotoUrl: fotoMasuk,
                    initial: initial,
                    size: 44,
                    mirror: true,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Time',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A94A6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isMasukOffline)
                        _buildOfflinePendingBadge()
                      else
                        Row(
                          children: [
                            Text(
                              _c.sudahMasuk.value ? waktuMasuk : '--:--',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _c.sudahMasuk.value
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFF8A94A6),
                              ),
                            ),
                            if (_c.sudahMasuk.value) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF4CAF50),
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      if (_c.sudahMasuk.value &&
                          masuk != null &&
                          !isMasukOffline)
                        _buildStatusBadge(masuk),
                    ],
                  ),
                ],
              ),
            ),

            Container(height: 45, width: 1, color: const Color(0xFFE5E7EB)),

            // ── End Time ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    _buildNetworkAvatar(
                      fotoUrl: fotoPulang,
                      initial: initial,
                      size: 44,
                      dimmed: !_c.sudahPulang.value,
                      mirror: true,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End Time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (isPulangOffline)
                          _buildOfflinePendingBadge()
                        else
                          Row(
                            children: [
                              Text(
                                _c.sudahPulang.value ? waktuPulang : '--:--',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _c.sudahPulang.value
                                      ? const Color(0xFFFF7A30)
                                      : const Color(0xFFFF5252),
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (_c.sudahPulang.value)
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF4CAF50),
                                  size: 18,
                                )
                              else
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF8A94A6),
                                  size: 16,
                                ),
                            ],
                          ),
                        if (_c.sudahPulang.value &&
                            pulang != null &&
                            !isPulangOffline)
                          _buildStatusBadge(pulang),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> absensi) {
    final status = absensi['status']?.toString() ?? 'tepat_waktu';
    final menitTerlambat = (absensi['menit_terlambat'] as num?)?.toInt() ?? 0;
    final menitLembur = (absensi['menit_lembur'] as num?)?.toInt() ?? 0;

    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'terlambat':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFE53935);
        label = 'Terlambat ${menitTerlambat}m';
        break;
      case 'lembur':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF6F00);
        label = 'Lembur ${menitLembur}m';
        break;
      default:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Tepat Waktu';
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── RECORD BUTTON ────────────────────────────────────────────────────────

  Widget _buildRecordButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Obx(() {
        final sudahMasuk = _c.sudahMasuk.value;
        final sudahPulang = _c.sudahPulang.value;
        final isSubmitting = _c.isSubmitting.value;

        // ── State: Absensi Selesai ──
        if (sudahMasuk && sudahPulang) {
          final msg = _getDoneMessage();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Kiri: avatar emoji dalam kotak
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFBBF7D0),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(msg['emoji']!, style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                // Tengah: teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['title']!,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        msg['sub']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Kanan: pill status
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Full Hadir',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '🔥 On fire!',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // ── State: Absen Masuk / Pulang ──
        String label;
        Color bgColor;
        VoidCallback? onTap;

        if (!sudahMasuk) {
          label = 'Absen Masuk';
          bgColor = const Color.fromARGB(255, 76, 159, 241);
          onTap = isSubmitting
              ? null
              : () async {
                  await _c.prosesAbsensi('masuk');
                  if (_c.sudahMasuk.value) _c.fetchRiwayatAbsensi();
                };
        } else {
          label = 'Absen Pulang';
          bgColor = const Color.fromARGB(255, 243, 110, 48);
          onTap = isSubmitting
              ? null
              : () async {
                  await _c.prosesAbsensi('pulang');
                  if (_c.sudahPulang.value) _c.fetchRiwayatAbsensi();
                };
        }

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: onTap != null
                  ? [
                      BoxShadow(
                        color: bgColor.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  // ─── RIWAYAT LIST ─────────────────────────────────────────────────────────

  Widget _buildRiwayatList() {
    return Obx(() {
      final isLoading = _c.isLoadingRiwayat.value;
      final riwayat = _c.riwayatAbsensi;

      if (isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF7A30),
              strokeWidth: 2,
            ),
          ),
        );
      }

      if (riwayat.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Belum ada riwayat absensi',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ),
        );
      }

      final items = riwayat.take(3).toList();
      return Column(
        children: items.asMap().entries.map((e) {
          return _buildRiwayatItem(items[e.key], e.key == items.length - 1);
        }).toList(),
      );
    });
  }

  // ─── RIWAYAT ITEM ─────────────────────────────────────────────────────────

  Widget _buildRiwayatItem(Map<String, dynamic> item, bool isLast) {
    final fotoAbsenUrl = _resolveAbsenFotoUrl(item);
    final fotoTampil = fotoAbsenUrl != null && fotoAbsenUrl.isNotEmpty
        ? fotoAbsenUrl
        : _auth.photoUrl.isNotEmpty
        ? _auth.photoUrl
        : null;

    final waktu = FormatterUtil.formatWaktuSimple(
      item['waktu_absen']?.toString() ?? '',
    );

    final tanggalRaw =
        item['tanggal_absen']?.toString() ??
        item['waktu_absen']?.toString() ??
        '';
    final tanggal = tanggalRaw.isNotEmpty
        ? _formatTanggalDisplay(tanggalRaw)
        : '-';

    final namaLokasi = _c.getNamaLokasiDariRiwayat(item);
    final namaShift = _c.getNamaShiftDariRiwayat(item);
    final status = item['status']?.toString() ?? 'tepat_waktu';
    final tipeAbsen = item['tipe_absen']?.toString() ?? '';
    final menitTerlambat = (item['menit_terlambat'] as num?)?.toInt() ?? 0;
    final menitLembur = (item['menit_lembur'] as num?)?.toInt() ?? 0;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'terlambat':
        statusColor = const Color(0xFFE53935);
        statusLabel = menitTerlambat > 0
            ? 'Terlambat ${menitTerlambat}m'
            : 'Terlambat';
        break;
      case 'lembur':
        statusColor = const Color(0xFFFF6F00);
        statusLabel = menitLembur > 0 ? 'Lembur ${menitLembur}m' : 'Lembur';
        break;
      default:
        statusColor = const Color(0xFF4CAF50);
        statusLabel = 'Tepat Waktu';
    }

    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                _buildNetworkAvatar(
                  fotoUrl: fotoTampil,
                  initial: _buildInitial(),
                  size: 52,
                  mirror: true,
                ),
                if (tipeAbsen.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: tipeAbsen == 'masuk'
                            ? const Color(0xFF1E88E5)
                            : const Color(0xFFFF7A30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tipeAbsen == 'masuk' ? 'IN' : 'OUT',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tanggal,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        waktu,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _statusIcon(Icons.location_on, const Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                      _statusIcon(Icons.face, const Color(0xFF4CAF50)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 11,
                        color: Color(0xFF8A94A6),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          _buildLokasiRiwayat(item),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A94A6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (namaShift.isNotEmpty && namaShift != '-') ...[
                        const Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            namaShift,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8A94A6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF8A94A6), // ← abu-abu, beda dari status
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(IconData icon, Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }

  Widget _buildViewMore() {
    return InkWell(
      onTap: () {
        _c.fetchRiwayatAbsensi();
        Get.toNamed('/user/riwayat');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
        ),
        child: const Center(
          child: Text(
            'View More',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1F36),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHideDetail(StateSetter setInner) {
    return InkWell(
      onTap: () {
        setInner(() {});
        setState(() => _showDetail = !_showDetail);
      },
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB),
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showDetail ? 'Hide Detail' : 'Show Detail',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1F36),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showDetail ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: const Color(0xFF1A1F36),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AVATAR ───────────────────────────────────────────────────────────────

  Widget _buildNetworkAvatar({
    required String? fotoUrl,
    required String initial,
    required double size,
    bool dimmed = false,
    bool mirror = false,
  }) {
    final hasPhoto = fotoUrl != null && fotoUrl.isNotEmpty;

    if (!hasPhoto) {
      return _fallbackAvatar(initial, size, dimmed);
    }

    Widget photo = ClipOval(
      child: Image.network(
        fotoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        color: dimmed ? Colors.white.withOpacity(0.45) : null,
        colorBlendMode: dimmed ? BlendMode.lighten : null,
        errorBuilder: (_, __, ___) => _fallbackAvatar(initial, size, dimmed),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _fallbackAvatar(initial, size, dimmed);
        },
      ),
    );

    if (mirror) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0),
        child: photo,
      );
    }
    return photo;
  }

  Widget _fallbackAvatar(String initial, double size, bool dimmed) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFD0D5E0),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(dimmed ? 0.45 : 1),
          ),
        ),
      ),
    );
  }

  // ─── UTILS ────────────────────────────────────────────────────────────────

  String _buildInitial() {
    final name = _auth.employeeFullName.isNotEmpty
        ? _auth.employeeFullName
        : _auth.userName;
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _buildLokasiRiwayat(Map<String, dynamic> item) {
    // Ambil alamat dari relasi permintaan_absen jika ada
    final alamat =
        item['permintaan_absen']?['alamat_pengajuan']?.toString() ?? '';
    if (alamat.isNotEmpty) return alamat;

    // Fallback ke nama pusat lokasi
    return item['pusat_lokasi']?['nama_lokasi']?.toString() ?? '-';
  }

  /// FIX: Resolve foto_absen_path ke URL publik.
  ///
  /// foto_absen_path = nama file saja → "masuk_john_1748000000.jpg"
  /// URL target      = "{origin}/storage/foto_absensi/{namaFile}"
  ///
  /// base_url di storage = "http://192.168.1.1:8000/api"
  /// origin              = "http://192.168.1.1:8000"  (strip '/api')
  String? _resolveAbsenFotoUrl(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Prioritas: gunakan foto_absen_url dari accessor backend
    final url = data['foto_absen_url']?.toString();
    if (url != null && url.isNotEmpty) return url;

    // Fallback: build manual dari foto_absen_path
    final path = data['foto_absen_path']?.toString();
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }

      String base = _auth.box.read('base_url')?.toString() ?? '';
      if (base.isEmpty) base = _c.baseUrl;

      if (base.isNotEmpty) {
        final origin = base.replaceFirst(RegExp(r'/api/?$'), '');

        // Jika path sudah ada subfolder → langsung pakai
        if (path.contains('/')) {
          return '$origin/storage/$path';
        }

        // Path lama hanya nama file → tambah prefix folder
        return '$origin/storage/foto_absensi/$path';
      }
    }

    return null;
  }

  String _formatTanggalDisplay(String raw) {
    try {
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
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
        final dt = DateTime.parse(raw);
        return '${dayNames[dt.weekday - 1]}, ${dt.day} ${monthNames[dt.month - 1]} ${dt.year}';
      }

      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(raw)) {
        final parts = raw.split('-');
        final dt = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        return '${dayNames[dt.weekday - 1]}, ${dt.day} ${monthNames[dt.month - 1]} ${dt.year}';
      }

      final dt = DateTime.parse(raw);
      final wib = dt.toUtc().add(const Duration(hours: 7));
      return '${dayNames[wib.weekday - 1]}, ${wib.day} ${monthNames[wib.month - 1]} ${wib.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _GradientBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;
  final double gap;

  const _GradientBorderPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter old) =>
      old.strokeWidth != strokeWidth || old.gap != gap;
}
