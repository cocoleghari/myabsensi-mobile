import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/offline_absensi_controller.dart';
import '../../../../controllers/user_lokasi_controller.dart';
import 'hasil_absensi_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myabsensi_mobile/controllers/notification_controller.dart';
import 'package:myabsensi_mobile/controllers/app_config.dart';
import 'package:geocoding/geocoding.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _blue = Color.fromARGB(255, 76, 159, 241);
const _orange = Color(0xFFF97316);
const _orangeSoft = Color(0xFFFFF4ED);
const _green = Color(0xFF059669);
const _greenSoft = Color(0xFFECFDF5);
const _red = Color(0xFFDC2626);
const _redSoft = Color(0xFFFEF2F2);
const _surface = Color(0xFFF3F6FB);
const _cardBg = Colors.white;
const _textPri = Color(0xFF0D1B2A);
const _textSec = Color(0xFF7C8DB5);
const _border = Color(0xFFE4EAF6);

class PreviewAbsensiPage extends StatefulWidget {
  final String tipe;
  final File fotoAbsen;
  final String fotoReferensiUrl;
  final Map<String, dynamic> lokasiTerdekat;
  final String koordinatUser;
  final double confidenceScore;
  final bool wajahCocok;
  final double akurasi;
  final bool isOffline;

  const PreviewAbsensiPage({
    super.key,
    required this.tipe,
    required this.fotoAbsen,
    required this.fotoReferensiUrl,
    required this.lokasiTerdekat,
    required this.koordinatUser,
    required this.confidenceScore,
    required this.wajahCocok,
    required this.akurasi,
    this.isOffline = false,
  });

  @override
  State<PreviewAbsensiPage> createState() => _PreviewAbsensiPageState();
}

