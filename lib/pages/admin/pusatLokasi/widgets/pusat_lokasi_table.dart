import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/pusat_lokasi_controller.dart';
import '../../../../models/pusat_lokasi_model.dart';
import '../modals/edit_pusat_lokasi_modal.dart';
import '../modals/detail_pusat_lokasi_modal.dart';
import '../modals/bulk_assign_karyawan_modal.dart';

class PusatLokasiTable extends StatelessWidget {
  final PusatLokasiController controller;

  const PusatLokasiTable({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.filteredLokasis.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data...'),
            ],
          ),
        );
      }

      if (controller.errorMessage.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => controller.fetchPusatLokasi(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.filteredLokasis.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.value.isEmpty
                    ? 'Belum ada data pusat lokasi'
                    : 'Tidak ada hasil untuk "${controller.searchQuery.value}"',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
              ),
              if (controller.searchQuery.value.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => controller.search(''),
                  child: const Text('Reset Pencarian'),
                ),
              ],
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: controller.filteredLokasis.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = controller.filteredLokasis[index];
          final isSelected = controller.selectedIds.contains(item.id);

          return _buildCard(context, item, isSelected, index);
        },
      );
    });
  }

  Widget _buildCard(
    BuildContext context,
    PusatLokasiModel item,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        if (controller.isSelectionMode.value) {
          controller.toggleSelectItem(item.id);
        } else {
          DetailPusatLokasiModal.show(context, item);
        }
      },
      onLongPress: () {
        if (!controller.isSelectionMode.value) {
          controller.toggleSelectionMode();
          controller.toggleSelectItem(item.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              // Avatar / Checkbox
              if (controller.isSelectionMode.value)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => controller.toggleSelectItem(item.id),
                    activeColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                )
              else
                Container(
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    gradient: item.isActive
                        ? LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: item.isActive
                        ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

              // Konten
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.namaLokasi,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(item.isActive),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          item.isKordinatValid
                              ? Icons.gps_fixed_rounded
                              : Icons.gps_not_fixed_rounded,
                          size: 12,
                          color: item.isKordinatValid
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.formattedKordinat,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.keterangan != null &&
                        item.keterangan!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.keterangan!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Menu
              if (!controller.isSelectionMode.value)
                PopupMenuButton<String>(
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.grey.shade500,
                      size: 18,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                  onSelected: (value) {
                    if (value == 'detail') {
                      DetailPusatLokasiModal.show(context, item);
                    } else if (value == 'assign') {
                      // ← BARU
                      BulkAssignKaryawanModal.show(context, controller, item);
                    } else if (value == 'edit') {
                      EditPusatLokasiModal.show(context, controller, item);
                    } else if (value == 'hapus') {
                      _showDeleteConfirmation(context, controller, item);
                    }
                  },
                  itemBuilder: (_) => [
                    _buildMenuItem(
                      value: 'detail',
                      icon: Icons.visibility_outlined,
                      label: 'Detail',
                      color: Colors.blue,
                    ),
                    _buildMenuItem(
                      value: 'assign', // ← BARU
                      icon: Icons.people_alt_rounded,
                      label: 'Assign Karyawan',
                      color: Colors.teal,
                    ),
                    _buildMenuItem(
                      value: 'edit',
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: Colors.orange,
                    ),
                    _buildMenuItem(
                      value: 'hapus',
                      icon: Icons.delete_outline_rounded,
                      label: 'Hapus',
                      color: Colors.red,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade600 : Colors.red.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Aktif' : 'Nonaktif',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green.shade700 : Colors.red.shade500,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    PusatLokasiController controller,
    PusatLokasiModel item,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Hapus Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Yakin ingin menghapus lokasi "${item.namaLokasi}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deletePusatLokasi(item.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
