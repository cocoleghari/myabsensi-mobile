import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/user/absenPage/modals/detail_kalender_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class AbsensiHarian {
  final DateTime tanggal;
  final String? waktuMasuk; // "07:27"
  final String? waktuPulang; // "17:07"
  final String? statusMasuk; // tepat_waktu / terlambat
  final String? statusPulang; // tepat_waktu / lembur
  final bool isHoliday;
  final String? holidayName;
  final bool
  hasMissedAbsen; // absen tidak lengkap (ada masuk, tidak ada pulang / sebaliknya)
  final Map<String, dynamic>? rawMasuk;
  final Map<String, dynamic>? rawPulang;

  const AbsensiHarian({
    required this.tanggal,
    this.waktuMasuk,
    this.waktuPulang,
    this.statusMasuk,
    this.statusPulang,
    this.isHoliday = false,
    this.holidayName,
    this.hasMissedAbsen = false,
    this.rawMasuk,
    this.rawPulang,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class MyCalendarController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();
  final UserLokasiController _lokasi = Get.find<UserLokasiController>();

  var currentMonth = DateTime.now().obs;
  var isLoading = false.obs;
  var absensiMap = <String, AbsensiHarian>{}.obs; // key: "yyyy-MM-dd"

  @override
  void onInit() {
    super.onInit();
    fetchMonthData(currentMonth.value);
  }

  void prevMonth() {
    final d = currentMonth.value;
    currentMonth.value = DateTime(d.year, d.month - 1);
    fetchMonthData(currentMonth.value);
  }

  void nextMonth() {
    final d = currentMonth.value;
    currentMonth.value = DateTime(d.year, d.month + 1);
    fetchMonthData(currentMonth.value);
  }

  void goToToday() {
    currentMonth.value = DateTime.now();
    fetchMonthData(currentMonth.value);
  }

  /// Fetch riwayat absensi bulan ini dari controller atau API.
  /// Jika UserLokasiController sudah punya riwayatAbsensi, kita filter by bulan.
  /// Jika tidak, hit API sendiri.
  Future<void> fetchMonthData(DateTime month) async {
    isLoading.value = true;
    absensiMap.clear();

    try {
      await _lokasi.fetchRiwayatAbsensi();

      final riwayat = _lokasi.riwayatAbsensi;
      debugPrint('RIWAYAT COUNT: ${riwayat.length}');
      for (final item in riwayat) {
        debugPrint(
          '>>> tipe: ${item['tipe_absen']} | tanggal_absen: ${item['tanggal_absen']}',
        );
      }

      if (riwayat.isNotEmpty) {
        _parseRiwayat(riwayat, month);
      } else {
        await _fetchFromApi(month);
      }
    } catch (e) {
      debugPrint('MyCalendarController fetchMonthData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _parseRiwayat(List riwayat, DateTime month) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in riwayat) {
      final tanggalRaw = item['tanggal_absen']?.toString() ?? '';
      if (tanggalRaw.isEmpty) continue;

      DateTime dt;
      try {
        dt = DateTime.parse(tanggalRaw.substring(0, 10));
      } catch (_) {
        continue;
      }

      if (dt.year != month.year || dt.month != month.month) continue;

      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(Map<String, dynamic>.from(item));
    }

    for (final entry in grouped.entries) {
      final key = entry.key;
      final items = entry.value;
      final dt = DateTime.parse(key);

      Map<String, dynamic>? masuk;
      Map<String, dynamic>? pulang;

      for (final it in items) {
        final tipe = it['tipe_absen']?.toString() ?? '';
        if (tipe == 'masuk') masuk = it;
        if (tipe == 'pulang') pulang = it;
      }

      absensiMap[key] = AbsensiHarian(
        tanggal: dt,
        waktuMasuk: masuk != null
            ? _parseWaktu(masuk['waktu_absen']?.toString())
            : null,
        waktuPulang: pulang != null
            ? _parseWaktu(pulang['waktu_absen']?.toString())
            : null,
        statusMasuk: masuk?['status']?.toString(),
        statusPulang: pulang?['status']?.toString(),
        hasMissedAbsen:
            (masuk != null && pulang == null) && dt.isBefore(DateTime.now()),
        rawMasuk: masuk,
        rawPulang: pulang,
      );
    }
  }

  Future<void> _fetchFromApi(DateTime month) async {
    try {
      final baseUrl = _auth.box.read('base_url')?.toString() ?? '';
      if (baseUrl.isEmpty) return;

      final uri = Uri.parse(
        '$baseUrl/user/riwayat-absensi?bulan=${month.month}&tahun=${month.year}&per_page=100',
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer ${_auth.token.value}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['riwayat'] ?? [];
        _parseRiwayat(list, month);
      }
    } catch (e) {
      debugPrint('_fetchFromApi error: $e');
    }
  }

  String? _parseWaktu(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      if (raw.contains(':')) return raw.substring(0, 5);
      return null;
    }
  }

  AbsensiHarian? getHari(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return absensiMap[key];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class MyCalendarPage extends StatelessWidget {
  const MyCalendarPage({super.key});

  static void show() {
    // Daftarkan controller jika belum ada
    if (!Get.isRegistered<MyCalendarController>()) {
      Get.put(MyCalendarController());
    } else {
      Get.find<MyCalendarController>().fetchMonthData(
        Get.find<MyCalendarController>().currentMonth.value,
      );
    }
    Get.to(
      () => const MyCalendarPage(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MyCalendarController>();
    final auth = Get.find<AuthController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildProfileCard(auth),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMonthNav(c),
                      _buildDayHeader(),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF0F0F0),
                      ),
                      Expanded(
                        child: Obx(() {
                          if (c.isLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1E88E5),
                                strokeWidth: 2,
                              ),
                            );
                          }
                          return _buildCalendarGrid(c);
                        }),
                      ),
                      _buildLegend(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Aksi tambah — bisa diarahkan ke absen manual / form izin
          },
          backgroundColor: const Color(0xFF1E88E5),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF1A1F36),
          ),
          const Text(
            'My Calendar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F36),
            ),
          ),
          const Spacer(),
          // Grid icon (dekoratif / bisa untuk switch view)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBDEFB), width: 1),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Color(0xFF1E88E5),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          // Settings icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF8A94A6),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile Card ─────────────────────────────────────────────────────────

  Widget _buildProfileCard(AuthController auth) {
    return Obx(() {
      final name = auth.employeeFullName.isNotEmpty
          ? auth.employeeFullName
          : auth.userName;
      final jabatan = auth.positionName.isNotEmpty
          ? auth.positionName
          : auth.departmentName.isNotEmpty
          ? auth.departmentName
          : auth.userRole;
      final photoUrl = auth.photoUrl;
      final nameParts = name.trim().split(' ');
      final initial = name.isEmpty
          ? 'U'
          : nameParts.length == 1
          ? nameParts[0][0].toUpperCase()
          : (nameParts[0][0] + nameParts[1][0]).toUpperCase();

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8EDF5),
              ),
              child: photoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initialAvatar(initial),
                      ),
                    )
                  : _initialAvatar(initial),
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
                      color: Color(0xFF1A1F36),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (jabatan.isNotEmpty)
                    Text(
                      jabatan,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A94A6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Team icon button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBDEFB), width: 1),
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                color: Color(0xFF1E88E5),
                size: 18,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _initialAvatar(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8A94A6),
        ),
      ),
    );
  }

  // ── Month Navigation ─────────────────────────────────────────────────────

  Widget _buildMonthNav(MyCalendarController c) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Obx(() {
      final month = c.currentMonth.value;
      final now = DateTime.now();
      final isCurrentMonth = month.year == now.year && month.month == now.month;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            Text(
              '${monthNames[month.month - 1]} ${month.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
            ),
            const Spacer(),
            // Today button
            GestureDetector(
              onTap: c.goToToday,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCurrentMonth
                      ? const Color(0xFF1E88E5)
                      : const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCurrentMonth
                        ? const Color(0xFF1E88E5)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCurrentMonth
                        ? Colors.white
                        : const Color(0xFF1E88E5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _navBtn(Icons.chevron_left_rounded, c.prevMonth),
            const SizedBox(width: 4),
            _navBtn(Icons.chevron_right_rounded, c.nextMonth),
          ],
        ),
      );
    });
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1A1F36)),
      ),
    );
  }

  // ── Day Header ───────────────────────────────────────────────────────────

  Widget _buildDayHeader() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: days.map((d) {
          final isWeekend = d == 'Sun' || d == 'Sat';
          return Expanded(
            child: Center(
              child: Text(
                d,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isWeekend
                      ? const Color(0xFF1E88E5).withOpacity(0.7)
                      : const Color(0xFF8A94A6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Calendar Grid ─────────────────────────────────────────────────────────

  Widget _buildCalendarGrid(MyCalendarController c) {
    final month = c.currentMonth.value;
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    // firstDay.weekday: Mon=1..Sun=7 → kita perlu Sun=0
    int startOffset = firstDay.weekday % 7; // Sun=0, Mon=1, ..., Sat=6

    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellHeight = constraints.maxHeight / rows;

        return Column(
          children: List.generate(rows, (row) {
            return Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - startOffset + 1;

                  if (dayNum < 1 || dayNum > lastDay.day) {
                    return Expanded(child: _emptyCell(col));
                  }

                  final date = DateTime(month.year, month.month, dayNum);
                  final absensi = c.getHari(date);
                  final isToday = _isToday(date);
                  final isWeekend = col == 0 || col == 6;
                  final isFuture = date.isAfter(DateTime.now());

                  return Expanded(
                    child: _buildDayCell(
                      date: date,
                      absensi: absensi,
                      isToday: isToday,
                      isWeekend: isWeekend,
                      isFuture: isFuture,
                      col: col,
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _emptyCell(int col) {
    final isWeekend = col == 0 || col == 6;
    return Container(
      decoration: BoxDecoration(
        color: isWeekend ? const Color(0xFFFFF5F0) : Colors.transparent,
        border: const Border(
          top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
          right: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required AbsensiHarian? absensi,
    required bool isToday,
    required bool isWeekend,
    required bool isFuture,
    required int col,
  }) {
    Color bgColor;
    if (isToday) {
      bgColor = const Color(0xFFE3F2FD);
    } else if (isWeekend) {
      bgColor = const Color(0xFFF5F9FF);
    } else {
      bgColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: () {
        // Semua tanggal bisa diklik (termasuk future & weekend)
        DetailKalenderPage.show(date, absensi: absensi);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: const BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
            right: const BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
            left: isToday
                ? const BorderSide(color: Color(0xFF1E88E5), width: 2)
                : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Day number
              _buildDayNumber(date.day, isToday, isWeekend),
              const SizedBox(height: 2),
              // Absensi time chips
              if (absensi != null) ...[
                if (absensi.waktuMasuk != null)
                  _buildTimeChip(
                    absensi.waktuMasuk!,
                    isMasuk: true,
                    isLate: absensi.statusMasuk == 'terlambat',
                  ),
                if (absensi.waktuPulang != null)
                  _buildTimeChip(
                    absensi.waktuPulang!,
                    isMasuk: false,
                    isLate: absensi.statusPulang == 'lembur',
                  ),
              ],
              // Holiday dot
              if (absensi?.isHoliday == true)
                _buildHolidayDot(absensi!.holidayName),
              // Missed badge
              if (absensi?.hasMissedAbsen == true) _buildMissedBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayNumber(int day, bool isToday, bool isWeekend) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: isToday
            ? Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : Text(
                '$day',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isWeekend ? FontWeight.w600 : FontWeight.w500,
                  color: isWeekend
                      ? const Color(0xFF1E88E5)
                      : const Color(0xFF1A1F36),
                ),
              ),
      ),
    );
  }

  Widget _buildTimeChip(
    String time, {
    required bool isMasuk,
    bool isLate = false,
  }) {
    final Color bg = isMasuk
        ? (isLate ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9))
        : (isLate ? const Color(0xFFFFF3E0) : const Color(0xFFFFEBEE));
    final Color text = isMasuk
        ? (isLate ? const Color(0xFFE53935) : const Color(0xFF2E7D32))
        : (isLate ? const Color(0xFFFF6F00) : const Color(0xFF1E88E5));

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        time,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }

  Widget _buildHolidayDot(String? name) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFE53935),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            name?.length != null && name!.length > 6
                ? '${name.substring(0, 6)}...'
                : (name ?? ''),
            style: const TextStyle(fontSize: 7, color: Color(0xFFE53935)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMissedBadge() {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFFFF5252),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.priority_high_rounded, size: 12, color: Colors.white),
      ),
    );
  }

  // ── Legend ───────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(
            const Color(0xFFE8F5E9),
            const Color(0xFF2E7D32),
            'Masuk',
          ),
          const SizedBox(width: 12),
          _legendItem(
            const Color(0xFFFFEBEE),
            const Color(0xFF1E88E5),
            'Pulang',
          ),
          const SizedBox(width: 12),
          _legendItem(
            const Color(0xFFFFEBEE),
            const Color(0xFFE53935),
            'Terlambat',
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Peringatan',
                style: TextStyle(fontSize: 10, color: Color(0xFF8A94A6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color text, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '00:00',
            style: TextStyle(
              fontSize: 8,
              color: text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF8A94A6)),
        ),
      ],
    );
  }
}
