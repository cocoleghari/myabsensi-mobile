import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/utils/riwayat_formatter.dart';
import 'package:myabsensi_mobile/utils/formatter_util.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RiwayatDetailDialog {
  static const String baseUrl = 'http://192.168.0.103:8000/api';

  static void show({
    required BuildContext context,
    required Map<String, dynamic>? dataMasuk,
    required Map<String, dynamic>? dataPulang,
    required int no,
    required String tanggal,
  }) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(28),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header biru ──
                _buildHeader(no, tanggal),

                // ── Tab + konten ──
                DefaultTabController(
                  length: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildTabBar(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 420,
                        child: TabBarView(
                          children: [
                            dataMasuk != null
                                ? _DetailContent(item: dataMasuk, tipe: 'masuk')
                                : const _EmptyContent(
                                    message: 'Belum absen masuk',
                                  ),
                            dataPulang != null
                                ? _DetailContent(
                                    item: dataPulang,
                                    tipe: 'pulang',
                                  )
                                : const _EmptyContent(
                                    message: 'Belum absen pulang',
                                  ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        child: _buildCloseButton(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────

  static Widget _buildHeader(int no, String tanggal) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 22),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$no',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Absensi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      RiwayatFormatter.formatTanggal(tanggal),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAB BAR ─────────────────────────────────────────────────────────────

  static Widget _buildTabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF8A94A6),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Absen Masuk'),
          Tab(text: 'Absen Pulang'),
        ],
      ),
    );
  }

  // ── CLOSE BUTTON ────────────────────────────────────────────────────────

  static Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Tutup',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── DETAIL CONTENT ──────────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  final Map<String, dynamic> item;
  final String tipe;

  const _DetailContent({required this.item, required this.tipe});

  @override
  Widget build(BuildContext context) {
    final data = _parseData(item);
    final bool isMasuk = tipe == 'masuk';
    final Color themeColor = isMasuk
        ? const Color(0xFF1565C0)
        : const Color(0xFFE65100);
    final Color themeBg = isMasuk
        ? const Color(0xFF1565C0)
        : const Color(0xFFE65100);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Waktu card ──
          _buildWaktuCard(themeBg, data.waktu, isMasuk),
          const SizedBox(height: 14),

          // ── Info card ──
          _buildInfoCard(themeColor, data),
          const SizedBox(height: 14),

          // ── Peta lokasi ──
          if (data.lokasiLatLng != null) ...[
            _sectionLabel('Lokasi Kantor'),
            const SizedBox(height: 8),
            _buildMapPreview(
              latLng: data.lokasiLatLng!,
              markerColor: isMasuk
                  ? BitmapDescriptor.hueBlue
                  : BitmapDescriptor.hueOrange,
            ),
            const SizedBox(height: 14),
          ],

          // ── Peta posisi kamu ──
          if (data.kamuLatLng != null) ...[
            _sectionLabel('Posisi Kamu'),
            const SizedBox(height: 8),
            _buildMapPreview(
              latLng: data.kamuLatLng!,
              markerColor: BitmapDescriptor.hueGreen,
            ),
            const SizedBox(height: 14),
          ],

          // ── Foto bukti ──
          if (data.fotoWajah.isNotEmpty) ...[
            _sectionLabel('Foto Bukti'),
            const SizedBox(height: 8),
            _buildFotoCard(data.fotoWajah),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8A94A6),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildWaktuCard(Color themeColor, String waktu, bool isMasuk) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isMasuk ? Icons.login_rounded : Icons.logout_rounded,
              color: themeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMasuk ? 'Waktu Absen Masuk' : 'Waktu Absen Pulang',
                  style: TextStyle(
                    fontSize: 11,
                    color: themeColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  waktu,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Color themeColor, _ParsedData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Lokasi',
            value: data.lokasi,
            color: themeColor,
            isLast: false,
          ),
          _buildInfoRow(
            icon: Icons.pin_drop_outlined,
            label: 'Koordinat Lokasi',
            value: data.koordinatLokasi,
            color: themeColor,
            isLast: false,
          ),
          _buildInfoRow(
            icon: Icons.my_location_rounded,
            label: 'Koordinat Kamu',
            value: data.koordinatKamu.isNotEmpty
                ? data.koordinatKamu
                : 'Tidak tersedia',
            color: data.koordinatKamu.isNotEmpty
                ? const Color(0xFF2E7D32)
                : const Color(0xFF8A94A6),
            valueColor: data.koordinatKamu.isNotEmpty
                ? const Color(0xFF2E7D32)
                : const Color(0xFF8A94A6),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    Color? valueColor,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A94A6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SelectableText(
                      value.isEmpty ? '-' : value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? const Color(0xFF1A1F36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 62,
            color: Color(0xFFF0F2F5),
          ),
      ],
    );
  }

  Widget _buildMapPreview({
    required LatLng latLng,
    required double markerColor,
  }) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: latLng, zoom: 15),
          markers: {
            Marker(
              markerId: MarkerId(
                'preview_${DateTime.now().millisecondsSinceEpoch}',
              ),
              position: latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            ),
          },
          zoomControlsEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Widget _buildFotoCard(String fotoWajah) {
    final imageUrl = RiwayatFormatter.getFullImageUrl(
      fotoWajah,
      RiwayatDetailDialog.baseUrl,
    );
    final heroTag = 'foto_bukti_$fotoWajah';

    return GestureDetector(
      onTap: () => _showFullscreenPhoto(imageUrl, heroTag),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: heroTag,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF2F4F7),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 32,
                              color: Color(0xFF8A94A6),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Gagal memuat foto',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8A94A6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFFF2F4F7),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF1565C0),
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Tap hint overlay
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Lihat penuh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullscreenPhoto(String imageUrl, String heroTag) {
    Get.to(
      () => _FullscreenPhotoPage(imageUrl: imageUrl, heroTag: heroTag),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );
  }

  _ParsedData _parseData(Map<String, dynamic> item) {
    String lokasi = '-';
    String koordinatLokasi = '-';
    String koordinatKamu = '-';
    String waktu = '-';
    String fotoWajah = '';
    LatLng? lokasiLatLng;
    LatLng? kamuLatLng;

    try {
      if (item['lokasi'] != null) {
        if (item['lokasi'] is Map) {
          lokasi = item['lokasi']['lokasi']?.toString() ?? '-';
          if (item['lokasi']['koordinat'] != null) {
            koordinatLokasi = item['lokasi']['koordinat'].toString();
          }
        } else {
          lokasi = item['lokasi'].toString();
        }
      }
    } catch (_) {}

    try {
      if (item['titik_koordinat_lokasi'] != null) {
        koordinatLokasi = item['titik_koordinat_lokasi'].toString();
      }
      if (koordinatLokasi != '-') {
        final parts = koordinatLokasi.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) lokasiLatLng = LatLng(lat, lng);
        }
      }
    } catch (_) {}

    try {
      if (item['titik_koordinat_kamu'] != null &&
          item['titik_koordinat_kamu'].toString().isNotEmpty) {
        koordinatKamu = item['titik_koordinat_kamu'].toString();
        final parts = koordinatKamu.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) kamuLatLng = LatLng(lat, lng);
        }
      }
    } catch (_) {}

    try {
      if (item['foto_wajah'] != null &&
          item['foto_wajah'].toString().isNotEmpty) {
        fotoWajah = item['foto_wajah'].toString();
      }
    } catch (_) {}

    try {
      if (item['waktu_absen'] != null) {
        waktu = _formatWaktuIndonesia(item['waktu_absen'].toString());
      }
    } catch (_) {
      waktu = '-';
    }

    return _ParsedData(
      lokasi: lokasi,
      koordinatLokasi: koordinatLokasi,
      koordinatKamu: koordinatKamu,
      waktu: waktu,
      fotoWajah: fotoWajah,
      lokasiLatLng: lokasiLatLng,
      kamuLatLng: kamuLatLng,
    );
  }
}

