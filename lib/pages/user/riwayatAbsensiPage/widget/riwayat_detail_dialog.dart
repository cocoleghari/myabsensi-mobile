import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/utils/riwayat_formatter.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myabsensi_mobile/controllers/app_config.dart';

class RiwayatDetailDialog {
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
                _buildHeader(no, tanggal),
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
                        height: 460,
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

// ── DETAIL CONTENT ───────────────────────────────────────────────────────────

class _DetailContent extends StatefulWidget {
  final Map<String, dynamic> item;
  final String tipe;

  const _DetailContent({required this.item, required this.tipe});

  @override
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent> {
  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    final url = await AppConfig.getBaseUrl();
    if (mounted) setState(() => _baseUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    final data = _parseData(widget.item);
    final bool isMasuk = widget.tipe == 'masuk';
    final Color themeColor = isMasuk
        ? const Color(0xFF1565C0)
        : const Color(0xFFE65100);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Waktu card ──
          _buildWaktuCard(themeColor, data.waktu, isMasuk),
          const SizedBox(height: 12),

          // ── Status card (terlambat / lembur / tepat waktu) ──
          if (data.status.isNotEmpty) ...[
            _buildStatusCard(data, isMasuk),
            const SizedBox(height: 12),
          ],

          // ── Shift & Lokasi ──
          _buildInfoCard(themeColor, data),
          const SizedBox(height: 12),

          // ── Peta posisi user ──
          if (data.kamuLatLng != null) ...[
            _sectionLabel('Posisi Absen'),
            const SizedBox(height: 8),
            _buildMapPreview(
              latLng: data.kamuLatLng!,
              markerColor: isMasuk
                  ? BitmapDescriptor.hueBlue
                  : BitmapDescriptor.hueOrange,
            ),
            const SizedBox(height: 12),
          ],

          // ── Foto bukti ──
          if (data.fotoAbsenPath.isNotEmpty && _baseUrl.isNotEmpty) ...[
            _sectionLabel('Foto Bukti'),
            const SizedBox(height: 8),
            _buildFotoCard(data.fotoAbsenPath),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8A94A6),
        letterSpacing: 0.6,
      ),
    );
  }

  // ── Waktu card ─────────────────────────────────────────────────────────────

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

  // ── Status card ────────────────────────────────────────────────────────────

  Widget _buildStatusCard(_ParsedData data, bool isMasuk) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (data.status) {
      case 'terlambat':
        statusColor = const Color(0xFFC62828);
        statusIcon = Icons.timer_off_rounded;
        statusLabel = 'Terlambat ${data.menitTerlambat} menit';
        break;
      case 'lembur':
        statusColor = const Color(0xFF6A1B9A);
        statusIcon = Icons.more_time_rounded;
        statusLabel = 'Lembur ${data.menitLembur} menit';
        break;
      default:
        statusColor = const Color(0xFF2E7D32);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Tepat Waktu';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          // Confidence score
          if (data.confidenceScore > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.face_rounded,
                    size: 13,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(data.confidenceScore * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard(Color themeColor, _ParsedData data) {
    final List<_InfoRowData> rows = [];

    // Shift
    if (data.namaShift.isNotEmpty) {
      rows.add(
        _InfoRowData(
          icon: Icons.schedule_rounded,
          label: 'Shift',
          value: data.namaShift,
        ),
      );
    }

    // Lokasi kantor (dari pusat_lokasi)
    rows.add(
      _InfoRowData(
        icon: Icons.location_on_outlined,
        label: 'Lokasi Kantor',
        value: data.namaLokasi.isNotEmpty ? data.namaLokasi : '-',
      ),
    );

    // Jarak ke kantor
    if (data.jarakMeter > 0) {
      rows.add(
        _InfoRowData(
          icon: Icons.social_distance_rounded,
          label: 'Jarak ke Kantor',
          value: data.jarakMeter >= 1000
              ? '${(data.jarakMeter / 1000).toStringAsFixed(2)} km'
              : '${data.jarakMeter.toStringAsFixed(0)} m',
        ),
      );
    }

    // Koordinat user
    rows.add(
      _InfoRowData(
        icon: Icons.my_location_rounded,
        label: 'Koordinat Absen',
        value: data.koordinatKamu.isNotEmpty ? data.koordinatKamu : '-',
        valueColor: data.koordinatKamu.isNotEmpty
            ? const Color(0xFF2E7D32)
            : const Color(0xFF8A94A6),
      ),
    );

    // Catatan (jika ada)
    if (data.catatan.isNotEmpty) {
      rows.add(
        _InfoRowData(
          icon: Icons.notes_rounded,
          label: 'Catatan',
          value: data.catatan,
        ),
      );
    }

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
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return _buildInfoRow(
            icon: row.icon,
            label: row.label,
            value: row.value,
            color: themeColor,
            valueColor: row.valueColor,
            isLast: i == rows.length - 1,
          );
        }),
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

  // ── Map preview ────────────────────────────────────────────────────────────

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
          initialCameraPosition: CameraPosition(target: latLng, zoom: 16),
          markers: {
            Marker(
              markerId: MarkerId(
                'preview_${latLng.latitude}_${latLng.longitude}',
              ),
              position: latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
        ),
      ),
    );
  }

  // ── Foto bukti ─────────────────────────────────────────────────────────────

