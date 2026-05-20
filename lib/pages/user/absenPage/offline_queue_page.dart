import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/offline_absensi_controller.dart';
import 'package:myabsensi_mobile/models/offline_absensi_model.dart';
import 'dart:io';

class OfflineQueuePage extends StatelessWidget {
  const OfflineQueuePage({super.key});

  static void show() {
    Get.bottomSheet(
      const OfflineQueuePage(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      ignoreSafeArea: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final offline = Get.find<OfflineAbsensiController>();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(offline),
              _buildOfflineInfo(), // ← tambah di sini
              Expanded(
                child: Obx(() {
                  if (offline.queue.isEmpty) {
                    return _buildEmpty();
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: offline.queue.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final item = offline.queue[i];
                      return _QueueItemCard(item: item, offline: offline);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFDDE1E7),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(OfflineAbsensiController offline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Antrian Offline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Absensi tersimpan sementara',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
              ),
            ],
          ),
          const Spacer(),
          Obx(() {
            final isOnline = offline.isOnline.value;
            final isSyncing = offline.isSyncing.value;
            final hasPending = offline.pendingCount > 0;

            if (!isOnline || !hasPending) return const SizedBox.shrink();

            return GestureDetector(
              onTap: isSyncing ? null : () => offline.syncQueue(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Sync Semua',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF22C55E),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada antrian',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Semua absensi sudah tersinkronisasi',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
          ),
        ],
      ),
    );
  }
}

// Tambah di dalam class OfflineQueuePage setelah _buildHeader()
Widget _buildOfflineInfo() {
  return Obx(() {
    final offline = Get.find<OfflineAbsensiController>();
    if (offline.isOnline.value) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Color(0xFFF97316),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ups, sepertinya ada gangguan pada koneksimu!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEA580C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Saran Mengatasi Masalah:\nJika kamu terus-menerus mengalami masalah konektivitas, berikut beberapa saran untuk dicoba:',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFF97316),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildTip('1.', 'Periksa pengaturan Wi-Fi atau data seluler kamu.'),
          _buildTip('2.', 'Mendekatlah ke router atau coba jaringan lain.'),
          _buildTip(
            '3.',
            'Matikan dan hidupkan kembali perangkat untuk memuat ulang koneksi.',
          ),
          const SizedBox(height: 10),
          const Text(
            'Butuh bantuan lebih lanjut? Hubungi admin atau tim IT.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFF97316),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  });
}

Widget _buildTip(String number, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFF97316),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFF97316),
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Item Card ────────────────────────────────────────────────────────────────

class _QueueItemCard extends StatelessWidget {
  final OfflineAbsensiModel item;
  final OfflineAbsensiController offline;

  const _QueueItemCard({required this.item, required this.offline});

  @override
  Widget build(BuildContext context) {
    final isMasuk = item.tipe == 'masuk';
    final statusConfig = _statusConfig();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusConfig['borderColor'] as Color,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top Row ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto
                _buildFotoPreview(),
                const SizedBox(width: 12),
                // Info
                Expanded(child: _buildInfo(isMasuk, statusConfig)),
                // Hapus
                _buildDeleteButton(context),
              ],
            ),
          ),
          // ── Bottom: Koordinat ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FB),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: Color(0xFF8A94A6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.latitude.toStringAsFixed(6)}, '
                  '${item.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A94A6),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoPreview() {
    final file = File(item.fotoPath);
    final exists = file.existsSync();

    return GestureDetector(
      onTap: exists ? () => _showFotoDialog(file) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: exists
            ? Image.file(file, width: 64, height: 64, fit: BoxFit.cover)
            : Container(
                width: 64,
                height: 64,
                color: const Color(0xFFF0F0F0),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFFCCCCCC),
                  size: 28,
                ),
              ),
      ),
    );
  }

  void _showFotoDialog(File file) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(file, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildInfo(bool isMasuk, Map<String, dynamic> statusConfig) {
    final waktu = _formatWaktu(item.waktuAbsen);
    final tanggal = _formatTanggal(item.waktuAbsen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipe badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isMasuk
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isMasuk ? 'MASUK' : 'PULANG',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isMasuk
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFFEA580C),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusConfig['bgColor'] as Color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusConfig['icon'] as IconData,
                    size: 10,
                    color: statusConfig['color'] as Color,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    statusConfig['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusConfig['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          waktu,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1F36),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          tanggal,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
        ),
        if (item.status == 'failed' && item.errorMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 11,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  item.errorMessage!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFEF4444),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmDelete(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          size: 16,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Antrian?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Data absensi offline ini akan dihapus permanen dan tidak dapat dikembalikan.',
          style: TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF8A94A6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              offline.removeFromQueue(item.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _statusConfig() {
    switch (item.status) {
      case 'syncing':
        return {
          'label': 'Mengirim...',
          'icon': Icons.sync_rounded,
          'color': const Color(0xFF6366F1),
          'bgColor': const Color(0xFFEEF2FF),
          'borderColor': const Color(0xFFC7D2FE),
        };
      case 'failed':
        return {
          'label': 'Gagal',
          'icon': Icons.error_outline_rounded,
          'color': const Color(0xFFEF4444),
          'bgColor': const Color(0xFFFEF2F2),
          'borderColor': const Color(0xFFFECACA),
        };
      default: // pending
        return {
          'label': 'Menunggu',
          'icon': Icons.schedule_rounded,
          'color': const Color(0xFFF97316),
          'bgColor': const Color(0xFFFFF7ED),
          'borderColor': const Color(0xFFFED7AA),
        };
    }
  }

  String _formatWaktu(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTanggal(DateTime dt) {
    const hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${hari[dt.weekday - 1]}, ${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
  }
}
