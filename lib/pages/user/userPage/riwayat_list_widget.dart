import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';
import 'package:myabsensi_mobile/utils/formatter_util.dart';
import 'package:get/get.dart';

class RiwayatListWidget extends StatelessWidget {
  final UserLokasiController controller;

  const RiwayatListWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingRiwayat.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.riwayatAbsensi.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum ada riwayat absensi',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.riwayatAbsensi.length,
        itemBuilder: (context, index) {
          final item = controller.riwayatAbsensi[index];
          return _buildRiwayatCard(item);
        },
      );
    });
  }

  Widget _buildRiwayatCard(Map<String, dynamic> item) {
    final tipe = item['tipe_absen'] ?? '';
    final waktu = item['waktu_absen'] ?? '';
    final lokasi = item['lokasi'] is Map
        ? item['lokasi']['lokasi'] ?? '-'
        : item['lokasi'] ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tipe == 'masuk' ? Colors.blue[50] : Colors.orange[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            tipe == 'masuk' ? Icons.login : Icons.logout,
            color: tipe == 'masuk' ? Colors.blue : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          lokasi,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          FormatterUtil.formatWaktuSimple(waktu),
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tipe == 'masuk' ? Colors.blue[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tipe == 'masuk' ? 'MASUK' : 'PULANG',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: tipe == 'masuk' ? Colors.blue : Colors.orange,
            ),
          ),
        ),
      ),
    );
  }
}