// ── EMPTY CONTENT ────────────────────────────────────────────────────────────

class _EmptyContent extends StatelessWidget {
  final String message;

  const _EmptyContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF8A94A6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.event_busy_outlined,
              size: 30,
              color: Color(0xFF8A94A6),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8A94A6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

/// Format waktu ke Indonesia lengkap: "Senin, 07 April 2025 • 08:30 WIB"
String _formatWaktuIndonesia(String waktuStr) {
  try {
    final dt = DateTime.parse(waktuStr);
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
    final jam = wib.hour.toString().padLeft(2, '0');
    final menit = wib.minute.toString().padLeft(2, '0');

    return '$hari, $tgl $bulan $tahun • $jam:$menit WIB';
  } catch (_) {
    return FormatterUtil.formatWaktuLengkap(waktuStr);
  }
}

// ── DATA MODEL ────────────────────────────────────────────────────────────────

class _ParsedData {
  final String lokasi;
  final String koordinatLokasi;
  final String koordinatKamu;
  final String waktu;
  final String fotoWajah;
  final LatLng? lokasiLatLng;
  final LatLng? kamuLatLng;

  _ParsedData({
    required this.lokasi,
    required this.koordinatLokasi,
    required this.koordinatKamu,
    required this.waktu,
    required this.fotoWajah,
    this.lokasiLatLng,
    this.kamuLatLng,
  });
}

// ── FULLSCREEN PHOTO PAGE ────────────────────────────────────────────────────

class _FullscreenPhotoPage extends StatefulWidget {
  final String imageUrl;
  final String heroTag;

  const _FullscreenPhotoPage({required this.imageUrl, required this.heroTag});

  @override
  State<_FullscreenPhotoPage> createState() => _FullscreenPhotoPageState();
}

class _FullscreenPhotoPageState extends State<_FullscreenPhotoPage> {
  final TransformationController _transformController =
      TransformationController();
  bool _showControls = true;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Foto interaktif (pinch to zoom) ──
            Center(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: widget.heroTag,
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.white38,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Gagal memuat foto',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── Top bar ──
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Tombol kembali
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Foto Bukti',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Tombol reset zoom
                      GestureDetector(
                        onTap: _resetZoom,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.fit_screen_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Hint zoom (muncul sebentar di bawah) ──
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pinch_outlined,
                            color: Colors.white70,
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cubit untuk zoom • Tap untuk sembunyikan',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
