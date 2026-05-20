import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myabsensi_mobile/controllers/app_config.dart';
import 'package:myabsensi_mobile/utils/formatter_util.dart';

class RekamAktivitasDetailPage extends StatefulWidget {
  final Map<String, dynamic> activity;

  const RekamAktivitasDetailPage({super.key, required this.activity});

  @override
  State<RekamAktivitasDetailPage> createState() =>
      _RekamAktivitasDetailPageState();
}

class _RekamAktivitasDetailPageState extends State<RekamAktivitasDetailPage> {
  // ── Warna tema ─────────────────────────────────────────────────────────
  static const _gradientStart = Color(0xFF1565C0);
  static const _gradientMid = Color(0xFF1E88E5);
  static const _gradientEnd = Color(0xFF42A5F5);
  static const _bg = Color(0xFFF2F4F7);

  GoogleMapController? _mapController;
  int _selectedPhotoIndex = 0;
  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    final url = await AppConfig.getBaseUrl();
    setState(() => _baseUrl = url.replaceAll('/api', ''));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _position => LatLng(
    double.tryParse(widget.activity['latitude']?.toString() ?? '') ?? 0,
    double.tryParse(widget.activity['longitude']?.toString() ?? '') ?? 0,
  );

  double get _accuracy =>
      double.tryParse(widget.activity['akurasi_meter']?.toString() ?? '') ?? 0;

  List get _fotos => widget.activity['fotos'] as List? ?? [];

