import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/employee_pusat_lokasi_controller.dart';

class LokasiDeleteDialog {
  static void show({
    required BuildContext context,
    required int id,
    required String namaLokasi,
    required EmployeePusatLokasiController controller,
  }) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Lokasi'),
        content: Text('Yakin ingin menghapus lokasi "$namaLokasi"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteEmployeeLokasi(id);
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
