import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../controllers/user_lokasi_controller.dart';

class AbsensiModal extends StatefulWidget {
  final String tipe;

  const AbsensiModal({super.key, this.tipe = 'masuk'});

  @override
  State<AbsensiModal> createState() => _AbsensiModalState();
}

class _AbsensiModalState extends State<AbsensiModal> {
  String? selectedLokasiId;
  String? selectedLokasiNama;
  String? selectedLokasiKoordinat;

  late final UserLokasiController lokasiController;

  GoogleMapController? mapController;
  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();
    lokasiController = Get.find<UserLokasiController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      lokasiController.isLoading.value = false;
      lokasiController.fetchUserLokasi();
    });
  }

  void _onLokasiSelected(String? value) {
    if (value != null) {
      final selected = lokasiController.userLokasis.firstWhere(
        (l) => l['id'].toString() == value,
      );

      setState(() {
        selectedLokasiId = value;
        selectedLokasiNama = selected['lokasi'];
        selectedLokasiKoordinat = selected['koordinat'];

        if (selectedLokasiKoordinat != null) {
          try {
            final parts = selectedLokasiKoordinat!.split(',');
            if (parts.length == 2) {
              final lat = double.tryParse(parts[0].trim());
              final lng = double.tryParse(parts[1].trim());
              if (lat != null && lng != null) {
                selectedLocation = LatLng(lat, lng);
                if (mapController != null) {
                  mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(selectedLocation!, 16),
                  );
                }
              } else {
                selectedLocation = null;
              }
            } else {
              selectedLocation = null;
            }
          } catch (e) {
            print('Error parsing koordinat: $e');
            selectedLocation = null;
          }
        }
      });
    }
  }

  String _getModalTitle() {
    return widget.tipe == 'masuk' ? 'Absen Masuk' : 'Absen Pulang';
  }

  String _getButtonText() {
    return widget.tipe == 'masuk' ? 'KONFIRMASI MASUK' : 'KONFIRMASI PULANG';
  }

  Color _getButtonColor() {
    return widget.tipe == 'masuk' ? Colors.blue : Colors.orange;
  }

  Future<void> _submitAbsensi() async {
    if (selectedLokasiId == null ||
        selectedLokasiNama == null ||
        selectedLokasiKoordinat == null) {
      return;
    }

    await lokasiController.prosesAbsensi(widget.tipe);

    if (mounted) {
      Get.back();
    }
  }

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

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getButtonColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.tipe == 'masuk' ? Icons.login : Icons.logout,
                    color: _getButtonColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getModalTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pilih lokasi absensi Anda',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Tombol refresh di modal
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: _getButtonColor(),
                      size: 20,
                    ),
                    onPressed: () {
                      lokasiController.fetchUserLokasi();
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
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: Obx(() {
              // Loading state
              if (lokasiController.isLoading.value) {
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

              // Error state
              if (lokasiController.errorMessage.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          lokasiController.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            lokasiController.fetchUserLokasi();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Empty state
              if (lokasiController.userLokasis.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 64),
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
                          onPressed: () {
                            lokasiController.fetchUserLokasi();
                          },
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

              // Normal state dengan daftar lokasi
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    const Text(
                      'Pilih Lokasi Absensi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('-- Pilih Lokasi --'),
                        value: selectedLokasiId,
                        isExpanded: true,
                        items: lokasiController.userLokasis.map((lokasi) {
                          return DropdownMenuItem<String>(
                            value: lokasi['id'].toString(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lokasi['lokasi'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '📍 ${lokasi['koordinat']}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _onLokasiSelected,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Map Preview
                    if (selectedLocation != null) ...[
                      const Text(
                        'Preview Lokasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
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
                                initialCameraPosition: CameraPosition(
                                  target: selectedLocation!,
                                  zoom: 16,
                                ),
                                onMapCreated: (controller) {
                                  mapController = controller;
                                },
                                markers: {
                                  Marker(
                                    markerId: const MarkerId(
                                      'selected_location',
                                    ),
                                    position: selectedLocation!,
                                    infoWindow: InfoWindow(
                                      title: selectedLokasiNama,
                                      snippet: selectedLokasiKoordinat,
                                    ),
                                  ),
                                },
                                zoomControlsEnabled: true,
                                myLocationButtonEnabled: false,
                                compassEnabled: true,
                                mapToolbarEnabled: false,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
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
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Lokasi dipilih',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade700,
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

                      const SizedBox(height: 16),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getButtonColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _getButtonColor().withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: _getButtonColor(),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedLokasiNama ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getButtonColor(),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedLokasiKoordinat ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getButtonColor().withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Tombol Konfirmasi
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: Obx(() {
                        final isSubmitting =
                            lokasiController.isSubmitting.value;
                        return ElevatedButton(
                          onPressed: (selectedLokasiId != null && !isSubmitting)
                              ? _submitAbsensi
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getButtonColor(),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            isSubmitting
                                ? 'Memproses...'
                                : (selectedLokasiId != null
                                      ? _getButtonText()
                                      : 'PILIH LOKASI TERLEBIH DAHULU'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
