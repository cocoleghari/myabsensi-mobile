import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../controllers/user_lokasi_controller.dart';

/// AbsensiModal — dipanggil saat user menekan tombol absen masuk/pulang.
///
/// Field lokasi yang digunakan (dari response GET /user/lokasi):
///   id              : id pivot employee_pusat_lokasi
///   pusat_lokasi_id : FK ke tabel pusat_lokasi
///   nama_lokasi     : string nama lokasi
///   latitude        : double (sudah di-parse backend)
///   longitude       : double (sudah di-parse backend)
///   radius_meter    : double, radius per relasi karyawan
///   is_active       : bool
class AbsensiModal extends StatefulWidget {
  final String tipe;

  const AbsensiModal({super.key, this.tipe = 'masuk'});

  @override
  State<AbsensiModal> createState() => _AbsensiModalState();
}

class _AbsensiModalState extends State<AbsensiModal> {
  // ID pivot yang dipilih (employee_pusat_lokasi.id)
  String? _selectedPivotId;
  // Data lokasi terpilih (Map dari userLokasis)
  Map<String, dynamic>? _selectedLokasi;

  late final UserLokasiController _ctrl;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<UserLokasiController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.isLoading.value = false;
      _ctrl.fetchUserLokasi();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  void _onLokasiSelected(String? pivotId) {
    if (pivotId == null) return;

    // Cari lokasi dari userLokasis berdasarkan id pivot
    final found = _ctrl.userLokasis.firstWhereOrNull(
      (l) => l['id'].toString() == pivotId,
    );
    if (found == null) return;

    setState(() {
      _selectedPivotId = pivotId;
      _selectedLokasi = Map<String, dynamic>.from(found);
    });

    // Animasi kamera ke koordinat terpilih
    final lat = (found['latitude'] as num?)?.toDouble();
    final lng = (found['longitude'] as num?)?.toDouble();
    if (lat != null && lng != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
      );
    }
  }

  Future<void> _submitAbsensi() async {
    if (_selectedLokasi == null) return;
    await _ctrl.prosesAbsensi(widget.tipe);
    if (mounted) Get.back();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String get _modalTitle =>
      widget.tipe == 'masuk' ? 'Absen Masuk' : 'Absen Pulang';

  String get _buttonText =>
      widget.tipe == 'masuk' ? 'KONFIRMASI MASUK' : 'KONFIRMASI PULANG';

  Color get _accentColor =>
      widget.tipe == 'masuk' ? Colors.blue : Colors.orange;

  /// Dapatkan LatLng dari lokasi terpilih.
  /// Field 'latitude' & 'longitude' sudah float dari backend.
  LatLng? get _selectedLatLng {
    if (_selectedLokasi == null) return null;
    final lat = (_selectedLokasi!['latitude'] as num?)?.toDouble();
    final lng = (_selectedLokasi!['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  /// Nama lokasi terpilih dari field 'nama_lokasi'.
  String get _selectedNamaLokasi =>
      _selectedLokasi?['nama_lokasi']?.toString() ?? '';

  /// Radius lokasi terpilih dari field 'radius_meter'.
  double get _selectedRadius =>
      (_selectedLokasi?['radius_meter'] as num?)?.toDouble() ?? 100.0;

  /// Label koordinat untuk ditampilkan di UI.
  String get _selectedKoordinatLabel {
    final ll = _selectedLatLng;
    if (ll == null) return '-';
    return '${ll.latitude.toStringAsFixed(6)}, ${ll.longitude.toStringAsFixed(6)}';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          _buildHeader(),

          const Divider(height: 1),

          // Content
          Expanded(child: Obx(() => _buildContent())),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.tipe == 'masuk' ? Icons.login : Icons.logout,
              color: _accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _modalTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pilih lokasi absensi Anda',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Tombol refresh
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: _accentColor, size: 20),
              onPressed: () {
                setState(() {
                  _selectedPivotId = null;
                  _selectedLokasi = null;
                });
                _ctrl.fetchUserLokasi();
                Get.snackbar(
                  'Sukses',
                  'Daftar lokasi diperbarui',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 1),
                );
              },
              tooltip: 'Refresh Lokasi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Loading
    if (_ctrl.isLoading.value) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data lokasi...'),
          ],
        ),
      );
    }

    // Error
    if (_ctrl.errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _ctrl.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _ctrl.fetchUserLokasi,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty
    if (_ctrl.userLokasis.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Belum ada lokasi absensi',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Hubungi admin untuk menambahkan lokasi',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _ctrl.fetchUserLokasi,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal — daftar lokasi
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label dropdown
          const Text(
            'Pilih Lokasi Absensi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Dropdown — menggunakan field terbaru dari backend
          _buildLokasiDropdown(),

          const SizedBox(height: 20),

          // Preview map (hanya jika lokasi sudah dipilih dan koordinat valid)
          if (_selectedLatLng != null) ...[
            const Text(
              'Preview Lokasi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildMapPreview(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 20),
          ],

          // Tombol konfirmasi
          _buildConfirmButton(),
        ],
      ),
    );
  }

  // ─── Dropdown ─────────────────────────────────────────────────────────────
  // Menggunakan field terbaru:
  //   lokasi['id']            → value dropdown (id pivot)
  //   lokasi['nama_lokasi']   → label utama (bukan 'lokasi')
  //   lokasi['latitude']      → float (bukan dari string 'koordinat')
  //   lokasi['longitude']     → float
  //   lokasi['radius_meter']  → radius per karyawan
  //   lokasi['is_active']     → filter hanya yang aktif

  Widget _buildLokasiDropdown() {
    // Filter hanya lokasi aktif
    final aktifList = _ctrl.userLokasis
        .where((l) => l['is_active'] != false)
        .toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        hint: const Text('-- Pilih Lokasi --'),
        value: _selectedPivotId,
        isExpanded: true,
        items: aktifList.map((lokasi) {
          final lat = (lokasi['latitude'] as num?)?.toDouble();
          final lng = (lokasi['longitude'] as num?)?.toDouble();
          final radius = (lokasi['radius_meter'] as num?)?.toInt() ?? 100;

          // Koordinat display
          String koordinatDisplay = '-';
          if (lat != null && lng != null) {
            koordinatDisplay =
                '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
          }

          return DropdownMenuItem<String>(
            value: lokasi['id'].toString(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // nama_lokasi (field terbaru, bukan 'lokasi')
                Text(
                  lokasi['nama_lokasi']?.toString() ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 10, color: Colors.grey),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        koordinatDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tampilkan radius per relasi
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'r: ${radius}m',
                        style: TextStyle(
                          fontSize: 9,
                          color: _accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: _onLokasiSelected,
      ),
    );
  }

  // ─── Map Preview ──────────────────────────────────────────────────────────

  Widget _buildMapPreview() {
    final ll = _selectedLatLng!;
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: ll, zoom: 16),
              onMapCreated: (controller) => _mapController = controller,
              markers: {
                Marker(
                  markerId: const MarkerId('selected_location'),
                  position: ll,
                  infoWindow: InfoWindow(
                    title: _selectedNamaLokasi,
                    snippet: _selectedKoordinatLabel,
                  ),
                ),
              },
              circles: {
                // Tampilkan lingkaran radius absensi
                Circle(
                  circleId: const CircleId('radius'),
                  center: ll,
                  radius: _selectedRadius,
                  fillColor: _accentColor.withOpacity(0.12),
                  strokeColor: _accentColor.withOpacity(0.5),
                  strokeWidth: 1,
                ),
              },
              zoomControlsEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
            ),
            // Badge overlay
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Radius: ${_selectedRadius.toInt()}m',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
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
    );
  }

  // ─── Info Card ────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _accentColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedNamaLokasi,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '📍 $_selectedKoordinatLabel',
                  style: TextStyle(
                    fontSize: 10,
                    color: _accentColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '🎯 Radius: ${_selectedRadius.toInt()} meter',
                  style: TextStyle(
                    fontSize: 10,
                    color: _accentColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Confirm Button ───────────────────────────────────────────────────────

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Obx(() {
        final isSubmitting = _ctrl.isSubmitting.value;
        final canSubmit = _selectedPivotId != null && !isSubmitting;
        return ElevatedButton(
          onPressed: canSubmit ? _submitAbsensi : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: canSubmit ? 2 : 0,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _selectedPivotId != null
                      ? _buttonText
                      : 'PILIH LOKASI TERLEBIH DAHULU',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        );
      }),
    );
  }
}
