import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../controllers/pusat_lokasi_controller.dart';
import 'pilih_lokasi_modal.dart';

class TambahPusatLokasiModal {
  static void show(BuildContext context, PusatLokasiController controller) {
    final namaLokasiC = TextEditingController();
    final titikKordinatC = TextEditingController();
    final alamatC = TextEditingController(); // hanya untuk display
    final keteranganC = TextEditingController(); // FIX: pisah dari alamatC
    final formKey = GlobalKey<FormState>();

    GoogleMapController? mapController;
    LatLng? selectedLocation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        // FIX: agar preview map bisa re-render
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'Tambah Pusat Lokasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: namaLokasiC,
                      decoration: InputDecoration(
                        labelText: 'Nama Lokasi *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.place, color: Colors.blue),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama lokasi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: titikKordinatC,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Titik Kordinat *',
                              hintText: 'Pilih lokasi di maps',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(
                                Icons.location_on,
                                color: Colors.blue,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Titik kordinat wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.map, color: Colors.white),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PilihLokasiModal(
                                    onLocationPicked: (koordinat, alamat) {
                                      titikKordinatC.text = koordinat;
                                      alamatC.text = alamat;

                                      try {
                                        final parts = koordinat.split(',');
                                        if (parts.length == 2) {
                                          final lat = double.tryParse(
                                            parts[0].trim(),
                                          );
                                          final lng = double.tryParse(
                                            parts[1].trim(),
                                          );
                                          if (lat != null && lng != null) {
                                            // FIX: pakai setState agar preview map muncul
                                            setState(() {
                                              selectedLocation = LatLng(
                                                lat,
                                                lng,
                                              );
                                            });
                                          }
                                        }
                                      } catch (e) {
                                        debugPrint(
                                          'Error parsing koordinat: $e',
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                            tooltip: 'Pilih Lokasi',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (selectedLocation != null) ...[
                      const Text(
                        'Preview Lokasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: selectedLocation!,
                              zoom: 14,
                            ),
                            onMapCreated: (GoogleMapController c) {
                              mapController = c;
                            },
                            markers: {
                              Marker(
                                markerId: const MarkerId('selected_location'),
                                position: selectedLocation!,
                                infoWindow: InfoWindow(
                                  title: namaLokasiC.text.isEmpty
                                      ? 'Lokasi Baru'
                                      : namaLokasiC.text,
                                ),
                              ),
                            },
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            compassEnabled: true,
                            mapToolbarEnabled: false,
                            gestureRecognizers: const {},
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Alamat — hanya display, tidak dikirim ke API
                    TextFormField(
                      controller: alamatC,
                      maxLines: 2,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Alamat Lengkap',
                        hintText: 'Alamat akan terisi otomatis dari maps',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.location_city,
                          color: Colors.blue,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // FIX: controller terpisah untuk keterangan
                    TextFormField(
                      controller: keteranganC,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Keterangan (Opsional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.description,
                          color: Colors.blue,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(() {
                            final isLoading = controller.isSubmitting.value;
                            return ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        // TAMBAH DI SINI
                                        debugPrint('=== DEBUG ===');
                                        debugPrint(
                                          'user map: ${controller.auth.user}',
                                        );
                                        debugPrint(
                                          'employee map: ${controller.auth.employee.value}',
                                        );
                                        debugPrint(
                                          'companyId: ${controller.auth.companyId}',
                                        );
                                        debugPrint('=============');
                                        // FIX: ambil companyId dari auth user
                                        final companyId =
                                            controller.auth.companyId;
                                        if (companyId == null) {
                                          Get.snackbar(
                                            'Error',
                                            'Company ID tidak ditemukan',
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                          );
                                          return;
                                        }

                                        Navigator.pop(context);

                                        await controller.createPusatLokasi(
                                          companyId: companyId, // FIX
                                          namaLokasi: namaLokasiC.text.trim(),
                                          titikKordinat: titikKordinatC.text
                                              .trim(),
                                          keterangan:
                                              keteranganC.text.trim().isEmpty
                                              ? null
                                              : keteranganC.text.trim(), // FIX
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                isLoading ? 'Menyimpan...' : 'Simpan',
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
