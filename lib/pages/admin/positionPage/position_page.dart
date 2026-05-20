import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/position_controller.dart';
import '../../../models/position_model.dart';
import '../master_drawer.dart';
import 'position_form_dialog.dart';

class PositionPage extends StatelessWidget {
  const PositionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PositionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posisi / Jabatan'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          Obx(
            () => ctrl.isExporting.value
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.import_export),
                    tooltip: 'Export / Import',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (action) async {
                      if (action == 'export') {
                        await ctrl.exportPositions();
                      } else if (action == 'import') {
                        await ctrl.importPositions();
                      } else if (action == 'template') {
                        await ctrl.downloadImportTemplate();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(
                              Icons.download_outlined,
                              size: 18,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text('Export ke Excel'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(
                              Icons.upload_outlined,
                              size: 18,
                              color: Colors.indigo,
                            ),
                            SizedBox(width: 8),
                            Text('Import dari Excel'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'template',
                        child: Row(
                          children: [
                            Icon(
                              Icons.file_download_outlined,
                              size: 18,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text('Unduh Template'),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ctrl.fetchPositions(),
          ),
        ],
      ),
      drawer: const MasterDrawer(currentPage: 'positions'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ctrl),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Posisi'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          _buildSearchBar(ctrl),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value && ctrl.positions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (ctrl.positions.isEmpty) {
                return const Center(child: Text('Belum ada posisi.'));
              }
              return RefreshIndicator(
                onRefresh: () => ctrl.fetchPositions(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: ctrl.positions.length,
                  itemBuilder: (_, i) =>
                      _PositionCard(position: ctrl.positions[i], ctrl: ctrl),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(PositionController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari nama posisi...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (v) {
          ctrl.searchQuery.value = v;
          ctrl.fetchPositions();
        },
      ),
    );
  }

  void _showForm(
    BuildContext context,
    PositionController ctrl, {
    Position? position,
  }) {
    showDialog(
      context: context,
      builder: (_) => PositionFormDialog(position: position, ctrl: ctrl),
    );
  }
}

class _PositionCard extends StatelessWidget {
  final Position position;
  final PositionController ctrl;

  const _PositionCard({required this.position, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: position.isActive
                ? Colors.indigo.shade50
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.work_outline,
            color: position.isActive ? Colors.indigo : Colors.grey,
          ),
        ),
        title: Text(
          position.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (position.companyName != null)
              Text(
                position.companyName!,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            Row(
              children: [
                if (position.code != null)
                  Chip(
                    label: Text(
                      position.code!,
                      style: const TextStyle(fontSize: 10),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.indigo.shade50,
                  ),
                const SizedBox(width: 6),
                if (position.totalEmployees != null)
                  Text(
                    '${position.totalEmployees} karyawan',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') {
              showDialog(
                context: context,
                builder: (_) =>
                    PositionFormDialog(position: position, ctrl: ctrl),
              );
            } else if (val == 'delete') {
              _confirmDelete(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'delete',
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Posisi'),
        content: Text('Hapus posisi "${position.name}"?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              ctrl.deletePosition(position.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
