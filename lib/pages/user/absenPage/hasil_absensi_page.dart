import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/user_lokasi_controller.dart';

class HasilAbsensiPage extends StatefulWidget {
  final String tipe;
  final bool isOffline;

  const HasilAbsensiPage({
    super.key,
    required this.tipe,
    this.isOffline = false,
  });

  @override
  State<HasilAbsensiPage> createState() => _HasilAbsensiPageState();
}

class _HasilAbsensiPageState extends State<HasilAbsensiPage> {
  final controller = Get.find<UserLokasiController>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => controller.fetchRiwayatAbsensi());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Record Attendance Result',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildTabs(),
              const SizedBox(height: 16),

              // Notif sukses
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance saved',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Horaayyy! Your attendance successfully recorded',
                      style: TextStyle(color: Colors.green[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Daftar riwayat
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingRiwayat.value) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            'Memuat riwayat...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final riwayat = controller.riwayatAbsensi;
                  if (riwayat.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada riwayat',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final grouped = _groupByDate(riwayat);

                  return ListView.separated(
                    itemCount: grouped.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = grouped.entries.elementAt(index);
                      final tanggal = entry.key;
                      final items = entry.value;

                      // Ambil data masuk & pulang dari riwayat
                      final masuk = items.firstWhereOrNull(
                        (e) => e['tipe_absen'] == 'masuk',
                      );
                      final pulang = items.firstWhereOrNull(
                        (e) => e['tipe_absen'] == 'pulang',
                      );

                      return _buildAttendanceCard(
                        label: _isToday(tanggal)
                            ? 'Today (${_formatLabel(tanggal)})'
                            : _formatLabel(tanggal),
                        masuk: masuk,
                        pulang: pulang,
                        isToday: _isToday(tanggal),
                      );
                    },
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Hanya satu tombol — Back to Home
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    controller.cekStatusHariIni();
                    // Kembali ke halaman utama dengan offAll
                    Get.offAllNamed('/user');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: const Color(0xFF1976D2),
                    side: const BorderSide(
                      color: const Color(0xFF1976D2),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _buildTab('Result', false),
        const SizedBox(width: 8),
        _buildTab('Today', true),
        const SizedBox(width: 8),
        _buildTab('Last 7 Days', false, hasDot: true),
      ],
    );
  }

  Widget _buildTab(String label, bool isActive, {bool hasDot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1976D2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF1976D2) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.white : Colors.grey[700],
            ),
          ),
          if (hasDot) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceCard({
    required String label,
    required Map<String, dynamic>? masuk,
    required Map<String, dynamic>? pulang,
    required bool isToday,
  }) {
    // Ambil jam dari waktu_absen
    final jamMasuk = masuk != null ? _extractJam(masuk['waktu_absen']) : null;
    final jamPulang = pulang != null
        ? _extractJam(pulang['waktu_absen'])
        : null;

    // Ambil foto dari masing-masing record absensi
    final fotoMasuk = masuk?['foto_absen_url']?.toString();
    final fotoPulang = pulang?['foto_absen_url']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (!isToday)
                const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.grey,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // ── START TIME (jam masuk) ──────────────────────────
              Expanded(
                child: Row(
                  children: [
                    _buildAvatar(fotoMasuk),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              jamMasuk ?? '--:--',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: jamMasuk != null
                                    ? Colors.green[600]
                                    : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              jamMasuk != null
                                  ? Icons.check_circle
                                  : Icons.location_on_outlined,
                              color: jamMasuk != null
                                  ? Colors.green[600]
                                  : Colors.grey[400],
                              size: jamMasuk != null ? 16 : 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Divider vertikal
              Container(height: 44, width: 1, color: Colors.grey[200]),

              // ── END TIME (jam pulang) ───────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      _buildAvatar(fotoPulang),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Time',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                jamPulang ?? '--:--',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: jamPulang != null
                                      ? Colors.blue[600]
                                      : Colors.grey[400],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                jamPulang != null
                                    ? Icons.check_circle
                                    : Icons.location_on_outlined,
                                color: jamPulang != null
                                    ? Colors.blue[400]
                                    : Colors.grey[400],
                                size: jamPulang != null ? 16 : 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? fotoUrl) {
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return ClipOval(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0),
          child: Image.network(
            fotoUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
          ),
        ),
      );
    }
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    final nama = controller.auth.user['name']?.toString() ?? 'U';
    final initials = nama
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[200],
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // Kelompokkan riwayat berdasarkan tanggal, urutkan terbaru di atas
  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> riwayat,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in riwayat) {
      final waktu = item['waktu_absen']?.toString() ?? '';
      final tanggal = waktu.length >= 10 ? waktu.substring(0, 10) : waktu;
      grouped.putIfAbsent(tanggal, () => []).add(item);
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  bool _isToday(String tanggal) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return tanggal == todayStr;
  }

  // Ekstrak jam:menit dari string waktu_absen
  String _extractJam(dynamic waktu) {
    if (waktu == null) return '--:--';
    try {
      final dt = DateTime.parse(waktu.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      final s = waktu.toString();
      return s.length >= 16 ? s.substring(11, 16) : '--:--';
    }
  }

  String _formatLabel(String tanggal) {
    try {
      final dt = DateTime.parse(tanggal);
      const hari = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const bulan = [
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
      return '${hari[dt.weekday - 1]}, ${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return tanggal;
    }
  }
}
