import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/user/userPage/widget/info_card_widget.dart';
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
    // Status bar mengikuti warna gradient biru
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1565C0),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.fetchRiwayatAbsensi();
    });
  }

  @override
  void dispose() {
    // Kembalikan status bar ke default saat meninggalkan halaman
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
            child: Column(
              children: [
                // ── HEADER BIRU — FIXED, tidak ikut scroll ──
                _buildGreetingWithHeader(),

                // ── KONTEN ABU — scrollable ──
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        _c.cekStatusHariIni(),
                        _c.fetchRiwayatAbsensi(),
                      ]);
                    },
                    color: const Color(0xFFFF7A30),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                            _buildMainCard(),
                            const SizedBox(height: 16),
                            const InfoCardWidget(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── GREETING + HEADER (digabung dalam satu banner biru) ───────────────────

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
      final user = Map<String, dynamic>.from(_auth.user);
      final name = user['name']?.toString() ?? 'User';
      final firstName = name.split(' ').first;
      final role =
          user['jabatan']?.toString() ?? user['role']?.toString() ?? '';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

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
        // ← Warna biru langsung di sini, bukan dari Stack background
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
                // Decorative circles
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
                // Konten utama
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Baris 1: Greeting + Search ──
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
                        // Search button
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Divider tipis ──
                    Container(height: 1, color: Colors.white.withOpacity(0.15)),

                    const SizedBox(height: 16),

                    // ── Baris 2: Avatar + Nama + Ikon ──
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (role.isNotEmpty)
                                Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.75),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _whiteIconBtn(Icons.calendar_today_outlined),
                        const SizedBox(width: 8),
                        _whiteIconBtn(Icons.notifications_none_outlined),
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

  // ─── DATE & SHIFT ─────────────────────────────────────────────────────────

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
            final shift =
                _c.dataMasuk.value?['shift']?.toString() ??
                'Shift 07:30-17:00 [07:30 - 17:00]';
            return Text(
              'Shift: $shift',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
            );
          }),
        ],
      ),
    );
  }

  // ─── TIME ROW ─────────────────────────────────────────────────────────────

  Widget _buildTimeRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Obx(() {
        final masuk = _c.dataMasuk.value;
        final pulang = _c.dataPulang.value;

        // Waktu dalam WIB menggunakan FormatterUtil
        final waktuMasuk = masuk != null
            ? FormatterUtil.formatWaktuSimple(
                masuk['waktu_absen']?.toString() ?? '',
              )
            : '--:--';
        final waktuPulang = pulang != null
            ? FormatterUtil.formatWaktuSimple(
                pulang['waktu_absen']?.toString() ?? '',
              )
            : '--:--';

        // Foto dari data absensi masuk & pulang
        final fotoMasuk = _pickFoto(masuk);
        final fotoPulang = _pickFoto(pulang);
        final initial = _initials();

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
                              Icons.check_circle,
                              color: Color(0xFF4CAF50),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
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
                                Icons.check_circle,
                                color: Color(0xFF4CAF50),
                                size: 16,
                              )
                            else
                              const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF8A94A6),
                                size: 16,
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
        );
      }),
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

        String label;
        Color bgColor;
        VoidCallback? onTap;

        if (!sudahMasuk) {
          label = 'Absen Masuk';
          bgColor = const Color(0xFF1976D2);
          onTap = isSubmitting ? null : () => _c.prosesAbsensi('masuk');
        } else if (!sudahPulang) {
          label = 'Absen Pulang';
          bgColor = const Color(0xFFFF7A30);
          onTap = isSubmitting ? null : () => _c.prosesAbsensi('pulang');
        } else {
          label = 'Absensi Selesai';
          bgColor = const Color(0xFF9CA3AF);
          onTap = null;
        }

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildRiwayatItem(Map<String, dynamic> item, bool isLast) {
    // Field foto di Laravel adalah 'foto_wajah' — sudah berupa full URL
    final fotoUrl = _pickFoto(item);

    // Waktu dalam WIB
    final waktu = FormatterUtil.formatWaktuSimple(
      item['waktu_absen']?.toString() ?? '',
    );

    // Tanggal
    final tanggalRaw =
        item['tanggal_formatted']?.toString() ??
        item['tanggal']?.toString() ??
        item['waktu_absen']
            ?.toString() ?? // gunakan waktu_absen jika tanggal tidak ada
        item['created_at']?.toString() ??
        '';
    final tanggal = tanggalRaw.isNotEmpty
        ? _formatTanggalDisplay(tanggalRaw)
        : '-';

    final status = item['status']?.toString() ?? 'Has been processed';

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
            // Foto absensi
            _buildNetworkAvatar(
              fotoUrl: fotoUrl,
              initial: _initials(),
              size: 52,
            ),
            const SizedBox(width: 12),

            // Info
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
                  const SizedBox(height: 5),
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
                      _statusIcon(Icons.crop_free, const Color(0xFF4CAF50)),
                    ],
                  ),
                ],
              ),
            ),

            // Status
            Text(
              status,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8A94A6)),
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

  // ─── VIEW MORE ────────────────────────────────────────────────────────────

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

  // ─── HIDE / SHOW DETAIL ───────────────────────────────────────────────────

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

  // ─── SHARED AVATAR WIDGET ─────────────────────────────────────────────────

  /// Widget avatar universal — pakai foto URL jika ada, fallback ke inisial
  Widget _buildNetworkAvatar({
    required String? fotoUrl,
    required String initial,
    required double size,
    bool dimmed = false,
  }) {
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          fotoUrl,
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
    }
    return _fallbackAvatar(initial, size, dimmed);
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

  String _initials() {
    final name =
        Map<String, dynamic>.from(_auth.user)['name']?.toString() ?? 'U';
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  /// Ambil URL foto dari response API Laravel
  /// Field di DB adalah 'foto_wajah' — disimpan sebagai full URL
  String? _pickFoto(Map<String, dynamic>? data) {
    if (data == null) return null;
    for (final k in [
      'foto_wajah', // ← field utama di tabel absensi Laravel
      'foto_wajah_url',
      'foto_url',
      'foto',
      'photo_url',
      'photo',
      'gambar_url',
      'gambar',
      'image_url',
      'image',
    ]) {
      final v = data[k]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Format tanggal untuk display di riwayat: "Fri, 20 Mar 2026"
  String _formatTanggalDisplay(String raw) {
    try {
      // Jika sudah berformat dd-MM-yyyy dari FormatterUtil
      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(raw)) {
        final parts = raw.split('-');
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
        final dt = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        return '${dayNames[dt.weekday - 1]}, ${dt.day} ${monthNames[dt.month - 1]} ${dt.year}';
      }
      // Coba parse ISO date
      final dt = DateTime.parse(raw);
      // Konversi ke WIB
      final wib = dt.toUtc().add(const Duration(hours: 7));
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
      return '${dayNames[wib.weekday - 1]}, ${wib.day} ${monthNames[wib.month - 1]} ${wib.year}';
    } catch (_) {
      return raw;
    }
  }
}
