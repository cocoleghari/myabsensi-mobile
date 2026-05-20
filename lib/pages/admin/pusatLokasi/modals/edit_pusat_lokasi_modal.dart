import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../controllers/pusat_lokasi_controller.dart';
import '../../../../models/pusat_lokasi_model.dart';
import 'pilih_lokasi_modal.dart';

class EditPusatLokasiModal {
  static void show(
    BuildContext context,
    PusatLokasiController controller,
    PusatLokasiModel item,
  ) {
    final namaLokasiC = TextEditingController(text: item.namaLokasi);
    final titikKordinatC = TextEditingController(text: item.titikKordinat);
    final alamatC = TextEditingController(text: item.keterangan ?? '');
    final formKey = GlobalKey<FormState>();

    // FIX: state lokal untuk map preview dan is_active
    GoogleMapController? mapController;
    LatLng? selectedLocation = item.isKordinatValid
        ? LatLng(item.latitude!, item.longitude!)
        : null;
    bool isActive = item.isActive; // FIX: ambil dari item

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        // FIX: wrap StatefulBuilder agar setState bisa dipakai
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
                    // Handle
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

                    // Title
                    const Center(
                      child: Text(
                        'Edit Pusat Lokasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Nama Lokasi
                    TextFormField(
                      controller: namaLokasiC,
                      decoration: InputDecoration(
                        labelText: 'Nama Lokasi *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.place,
                          color: Colors.orange,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama lokasi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Titik Kordinat + tombol pilih map
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: titikKordinatC,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Titik Kordinat *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(
                                Icons.location_on,
                                color: Colors.orange,
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
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.map, color: Colors.white),
                            onPressed: () async {
                              LatLng? initialLocation;
                              if (item.isKordinatValid) {
                                initialLocation = LatLng(
                                  item.latitude!,
                                  item.longitude!,
                                );
                              }

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
                                        debugPrint('Error parsing: $e');
                                      }
                                    },
                                    initialLocation: initialLocation,
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

                    // Preview Map — hanya muncul jika ada koordinat
                    if (selectedLocation != null) ...[
                      const Text(
                        'Preview Lokasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
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
                                markerId: const MarkerId('edit_location'),
                                position: selectedLocation!,
                                infoWindow: InfoWindow(
                                  title: namaLokasiC.text.isEmpty
                                      ? 'Lokasi'
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

                    // Alamat / Keterangan
                    TextFormField(
                      controller: alamatC,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Alamat Lengkap',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.location_city,
                          color: Colors.orange,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // FIX: Toggle is_active
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Status Aktif',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          isActive ? 'Lokasi ini aktif' : 'Lokasi ini nonaktif',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive
                                ? Colors.green.shade600
                                : Colors.red.shade400,
                          ),
                        ),
                        value: isActive,
                        onChanged: (val) => setState(() => isActive = val),
                        activeColor: Colors.orange,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tombol Batal & Update
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
                                        Navigator.pop(context);

                                        await controller.updatePusatLokasi(
                                          id: item.id,
                                          namaLokasi:
                                              namaLokasiC.text.trim() !=
                                                  item.namaLokasi
                                              ? namaLokasiC.text.trim()
                                              : null,
                                          titikKordinat:
                                              titikKordinatC.text.trim() !=
                                                  item.titikKordinat
                                              ? titikKordinatC.text.trim()
                                              : null,
                                          keterangan:
                                              alamatC.text.trim() !=
                                                  (item.keterangan ?? '')
                                              ? (alamatC.text.trim().isEmpty
                                                    ? null
                                                    : alamatC.text.trim())
                                              : null,
                                          // FIX: kirim is_active hanya jika berubah
                                          isActive: isActive != item.isActive
                                              ? isActive
                                              : null,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                isLoading ? 'Menyimpan...' : 'Update',
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