class _PreviewAbsensiPageState extends State<PreviewAbsensiPage>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  GoogleMapController? _mapController;
  final controller = Get.find<UserLokasiController>();
  final _auth = Get.find<AuthController>();

  bool _catatanEnabled = false;
  final _catatanCtrl = TextEditingController();

  AnimationController? _animCtrl;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  String _alamatPengajuan = ''; // ← tambah ini
  bool _isGettingAlamat = false; // ← tambah ini

  @override
  void initState() {
    super.initState();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _animCtrl = ctrl;
    _fadeAnim = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    ctrl.forward();
    _fetchAlamatBackground();
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    _animCtrl?.dispose();
    super.dispose();
  }

  Future<void> _fetchAlamatBackground() async {
    if (mounted) setState(() => _isGettingAlamat = true);
    try {
      final coords = widget.koordinatUser.split(',');
      final lat = double.tryParse(coords[0].trim());
      final lng = double.tryParse(coords[1].trim());

      if (lat == null || lng == null) return;

      // Tambah timeout agar tidak hang di iOS
      final placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 5));
          
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        _alamatPengajuan = [
          p.street,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (e) {
      debugPrint('Geocoding background error: $e');
      _alamatPengajuan = widget.koordinatUser; // fallback ke koordinat
    } finally {
      if (mounted) setState(() => _isGettingAlamat = false);
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────────

  LatLng get _userLatLng {
    final p = widget.koordinatUser.split(',');
    return LatLng(double.parse(p[0].trim()), double.parse(p[1].trim()));
  }

  LatLng get _lokasiLatLng {
    final lat = (widget.lokasiTerdekat['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (widget.lokasiTerdekat['longitude'] as num?)?.toDouble() ?? 0;
    return LatLng(lat, lng);
  }

  Color _akurasiColor(double v) {
    if (v <= 10) return _green;
    if (v <= 30) return _orange;
    return _red;
  }

  Set<Marker> get _markers => {
    Marker(
      markerId: const MarkerId('user'),
      position: _userLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Posisi Anda'),
    ),
    if (!widget.isOffline)
      Marker(
        markerId: const MarkerId('lokasi'),
        position: _lokasiLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.lokasiTerdekat['nama_lokasi']),
      ),
  };

  Set<Circle> get _circles => widget.isOffline
      ? {}
      : {
          Circle(
            circleId: const CircleId('radius'),
            center: _lokasiLatLng,
            radius:
                (widget.lokasiTerdekat['radius_meter'] as num?)?.toDouble() ??
                100,
            fillColor: _blue.withOpacity(0.10),
            strokeColor: _blue.withOpacity(0.45),
            strokeWidth: 2,
          ),
        };

  // ── build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lokasiOke =
        widget.isOffline || widget.lokasiTerdekat['dalam_radius'] == true;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
        child: SlideTransition(
          position: _slideAnim ?? const AlwaysStoppedAnimation(Offset.zero),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildMap(),
                const SizedBox(height: 10),

                if (widget.isOffline)
                  _AlertBanner(
                    icon: Icons.wifi_off_rounded,
                    color: _orange,
                    bg: _orangeSoft,
                    title: 'Mode Offline',
                    subtitle:
                        'Absensi tersimpan lokal & dikirim otomatis saat online.',
                  ),
                if (!widget.isOffline && !lokasiOke)
                  _AlertBanner(
                    icon: Icons.location_off_rounded,
                    color: _red,
                    bg: _redSoft,
                    title: 'Di Luar Radius',
                    subtitle:
                        '${widget.lokasiTerdekat['jarak'].toStringAsFixed(0)} m '
                        'dari ${widget.lokasiTerdekat['nama_lokasi']} '
                        '(batas ${(widget.lokasiTerdekat['radius_meter'] as num?)?.toInt() ?? 100} m)',
                  ),

                _buildIdentitasCard(now),
                const SizedBox(height: 8),
                _buildFotoCard(),
                const SizedBox(height: 8),
                _buildCatatanDanAksiCard(lokasiOke, now),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCatatanDanAksiCard(bool lokasiOke, DateTime now) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Catatan ──
          Row(
            children: [
              _SectionHeader(
                icon: Icons.notes_rounded,
                label: 'Catatan',
                iconColor: _blue,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: const Text(
                  'Opsional',
                  style: TextStyle(
                    fontSize: 10,
                    color: _textSec,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.82,
                child: Switch(
                  value: _catatanEnabled,
                  onChanged: (v) => setState(() => _catatanEnabled = v),
                  activeColor: _blue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _catatanEnabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _catatanCtrl,
                      maxLines: 3,
                      maxLength: 200,
                      style: const TextStyle(fontSize: 13.5, color: _textPri),
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan untuk kehadiran ini...',
                        hintStyle: const TextStyle(
                          color: _textSec,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        filled: true,
                        fillColor: _surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: _orange,
                            width: 1.8,
                          ),
                        ),
                        counterStyle: const TextStyle(
                          fontSize: 11,
                          color: _textSec,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 16),

          // ── Tombol Aksi ──
          _buildInlineActionButton(lokasiOke),
        ],
      ),
    );
  }

  Widget _buildInlineActionButton(bool lokasiOke) {
    if (widget.isOffline) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _simpanOffline,
          icon: const Icon(Icons.save_alt_rounded, size: 18),
          label: const Text(
            'Simpan Offline',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (!lokasiOke) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Get.offAllNamed('/user'),
                icon: const Icon(Icons.home_rounded, size: 18),
                label: const Text(
                  'Beranda',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _showAjukanPermintaanDialog,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text(
                  'Izin Lokasi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _orange,
                  side: const BorderSide(color: _orange, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!widget.wajahCocok) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.camera_alt_rounded, size: 18),
          label: const Text(
            'Foto Ulang',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    // Simpan normal
    return Obx(() {
      final loading = controller.isSubmitting.value;
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: loading ? null : _simpanAbsensi,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_rounded, size: 18),
          label: Text(
            loading ? 'Menyimpan...' : 'Simpan Kehadiran',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    });
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Preview Absensi',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Get.back(),
      ),
    );
  }

  // ── MAP ───────────────────────────────────────────────────────────────────────

  Widget _buildMap() {
    return SizedBox(
      height: 195,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLatLng,
              zoom: 17,
            ),
            markers: _markers,
            circles: _circles,
            onMapCreated: (c) => _mapController = c,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          if (!widget.isOffline)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Center(
                child: _MapPill(
                  icon: Icons.place_rounded,
                  iconColor: _red,
                  label: widget.lokasiTerdekat['nama_lokasi'] ?? '',
                ),
              ),
            ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: _MapPill(
                icon: Icons.my_location_rounded,
                iconColor: _akurasiColor(widget.akurasi),
                label: 'Akurasi ${widget.akurasi.toStringAsFixed(0)} m',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── IDENTITAS ─────────────────────────────────────────────────────────────────

  Widget _buildIdentitasCard(DateTime now) {
    final nama = _auth.employeeFullName.isNotEmpty
        ? _auth.employeeFullName
        : _auth.userName;
    final isMasuk = widget.tipe == 'masuk';

    return _SectionCard(
      child: Row(
        children: [
          _buildAvatar(nama),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPri,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: _textSec,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTanggal(now),
                      style: const TextStyle(
                        fontSize: 17, // was 12
                        color: _textSec,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatJam(now),
                      style: const TextStyle(
                        fontSize: 17, // was 13
                        color: Color.fromARGB(255, 45, 130, 214),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Gradient badge tipe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: isMasuk ? _blue : _orange,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMasuk ? Icons.login_rounded : Icons.logout_rounded,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isMasuk ? 'MASUK' : 'PULANG',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String nama) {
    final photoUrl = _auth.photoUrl;
    final hasPhoto = photoUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 50,
        height: 50,
        child: hasPhoto
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, prog) {
                  if (prog == null) return child;
                  return Container(
                    color: _blue,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _buildInitialAvatar(nama),
              )
            : _buildInitialAvatar(nama),
      ),
    );
  }

  Widget _buildInitialAvatar(String nama) {
    return Container(
      color: _blue,
      alignment: Alignment.center,
      child: Text(
        nama.isNotEmpty ? nama[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  // ── FOTO CARD ─────────────────────────────────────────────────────────────────

  Widget _buildFotoCard() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.face_retouching_natural,
            label: 'Verifikasi Wajah',
            iconColor: _blue,
          ),

          const SizedBox(height: 14),

          // Dua foto berdampingan — rapat, tanpa label VS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FotoItem(
                  label: 'Foto Kehadiran',
                  labelColor: _blue,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: Image.file(widget.fotoAbsen, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: 6), // jarak minimal
              Expanded(
                child: _FotoItem(
                  label: 'Foto Referensi',
                  labelColor: _textSec,
                  child: _buildFotoReferensi(),
                ),
              ),
            ],
          ),

          if (!widget.isOffline) ...[
            const SizedBox(height: 14),
            _buildMatchBadge(),
          ],
        ],
      ),
    );
  }

  Widget _buildFotoReferensi() {
    if (widget.isOffline || widget.fotoReferensiUrl.isEmpty) {
      return Container(
        color: _surface,
        child: const Center(
          child: Icon(Icons.person_outline_rounded, size: 44, color: _textSec),
        ),
      );
    }
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(-1.0, 1.0),
      child: Image.network(
        widget.fotoReferensiUrl,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, prog) {
          if (prog == null) return child;
          return Container(
            color: _surface,
            child: Center(
              child: CircularProgressIndicator(
                value: prog.expectedTotalBytes != null
                    ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes!
                    : null,
                color: _blue,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: _surface,
          child: const Center(
            child: Icon(
              Icons.person_outline_rounded,
              size: 44,
              color: _textSec,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBadge() {
    final ok = widget.wajahCocok;
    final pct = (widget.confidenceScore * 100).toStringAsFixed(1);
    final col = ok ? _green : _red;
    final bg = ok ? _greenSoft : _redSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withOpacity(0.22), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: col.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ok ? Icons.verified_rounded : Icons.gpp_bad_rounded,
              color: col,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'Wajah Terverifikasi' : 'Verifikasi Gagal',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: col,
                    fontSize: 13.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  ok
                      ? 'Kecocokan $pct% — identitas dikonfirmasi'
                      : 'Kecocokan $pct% — tidak memenuhi ambang batas',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: col.withOpacity(0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: col.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$pct%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: col,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CATATAN ───────────────────────────────────────────────────────────────────

  Widget _buildCatatanCard() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionHeader(
                icon: Icons.notes_rounded,
                label: 'Catatan',
                iconColor: _blue,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: const Text(
                  'Opsional',
                  style: TextStyle(
                    fontSize: 10,
                    color: _textSec,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.82,
                child: Switch(
                  value: _catatanEnabled,
                  onChanged: (v) => setState(() => _catatanEnabled = v),
                  activeColor: _blue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _catatanEnabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _catatanCtrl,
                      maxLines: 3,
                      maxLength: 200,
                      style: const TextStyle(fontSize: 13.5, color: _textPri),
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan untuk kehadiran ini...',
                        hintStyle: const TextStyle(
                          color: _textSec,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        filled: true,
                        fillColor: _surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: _orange,
                            width: 1.8,
                          ),
                        ),
                        counterStyle: const TextStyle(
                          fontSize: 11,
                          color: _textSec,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── ACTION ────────────────────────────────────────────────────────────────────

  Widget _buildActionButton(bool lokasiOke) {
    if (widget.isOffline) return _buildOfflineButton(); // sudah handle sendiri

    // yang lain bungkus dengan padding horizontal
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: () {
        if (!lokasiOke) return _buildLuarRadiusButton();
        if (!widget.wajahCocok) return _buildWajahGagalButton();
        return _buildSimpanButton();
      }(),
    );
  }

  Widget _buildOfflineButton() {
    return Column(
      children: [
        _AlertBanner(
          icon: Icons.info_outline_rounded,
          color: _orange,
          bg: _orangeSoft,
          title: 'Simpan Sementara',
          subtitle:
              'Data tersimpan lokal & dikirim otomatis saat koneksi tersedia.',
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _GradientButton(
            label: 'Simpan Kehadiran Offline',
            icon: Icons.save_alt_rounded,
            gradientColors: [_blue, const Color(0xFFEA580C)],
            shadowColor: _blue,
            onPressed: _simpanOffline,
          ),
        ),
      ],
    );
  }

  Widget _buildLuarRadiusButton() {
    return _SectionCard(
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Get.offAllNamed('/user'),
                icon: const Icon(Icons.home_rounded, size: 18),
                label: const Text(
                  'Beranda',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _showAjukanPermintaanDialog,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text(
                  'Izin Lokasi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _orange,
                  side: const BorderSide(color: _orange, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWajahGagalButton() {
    return _GradientButton(
      label: 'Foto Ulang',
      icon: Icons.camera_alt_rounded,
      gradientColors: [_blue, const Color(0xFFEA580C)],
      shadowColor: _blue,
      onPressed: () => Get.back(),
    );
  }

  Widget _buildSimpanButton() {
    return Obx(() {
      final loading = controller.isSubmitting.value;
      return _GradientButton(
        label: loading ? 'Menyimpan...' : 'Simpan Kehadiran',
        icon: loading ? null : Icons.check_circle_rounded,
        gradientColors: [_blue, const Color(0xFF2563EB)],
        shadowColor: _blue,
        loading: loading,
        onPressed: loading ? null : _simpanAbsensi,
      );
    });
  }

  // ── SIMPAN ────────────────────────────────────────────────────────────────────

  Future<void> _simpanAbsensi() async {
    final catatan = _catatanEnabled ? _catatanCtrl.text.trim() : null;
    final success = await controller.kirimAbsensiDariPreview(
      lokasiTerpilih: widget.lokasiTerdekat,
      koordinatUser: widget.koordinatUser,
      foto: widget.fotoAbsen,
      tipe: widget.tipe,
      catatan: catatan,
    );
    if (success && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      Get.offAll(() => HasilAbsensiPage(tipe: widget.tipe));
    }
  }

  Future<void> _simpanOffline() async {
    final p = widget.koordinatUser.split(',');
    final lat = double.parse(p[0].trim());
    final lng = double.parse(p[1].trim());

    final offline = Get.find<OfflineAbsensiController>();
    await offline.addToQueue(
      tipe: widget.tipe,
      foto: widget.fotoAbsen,
      latitude: lat,
      longitude: lng,
    );

    if (widget.tipe == 'masuk') {
      controller.sudahMasuk.value = true;
      controller.dataMasuk.value = {
        'waktu_absen': DateTime.now().toIso8601String(),
        'status': 'tepat_waktu',
        'tipe_absen': 'masuk',
        'offline': true,
      };
    } else {
      controller.sudahPulang.value = true;
      controller.dataPulang.value = {
        'waktu_absen': DateTime.now().toIso8601String(),
        'status': 'tepat_waktu',
        'tipe_absen': 'pulang',
        'offline': true,
      };
    }

    Get.snackbar(
      'Tersimpan Offline 📴',
      'Absen ${widget.tipe} disimpan. Akan dikirim otomatis saat online.',
      backgroundColor: const Color(0xFF6366F1),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
    );

    Get.offAllNamed('/user');
  }

  Future<void> _showAjukanPermintaanDialog() async {
    await Get.dialog(
      _AjukanPermintaanDialog(
        tipe: widget.tipe,
        lokasiTerdekat: widget.lokasiTerdekat,
        koordinatUser: widget.koordinatUser,
        fotoAbsen: widget.fotoAbsen,
        alamatPengajuan: _alamatPengajuan,
      ),
      barrierDismissible: false,
    );
  }

  // ── utils ─────────────────────────────────────────────────────────────────────

  String _formatTanggal(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  String _formatJam(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// REUSABLE PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: iconColor),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: _textPri,
          letterSpacing: -0.3,
        ),
      ),
    ],
  );
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final String title, subtitle;

  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.28), width: 1.2),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: color.withOpacity(0.82),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MapPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _MapPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 260),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.14),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _FotoItem extends StatelessWidget {
  final Widget child;
  final String label;
  final Color labelColor;

  const _FotoItem({
    required this.child,
    required this.label,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: labelColor.withOpacity(0.20), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: AspectRatio(aspectRatio: 3 / 4, child: child),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: labelColor.withOpacity(0.55),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    ],
  );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final List<Color> gradientColors;
  final Color shadowColor;
  final bool loading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.gradientColors,
    required this.shadowColor,
    this.icon,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedOpacity(
          opacity: (onPressed == null && !loading) ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: gradientColors[0], // flat, pakai warna pertama
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withOpacity(0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 19, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.1,
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
}

class _AjukanPermintaanDialog extends StatefulWidget {
  final String tipe;
  final Map<String, dynamic> lokasiTerdekat;
  final String koordinatUser;
  final File fotoAbsen;
  final String alamatPengajuan;

  const _AjukanPermintaanDialog({
    required this.tipe,
    required this.lokasiTerdekat,
    required this.koordinatUser,
    required this.fotoAbsen,
    required this.alamatPengajuan,
  });

  @override
  State<_AjukanPermintaanDialog> createState() =>
      _AjukanPermintaanDialogState();
}

class _AjukanPermintaanDialogState extends State<_AjukanPermintaanDialog> {
  final _alasanCtrl = TextEditingController();
  String? _terpilih;
  bool _isSending = false;

  final _alasanOptions = const [
    'Lupa absen di lokasi',
    'Gangguan GPS / sinyal',
    'Tugas di luar kantor',
    'Kunjungan klien',
    'Lainnya',
  ];

  @override
  void dispose() {
    _alasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    if (_terpilih == null) {
      Get.snackbar(
        'Perhatian',
        'Pilih alasan permintaan terlebih dahulu',
        backgroundColor: const Color(0xFFF97316),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
      return;
    }

    setState(() => _isSending = true);
    Get.back(); // tutup dialog dulu

    try {
      final coords = widget.koordinatUser.split(',');
      final token = Get.find<AuthController>().token.value;
      final baseUrl = await AppConfig.getBaseUrl();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/permintaan-absen'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['tipe_absen'] = widget.tipe;
      request.fields['alasan'] = _terpilih!;
      request.fields['keterangan'] = _alasanCtrl.text.trim();
      request.fields['latitude'] = coords[0].trim();
      request.fields['longitude'] = coords[1].trim();
      request.fields['jarak_meter'] = (widget.lokasiTerdekat['jarak'] ?? 0)
          .toString();
      request.fields['pusat_lokasi_id'] =
          (widget.lokasiTerdekat['pusat_lokasi_id'] ?? '').toString();
      request.fields['alamat_pengajuan'] = widget.alamatPengajuan.isNotEmpty
          ? widget.alamatPengajuan
          : widget.koordinatUser;

      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_wajah',
          widget.fotoAbsen.path,
          filename:
              'req_${widget.tipe}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 201) {
        Get.snackbar(
          'Permintaan Dikirim ✓',
          'Admin akan memverifikasi permintaan Anda.',
          backgroundColor: const Color(0xFF059669),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: 10,
        );
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().fetchNotifications();
        }
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed('/user');
      } else {
        final err = jsonDecode(res.body);
        Get.snackbar(
          'Gagal',
          err['message'] ?? 'Terjadi kesalahan',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: 10,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_late_outlined,
                    color: Color(0xFFF97316),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajukan Permintaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                      Text(
                        'Absensi di luar radius',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C8DB5),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFF7C8DB5),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE4EAF6)),
            const SizedBox(height: 16),

            // ── Info lokasi ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFDC2626).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_off_rounded,
                    color: Color(0xFFDC2626),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jarak Anda '
                      '${(widget.lokasiTerdekat['jarak'] as num?)?.toStringAsFixed(0) ?? '-'} m '
                      'dari ${widget.lokasiTerdekat['nama_lokasi'] ?? 'lokasi absen'} '
                      '(batas ${(widget.lokasiTerdekat['radius_meter'] as num?)?.toInt() ?? 100} m)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Tipe absen badge ──
            Row(
              children: [
                const Text(
                  'Tipe absen',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7C8DB5)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.tipe == 'masuk'
                        ? const Color(0xFFE8F3FF)
                        : const Color(0xFFFFF0E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.tipe == 'masuk' ? 'Absen Masuk' : 'Absen Pulang',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.tipe == 'masuk'
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFF97316),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Pilih alasan ──
            const Text(
              'Alasan permintaan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _alasanOptions.map((alasan) {
                final selected = _terpilih == alasan;
                return GestureDetector(
                  onTap: () => setState(() => _terpilih = alasan),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFF97316)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFF97316)
                            : const Color(0xFFE4EAF6),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      alasan,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF7C8DB5),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // ── Keterangan tambahan ──
            const Text(
              'Keterangan tambahan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alasanCtrl,
              maxLines: 3,
              maxLength: 200,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0D1B2A)),
              decoration: InputDecoration(
                hintText: 'Jelaskan situasi Anda...',
                hintStyle: const TextStyle(
                  color: Color(0xFF7C8DB5),
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: const Color(0xFFF3F6FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4EAF6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4EAF6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF97316),
                    width: 1.5,
                  ),
                ),
                counterStyle: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7C8DB5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Tombol aksi ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C8DB5),
                      side: const BorderSide(color: Color(0xFFE4EAF6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _kirim,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _isSending ? 'Mengirim...' : 'Kirim Permintaan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
