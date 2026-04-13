import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../controllers/user_lokasi_controller.dart';

class DaftarLokasiModal {
  static void show(BuildContext context, UserLokasiController controller) {
    GoogleMapController? mapController;
    final selectedLocation = Rxn<LatLng>();
    final selectedLokasi = Rxn<Map<String, dynamic>>();

    void log(String message) {
      if (kDebugMode) {
        debugPrint('📍 [DaftarLokasiModal] $message');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Daftar Lokasi Absensi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: Obx(() {
                if (controller.userLokasis.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada lokasi tersedia',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hubungi admin untuk menambahkan lokasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.userLokasis.length,
                        itemBuilder: (context, index) {
                          final lokasi = controller.userLokasis[index];
                          final isSelected = selectedLokasi.value == lokasi;
                          final isTerdekat =
                              lokasi['id'] ==
                              controller.lokasiTerpilih.value?['id'];
                          final jarak = controller.jarakTerdekat.value;

                          return GestureDetector(
                            onTap: () {
                              selectedLokasi.value = lokasi;
                              try {
                                final parts = lokasi['koordinat'].split(',');
                                if (parts.length == 2) {
                                  final lat = double.tryParse(parts[0].trim());
                                  final lng = double.tryParse(parts[1].trim());
                                  if (lat != null && lng != null) {
                                    selectedLocation.value = LatLng(lat, lng);
                                    if (mapController != null) {
                                      mapController!.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                          selectedLocation.value!,
                                          16,
                                        ),
                                      );
                                    }
                                  }
                                }
                              } catch (e) {
                                log('Error parsing koordinat: $e');
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue[50]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey[200]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lokasi['lokasi'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? Colors.blue[700]
                                                      : Colors.grey[800],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isTerdekat) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Terdekat',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: Colors.green[600],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lokasi['koordinat'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isTerdekat) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: controller.isInRange.value
                                                  ? Colors.green[50]
                                                  : Colors.orange[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  controller.isInRange.value
                                                      ? Icons.check_circle
                                                      : Icons.warning,
                                                  size: 10,
                                                  color:
                                                      controller.isInRange.value
                                                      ? Colors.green[600]
                                                      : Colors.orange[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  controller.isInRange.value
                                                      ? 'Dalam radius (${jarak.toStringAsFixed(1)} m)'
                                                      : 'Luar radius (${jarak.toStringAsFixed(1)} m)',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color:
                                                        controller
                                                            .isInRange
                                                            .value
                                                        ? Colors.green[600]
                                                        : Colors.orange[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    if (selectedLocation.value != null)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: ClipRRect(
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: selectedLocation.value!,
                                  zoom: 16,
                                ),
                                onMapCreated: (controller) {
                                  mapController = controller;
                                },
                                markers: {
                                  Marker(
                                    markerId: MarkerId(
                                      'selected_location_${DateTime.now().millisecondsSinceEpoch}',
                                    ),
                                    position: selectedLocation.value!,
                                    infoWindow: InfoWindow(
                                      title: selectedLokasi.value?['lokasi'],
                                    ),
                                  ),
                                },
                                zoomControlsEnabled: true,
                                myLocationButtonEnabled: false,
                                compassEnabled: true,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        selectedLokasi.value?['lokasi'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
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
                  ],
                );
              }),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Tutup',
                    style: TextStyle(color: Colors.grey[700]),
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