  Widget _buildFotoCard(String fotoAbsenPath) {
    // foto_absen_path dari backend hanya nama file: "masuk_nama_1234567890.jpg"
    // URL lengkap: {baseUrl}/storage/foto_absensi/{namaFile}
    // Tapi baseUrl di sini adalah base API, storage ada di root laravel
    // Contoh: http://192.168.0.103:8000/storage/foto_absensi/masuk_budi_1234.jpg
    final storageBase = _baseUrl.replaceFirst('/api', '');
    final imageUrl = '$storageBase/storage/foto_absensi/$fotoAbsenPath';
    final heroTag = 'foto_bukti_$fotoAbsenPath';

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

  // ── Parse data dari field Absensi model ────────────────────────────────────
  //
  // Field yang tersedia dari backend (getRiwayatAbsensi):
  //   id, employee_id, pusat_lokasi_id, shift_id,
  //   tanggal_absen (date),  tipe_absen,  waktu_absen (datetime UTC),
  //   latitude (double),     longitude (double),
  //   jarak_meter (double),  foto_absen_path (string: nama file saja),
  //   confidence_score,      wajah_cocok,   status,
  //   menit_terlambat,       menit_lembur,  catatan,
  //   pusat_lokasi: { id, nama_lokasi },
  //   shift: { id, nama, kode }

  _ParsedData _parseData(Map<String, dynamic> item) {
    // Tambah ini di baris pertama
    debugPrint('=== FULL ITEM DATA ===');
    debugPrint(item.toString());
    debugPrint('catatan value: ${item['catatan']}');
    debugPrint('catatan type: ${item['catatan'].runtimeType}');
    // Waktu absen — datetime UTC dari backend
    String waktu = '-';
    try {
      final raw = item['waktu_absen']?.toString() ?? '';
      if (raw.isNotEmpty) waktu = _formatWaktuIndonesia(raw);
    } catch (_) {}

    // Lokasi dari relasi pusat_lokasi
    final String namaLokasi =
        item['pusat_lokasi']?['nama_lokasi']?.toString() ?? '';

    // Shift dari relasi shift
    final String namaShift = item['shift']?['nama']?.toString() ?? '';

    // Koordinat user saat absen
    final double? lat = (item['latitude'] as num?)?.toDouble();
    final double? lng = (item['longitude'] as num?)?.toDouble();
    String koordinatKamu = '';
    LatLng? kamuLatLng;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      koordinatKamu = '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      kamuLatLng = LatLng(lat, lng);
    }

    // Jarak meter
    final double jarakMeter = (item['jarak_meter'] as num?)?.toDouble() ?? 0.0;

    // Foto — hanya nama file, URL dibangun di _buildFotoCard
    final String fotoAbsenPath = item['foto_absen_path']?.toString() ?? '';

    // Confidence score (0.0 – 1.0)
    final double confidenceScore =
        (item['confidence_score'] as num?)?.toDouble() ?? 0.0;

    // Status: tepat_waktu | terlambat | lembur
    final String status = item['status']?.toString() ?? 'tepat_waktu';

    // Menit terlambat / lembur
    final int menitTerlambat = (item['menit_terlambat'] as num?)?.toInt() ?? 0;
    final int menitLembur = (item['menit_lembur'] as num?)?.toInt() ?? 0;

    // Catatan
    final String catatan = item['catatan']?.toString() ?? '';

    return _ParsedData(
      waktu: waktu,
      namaLokasi: namaLokasi,
      namaShift: namaShift,
      koordinatKamu: koordinatKamu,
      kamuLatLng: kamuLatLng,
      jarakMeter: jarakMeter,
      fotoAbsenPath: fotoAbsenPath,
      confidenceScore: confidenceScore,
      status: status,
      menitTerlambat: menitTerlambat,
      menitLembur: menitLembur,
      catatan: catatan,
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

// ── DATA MODELS ───────────────────────────────────────────────────────────────

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class _ParsedData {
  final String waktu;
  final String namaLokasi;
  final String namaShift;
  final String koordinatKamu;
  final LatLng? kamuLatLng;
  final double jarakMeter;
  final String fotoAbsenPath;
  final double confidenceScore;
  final String status;
  final int menitTerlambat;
  final int menitLembur;
  final String catatan;

  const _ParsedData({
    required this.waktu,
    required this.namaLokasi,
    required this.namaShift,
    required this.koordinatKamu,
    required this.kamuLatLng,
    required this.jarakMeter,
    required this.fotoAbsenPath,
    required this.confidenceScore,
    required this.status,
    required this.menitTerlambat,
    required this.menitLembur,
    required this.catatan,
  });
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

/// Format datetime UTC ke: "Senin, 07 April 2025 • 08:30 WIB"
String _formatWaktuIndonesia(String waktuStr) {
  try {
    final dt = DateTime.parse(waktuStr);
    final utc = dt.isUtc ? dt : dt.toUtc();
    final wib = utc.add(const Duration(hours: 7));

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
    return waktuStr;
  }
}

// ── FULLSCREEN PHOTO PAGE ─────────────────────────────────────────────────────

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

  void _resetZoom() => _transformController.value = Matrix4.identity();

  void _toggleControls() => setState(() => _showControls = !_showControls);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
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
                    errorBuilder: (_, __, ___) => const Center(
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
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
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

            // Top bar
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

            // Bottom hint
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
