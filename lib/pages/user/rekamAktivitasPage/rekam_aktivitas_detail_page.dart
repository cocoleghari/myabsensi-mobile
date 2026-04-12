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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto ─────────────────────────────────────────
          if (_fotos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Foto'),
                  const SizedBox(height: 10),
                  _buildFotoSection(),
                ],
              ),
            ),
            _buildDivider(),
          ],

          // ── Waktu Pencapaian ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Waktu & Tanggal Pencapaian'),
                const SizedBox(height: 6),
                _buildValue(FormatterUtil.formatWaktuLengkap(mulai)),
              ],
            ),
          ),
          _buildDivider(),

          // ── Tugas ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Tugas'),
                const SizedBox(height: 6),
                _buildValue(widget.activity['tugas'] ?? '-'),
              ],
            ),
          ),
          _buildDivider(),

          // ── Mulai & Berakhir ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Mulai'),
                      const SizedBox(height: 6),
                      _buildValue(FormatterUtil.formatWaktuLengkap(mulai)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Berakhir'),
                      const SizedBox(height: 6),
                      _buildValue(FormatterUtil.formatWaktuLengkap(berakhir)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(),

          // ── Lokasi ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Lokasi'),
                const SizedBox(height: 6),
                _buildValue(
                  '${widget.activity['latitude'] ?? '-'}, '
                  '${widget.activity['longitude'] ?? '-'}',
                ),
              ],
            ),
          ),
          _buildDivider(),

          // ── Tipe Aktivitas ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Tipe Aktivitas'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EDF8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tipeNama,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _gradientStart,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tujuan ────────────────────────────────────────
          if (tujuan.isNotEmpty) ...[
            _buildDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Tujuan'),
                  const SizedBox(height: 6),
                  _buildValue(tujuan),
                ],
              ),
            ),
          ],

          // ── Kendaraan & Nopol ─────────────────────────────
          if (kendaraanNopol.isNotEmpty) ...[
            _buildDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Kendaraan & Nopol'),
                  const SizedBox(height: 6),
                  _buildValue(kendaraanNopol),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Divider(color: Colors.grey.shade100, height: 1),
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

  // ── HELPER ────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black87,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
