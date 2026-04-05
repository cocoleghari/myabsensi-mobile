import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/admin_absensi_controller.dart';
import 'package:get/get.dart';

class AdminDeleteConfirmation {
  static void show({
    required BuildContext context,
    required int id,
    required String tipe,
    int? idPulang,
  }) {
    final controller = Get.find<AdminAbsensiController>();

    String pesan = '';
    String title = 'Konfirmasi Hapus';

    if (tipe == 'masuk') {
      pesan = 'Yakin ingin menghapus absen MASUK ini?';
    } else if (tipe == 'pulang') {
      pesan = 'Yakin ingin menghapus absen PULANG ini?';
    } else if (tipe == 'semua') {
      pesan = 'Yakin ingin menghapus SEMUA absensi (masuk & pulang) hari ini?';
    }

    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(pesan),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();

              bool success = false;
              if (tipe == 'masuk') {
                success = await controller.deleteAbsensi(id);
              } else if (tipe == 'pulang') {
                success = await controller.deleteAbsensi(id);
              } else if (tipe == 'semua' && idPulang != null) {
                bool success1 = await controller.deleteAbsensi(id);
                bool success2 = await controller.deleteAbsensi(idPulang);
                success = success1 && success2;
              }

              if (success) {
                Get.snackbar(
                  'Sukses',
                  'Data absensi berhasil dihapus',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 2),
                );
                controller.fetchAllAbsensi();
              } else {
                Get.snackbar(
                  'Error',
                  'Gagal menghapus data absensi',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
