import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../controllers/user_lokasi_controller.dart';
import 'hasil_absensi_page.dart';

class PreviewAbsensiPage extends StatefulWidget {
  final String tipe;
  final File fotoAbsen;
  final String fotoReferensiUrl;
  final Map<String, dynamic> lokasiTerdekat;
  final String koordinatUser;
  final double confidenceScore;
  final bool wajahCocok;
  final double akurasi;

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
  });

  @override
  State<PreviewAbsensiPage> createState() => _PreviewAbsensiPageState();
}

class _PreviewAbsensiPageState extends State<PreviewAbsensiPage> {
  GoogleMapController? _mapController;
  final controller = Get.find<UserLokasiController>();

  LatLng get _userLatLng {
    final parts = widget.koordinatUser.split(',');
    return LatLng(double.parse(parts[0].trim()), double.parse(parts[1].trim()));
  }

  LatLng get _lokasiLatLng {
    final parts = widget.lokasiTerdekat['koordinat'].split(',');
    return LatLng(double.parse(parts[0].trim()), double.parse(parts[1].trim()));
  }

  // Warna icon akurasi — hijau jika akurat, kuning sedang, merah buruk
  Color _getAkurasiColor(double akurasi) {
    if (akurasi <= 10) return Colors.green;
    if (akurasi <= 30) return Colors.orange;
    return Colors.red;
  }

  Set<Marker> get _markers => {
    Marker(
      markerId: const MarkerId('user'),
      position: _userLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Posisi Anda'),
    ),
    Marker(
      markerId: const MarkerId('lokasi'),
      position: _lokasiLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: widget.lokasiTerdekat['lokasi']),
    ),
  };

  Set<Circle> get _circles => {
    Circle(
      circleId: const CircleId('radius'),
      center: _lokasiLatLng,
      radius: 100,
      fillColor: Colors.green.withOpacity(0.25),
      strokeColor: Colors.green.withOpacity(0.6),
      strokeWidth: 2,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final bool lokasiOke = widget.lokasiTerdekat['dalam_radius'] == true;
    final bool bisaSimpan = lokasiOke && widget.wajahCocok;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Preview Absensi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── PETA ──────────────────────────────────────────────────
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  // Peta
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

                  // Badge akurasi lokasi — pojok kanan bawah
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.my_location,
                              size: 14,
                              color: _getAkurasiColor(widget.akurasi),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Location accuracy ${widget.akurasi.toStringAsFixed(0)} meters',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── STATUS LOKASI (muncul jika di luar radius) ────────────
            if (!lokasiOke)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: Colors.red[50],
                child: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.red[600], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lokasi tidak sesuai — Anda berada '
                        '${widget.lokasiTerdekat['jarak'].toStringAsFixed(0)} m '
                        'dari ${widget.lokasiTerdekat['lokasi']} '
                        '(batas 100 m)',
                        style: TextStyle(fontSize: 12, color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),

            // ── INFO NAMA & WAKTU ────────────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Text(
                    controller.auth.user['name']?.toString() ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTanggalWaktu(now),
                    style: TextStyle(fontSize: 13, color: Colors.orange[700]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── PERBANDINGAN FOTO ────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto absen (portrait 3:4, mirror)
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..scale(-1.0, 1.0),
                                  child: Image.file(
                                    widget.fotoAbsen,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Attendance Photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Base photo (portrait 3:4, mirror)
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..scale(-1.0, 1.0),
                                  child: Image.network(
                                    widget.fotoReferensiUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                progress.expectedTotalBytes !=
                                                    null
                                                ? progress.cumulativeBytesLoaded /
                                                      progress
                                                          .expectedTotalBytes!
                                                : null,
                                            color: Colors.blue,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.person,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Base Photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── HASIL MATCH CHECK ──────────────────────────────
                  _buildMatchResult(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── TOMBOL AKSI ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: _buildActionButton(bisaSimpan, lokasiOke),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchResult() {
    if (widget.wajahCocok) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face_retouching_natural,
              color: Colors.green[600],
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Match Check : Passed ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            Text(
              '(${(widget.confidenceScore * 100).toStringAsFixed(2)}% Match)',
              style: TextStyle(
                color: Colors.green[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.face_retouching_off, color: Colors.red[600], size: 22),
            const SizedBox(width: 8),
            Text(
              'Match Check : Failed ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            Text(
              '(${(widget.confidenceScore * 100).toStringAsFixed(2)}%)',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButton(bool bisaSimpan, bool lokasiOke) {
    // Lokasi tidak sesuai
    if (!lokasiOke) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lokasi tidak sesuai, tidak dapat absen',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Wajah tidak cocok — tampilkan tombol foto ulang
    if (!widget.wajahCocok) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.back(), // kembali untuk foto ulang
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'Foto Ulang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wajah tidak cocok dengan data terdaftar',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      );
    }

    // Semua OK — Save Attendance
    return Obx(() {
      final isLoading = controller.isSubmitting.value;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  await _simpanAbsensi();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.orange.withOpacity(0.6),
          ),
          child: isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Menyimpan...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Save Attendance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      );
    });
  }

  Future<void> _simpanAbsensi() async {
    final success = await controller.kirimAbsensiDariPreview(
      lokasiTerpilih: widget.lokasiTerdekat,
      titikKoordinatKamu: widget.koordinatUser,
      foto: widget.fotoAbsen,
      tipe: widget.tipe,
    );

    if (success && mounted) {
      // Beri jeda kecil agar UI tidak langsung freeze
      await Future.delayed(const Duration(milliseconds: 300));
      Get.offAll(() => HasilAbsensiPage(tipe: widget.tipe));
    }
  }

  String _formatTanggalWaktu(DateTime dt) {
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
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '${bulan[dt.month - 1]}, ${dt.day} ${dt.year}, $jam:$menit';
  }
}
