import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'admin_formatter.dart';

class AdminDetailDialog {
  static const String baseUrl = 'http://192.168.1.12:8000';
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  static void show({
    required BuildContext context,
    required Map<String, dynamic>? dataMasuk,
    required Map<String, dynamic>? dataPulang,
    required String userName,
    required String tanggal,
  }) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.blue.shade50],
            ),
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(userName, tanggal),
                const SizedBox(height: 16),
                _buildTabBar(),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    children: [
                      dataMasuk != null
                          ? _DetailContent(item: dataMasuk, tipe: 'masuk')
                          : _EmptyContent(message: 'User belum absen masuk'),
                      dataPulang != null
                          ? _DetailContent(item: dataPulang, tipe: 'pulang')
                          : _EmptyContent(message: 'User belum absen pulang'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildCloseButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildHeader(String userName, String tanggal) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          child: Center(
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Absensi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                '$userName - ${AdminFormatter.formatTanggal(tanggal)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close, color: Colors.grey),
        ),
      ],
    );
  }

  static Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Absen Masuk'),
          Tab(text: 'Absen Pulang'),
        ],
      ),
    );
  }

  static Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Tutup',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Map<String, dynamic> item;
  final String tipe;

  const _DetailContent({required this.item, required this.tipe});

  @override
  Widget build(BuildContext context) {
    final data = _parseData(item);
    final themeColor = tipe == 'masuk' ? Colors.blue : Colors.orange;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Lokasi',
            value: data.lokasi,
            color: themeColor,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.pin_drop,
            label: 'Titik Koordinat Lokasi',
            value: data.koordinatLokasi,
            color: themeColor,
          ),
          const SizedBox(height: 12),
          if (data.lokasiLatLng != null) ...[
            const SizedBox(height: 8),
            Text(
              'Preview Lokasi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildMapPreview(
              latLng: data.lokasiLatLng!,
              markerColor: tipe == 'masuk'
                  ? BitmapDescriptor.hueBlue
                  : BitmapDescriptor.hueOrange,
            ),
            const SizedBox(height: 16),
          ],
          _buildInfoRow(
            icon: Icons.my_location,
            label: 'Titik Koordinat User',
            value: data.koordinatKamu.isNotEmpty
                ? data.koordinatKamu
                : '(Tidak tersedia)',
            valueColor: data.koordinatKamu.isNotEmpty
                ? Colors.green
                : Colors.grey,
            color: themeColor,
          ),
          const SizedBox(height: 12),
          if (data.kamuLatLng != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Preview Posisi User',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            _buildMapPreview(
              latLng: data.kamuLatLng!,
              markerColor: BitmapDescriptor.hueGreen,
            ),
            const SizedBox(height: 16),
          ],
          _buildWaktuCard(themeColor, data.waktu),
          const SizedBox(height: 16),
          if (data.fotoWajah.isNotEmpty) _buildFotoCard(data.fotoWajah),
        ],
      ),
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
    } catch (e) {
      print('Error parsing lokasi: $e');
    }

    try {
      if (item['titik_koordinat_lokasi'] != null) {
        koordinatLokasi = item['titik_koordinat_lokasi'].toString();
      }

      if (koordinatLokasi != '-') {
        try {
          final parts = koordinatLokasi.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0].trim());
            final lng = double.tryParse(parts[1].trim());
            if (lat != null && lng != null) {
              lokasiLatLng = LatLng(lat, lng);
            }
          }
        } catch (e) {
          print('Error parsing koordinat lokasi: $e');
        }
      }
    } catch (e) {
      print('Error processing koordinat lokasi: $e');
    }

    try {
      if (item['titik_koordinat_kamu'] != null &&
          item['titik_koordinat_kamu'].toString().isNotEmpty) {
        koordinatKamu = item['titik_koordinat_kamu'].toString();
        try {
          final parts = koordinatKamu.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0].trim());
            final lng = double.tryParse(parts[1].trim());
            if (lat != null && lng != null) {
              kamuLatLng = LatLng(lat, lng);
            }
          }
        } catch (e) {
          print('Error parsing koordinat kamu: $e');
        }
      }
    } catch (e) {
      print('Error processing koordinat kamu: $e');
    }

    try {
      if (item['foto_wajah'] != null &&
          item['foto_wajah'].toString().isNotEmpty) {
        fotoWajah = item['foto_wajah'].toString();
      }
    } catch (e) {
      print('Error parsing foto wajah: $e');
    }

    try {
      if (item['waktu_absen'] != null) {
        waktu = AdminFormatter.formatWaktuLengkap(
          item['waktu_absen'].toString(),
        );
      }
    } catch (e) {
      print('Error parsing waktu absen: $e');
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Color color = Colors.blue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 24, child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview({
    required LatLng latLng,
    required double markerColor,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildWaktuCard(Color themeColor, String waktu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waktu Absen $tipe',
            style: TextStyle(
              fontSize: 11,
              color: themeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            waktu,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoCard(String fotoWajah) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Bukti',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              AdminFormatter.getFullImageUrl(
                fotoWajah,
                AdminDetailDialog.baseUrl,
              ),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Text('Gagal memuat foto')),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyContent extends StatelessWidget {
  final String message;

  const _EmptyContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

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
