import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/pusat_lokasi_controller.dart';

class ImportExportPusatLokasiModal {
  static void show(BuildContext context, PusatLokasiController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.import_export,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import / Export',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Kelola data pusat lokasi via file',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Divider(height: 1),
            const SizedBox(height: 20),

            // Tombol Export
            Obx(
              () => _buildOptionTile(
                icon: Icons.download_rounded,
                color: Colors.green,
                title: 'Export Data',
                subtitle: 'Unduh semua pusat lokasi ke file Excel',
                isLoading: controller.isExporting.value,
                onTap: () async {
                  Navigator.pop(context);
                  await controller.exportPusatLokasi();
                },
              ),
            ),

            const SizedBox(height: 12),

            // Tombol Download Template
            Obx(
              () => _buildOptionTile(
                icon: Icons.file_download_outlined,
                color: Colors.orange,
                title: 'Download Template',
                subtitle: 'Unduh template Excel untuk import',
                isLoading: controller.isDownloadingTemplate.value,
                onTap: () async {
                  Navigator.pop(context);
                  await controller.downloadTemplate();
                },
              ),
            ),

            const SizedBox(height: 12),

            // Tombol Import
            Obx(
              () => _buildOptionTile(
                icon: Icons.upload_rounded,
                color: Colors.blue,
                title: 'Import Data',
                subtitle: 'Upload file Excel/CSV untuk menambah data',
                isLoading: controller.isImporting.value,
                onTap: () async {
                  Navigator.pop(context);
                  await controller.importPusatLokasi();
                },
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Widget _buildOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
          color: isLoading ? Colors.grey.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isLoading ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