  String _getFotoUrl(String fotoPath) {
    if (fotoPath.isEmpty) return '';
    if (fotoPath.startsWith('http')) return fotoPath;
    return '$_baseUrl/storage/$fotoPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildMap(),
                  const SizedBox(height: 12),
                  _buildDetailCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER BIRU ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    final tipeNama =
        (widget.activity['tipe_aktivitas'] is Map
            ? widget.activity['tipe_aktivitas']['nama']
            : widget.activity['tipe_aktivitas']) ??
        '-';

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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Stack(
            children: [
              // Dekorasi
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Detail Aktivitas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 20),

                  // Info ringkas di header
                  Row(
                    children: [
                      _buildHeaderChip(
                        icon: Icons.assignment_outlined,
                        label: 'Tipe',
                        value: tipeNama,
                      ),
                      const SizedBox(width: 10),
                      _buildHeaderChip(
                        icon: Icons.access_time_outlined,
                        label: 'Mulai',
                        value: FormatterUtil.formatWaktuSimple(
                          widget.activity['mulai'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.85), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MAP ───────────────────────────────────────────────────────────────
  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 220,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: _position, zoom: 17),
            onMapCreated: (c) => _mapController = c,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('lokasi'),
                position: _position,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
              ),
            },
            circles: {
              Circle(
                circleId: const CircleId('akurasi'),
                center: _position,
                radius: _accuracy,
                fillColor: _gradientMid.withOpacity(0.15),
                strokeColor: _gradientMid.withOpacity(0.4),
                strokeWidth: 1,
              ),
            },
          ),
        ),
      ),
    );
  }

  // ── DETAIL CARD ───────────────────────────────────────────────────────
  // Ganti seluruh _buildDetailCard() dan semua helper lama dengan ini:

  Widget _buildDetailCard() {
    final mulai = widget.activity['mulai'] ?? '';
    final berakhir = widget.activity['berakhir'] ?? '';
    final tipeNama =
        (widget.activity['tipe_aktivitas'] is Map
            ? widget.activity['tipe_aktivitas']['nama']
            : widget.activity['tipe_aktivitas']) ??
        '-';
    final tujuan = (widget.activity['tujuan'] ?? '').toString();
    final kendaraanNopol = (widget.activity['kendaraan_nopol'] ?? '')
        .toString();
    final lat = widget.activity['latitude']?.toString() ?? '-';
    final lng = widget.activity['longitude']?.toString() ?? '-';
    final akurasi = widget.activity['akurasi_meter']?.toString() ?? '-';

    String durasi = '-';
    try {
      final dtMulai = DateTime.parse(mulai);
      final dtBerakhir = DateTime.parse(berakhir);
      final diff = dtBerakhir.difference(dtMulai);
      final jam = diff.inHours;
      final menit = diff.inMinutes % 60;
      durasi = jam > 0 ? '${jam}j ${menit}m' : '${menit} menit';
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── Foto ──────────────────────────────────────────────
          if (_fotos.isNotEmpty) ...[
            _buildFotoSection(),
            const SizedBox(height: 16),
          ],

          // ── Satu card gabungan ─────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Waktu ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTimeColumn(
                          label: 'Mulai',
                          time: FormatterUtil.formatWaktuSimple(mulai),
                          date: FormatterUtil.formatTanggal(mulai),
                          color: const Color(0xFF1565C0),
                          bgColor: const Color(0xFFE8F0FE),
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF2F4F7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Color(0xFF8A94A6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              durasi,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: _buildTimeColumn(
                          label: 'Selesai',
                          time: FormatterUtil.formatWaktuSimple(berakhir),
                          date: FormatterUtil.formatTanggal(berakhir),
                          color: const Color(0xFF2E7D32),
                          bgColor: const Color(0xFFE8F5E9),
                          alignRight: true,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDividerLine(),

                // ── Tipe & Tugas ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.label_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tipeNama,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.activity['tugas'] ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F36),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tujuan (opsional) ──────────────────────────
                if (tujuan.isNotEmpty) ...[
                  _buildDividerLine(),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: _buildInfoRow(
                      icon: Icons.flag_rounded,
                      iconColor: const Color(0xFFE65100),
                      label: 'Tujuan',
                      value: tujuan,
                    ),
                  ),
                ],

                // ── Kendaraan (opsional) ───────────────────────
                if (kendaraanNopol.isNotEmpty) ...[
                  _buildDividerLine(),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: _buildInfoRow(
                      icon: Icons.directions_car_rounded,
                      iconColor: const Color(0xFF1565C0),
                      label: 'Kendaraan & Nopol',
                      value: null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          kendaraanNopol.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1F36),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Koordinat ──────────────────────────────────
                _buildDividerLine(),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Color(0xFFE53935),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'KOORDINAT LOKASI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8A94A6),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCoordCard(
                              label: 'Latitude',
                              value: lat,
                              icon: Icons.north_rounded,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCoordCard(
                              label: 'Longitude',
                              value: lng,
                              icon: Icons.east_rounded,
                              color: const Color(0xFF7B2FBE),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE65100).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.radar_rounded,
                              size: 15,
                              color: Color(0xFFE65100),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Akurasi GPS',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '± $akurasi meter',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Tambahkan helper divider ini
  Widget _buildDividerLine() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade100);
  }

  // ── CARD WRAPPER ──────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── CARD HEADER ───────────────────────────────────────────────────────
  Widget _buildCardHeader({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8A94A6),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ── TIME COLUMN ───────────────────────────────────────────────────────
  Widget _buildTimeColumn({
    required String label,
    required String time,
    required String date,
    required Color color,
    required Color bgColor,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8A94A6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: alignRight
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── INFO ROW ──────────────────────────────────────────────────────────
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String? value,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 15),
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
              const SizedBox(height: 4),
              if (value != null)
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1F36),
                    height: 1.4,
                  ),
                ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ],
    );
  }

  // ── COORD CARD ────────────────────────────────────────────────────────
  Widget _buildCoordCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── FOTO SECTION ──────────────────────────────────────────────────────
  Widget _buildFotoSection() {
    if (_baseUrl.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: _gradientMid)),
      );
    }

    final fotoUrl = _getFotoUrl(_fotos[_selectedPhotoIndex]['foto_path'] ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showFullScreenPhoto(fotoUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              fotoUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: const Color(0xFFE3EDF8),
                  child: const Center(
                    child: CircularProgressIndicator(color: _gradientMid),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFFE3EDF8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Gagal memuat foto',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_fotos.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isActive = index == _selectedPhotoIndex;
                final thumbUrl = _getFotoUrl(_fotos[index]['foto_path'] ?? '');
                return GestureDetector(
                  onTap: () => setState(() => _selectedPhotoIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: isActive
                          ? Border.all(color: _gradientMid, width: 2)
                          : Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.network(
                        thumbUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFFE3EDF8),
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_selectedPhotoIndex + 1} / ${_fotos.length}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }

  // ── FULLSCREEN ────────────────────────────────────────────────────────
  void _showFullScreenPhoto(String url) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
