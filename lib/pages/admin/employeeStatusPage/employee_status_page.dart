import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/employee_status_controller.dart';
import '../../../pages/admin/master_drawer.dart';

class EmployeeStatusPage extends StatelessWidget {
  const EmployeeStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EmployeeStatusController());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Status Karyawan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchStatuses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const MasterDrawer(currentPage: 'employee-statuses'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context, controller),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Status'),
      ),
      body: Column(
        children: [
          _buildSearchBar(controller),
          Expanded(child: _buildList(context, controller)),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(EmployeeStatusController controller) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        onChanged: (v) => controller.searchQuery.value = v,
        decoration: InputDecoration(
          hintText: 'Cari kode atau label...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LIST
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, EmployeeStatusController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.statuses.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.filteredStatuses;

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.label_off_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada status karyawan',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchStatuses,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: list.length,
          itemBuilder: (_, i) => _buildCard(context, controller, list[i]),
        ),
      );
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCard(
    BuildContext context,
    EmployeeStatusController controller,
    Map<String, dynamic> status,
  ) {
    final color = EmployeeStatusController.colorFromString(status['color']);
    final isActive = status['is_active'] == true;
    final isVisible = status['is_visible'] == true;
    final empCount = status['employees_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.label, color: color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                status['label'] ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            // Badge warna
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status['code'] ?? '',
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              _statusChip(
                isActive ? 'Bisa Absen' : 'Tidak Absen',
                isActive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              _statusChip(
                isVisible ? 'Tampil' : 'Tersembunyi',
                isVisible ? Colors.blue : Colors.grey,
              ),
              const Spacer(),
              Text(
                '$empCount karyawan',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showFormDialog(context, controller, existing: status);
            } else if (value == 'delete') {
              _showDeleteDialog(context, controller, status);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FORM DIALOG (Add / Edit)
  // ───────────────────────────────────────────────────────────────────────────
  void _showFormDialog(
    BuildContext context,
    EmployeeStatusController controller, {
    Map<String, dynamic>? existing,
  }) {
    final isEdit = existing != null;

    final codeCtrl = TextEditingController(text: existing?['code'] ?? '');
    final labelCtrl = TextEditingController(text: existing?['label'] ?? '');
    final sortCtrl = TextEditingController(
      text: (existing?['sort_order'] ?? 0).toString(),
    );

    var selectedColor = (existing?['color'] ?? 'gray') as String;
    var isActive = existing?['is_active'] != false;
    var isVisible = existing?['is_visible'] != false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEdit ? 'Edit Status Karyawan' : 'Tambah Status Karyawan',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Code
                _inputField(
                  controller: codeCtrl,
                  label: 'Kode',
                  hint: 'cth: active, probation',
                  enabled: !isEdit, // code tidak bisa diubah setelah dibuat
                ),
                const SizedBox(height: 12),
                // Label
                _inputField(
                  controller: labelCtrl,
                  label: 'Label',
                  hint: 'cth: Aktif, Masa Percobaan',
                ),
                const SizedBox(height: 12),
                // Sort order
                _inputField(
                  controller: sortCtrl,
                  label: 'Urutan Tampil',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Color picker
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Warna Badge',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EmployeeStatusController.availableColors.map((c) {
                    final col = EmployeeStatusController.colorFromString(c);
                    final sel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: col.withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: sel
                              ? Border.all(color: Colors.black54, width: 2.5)
                              : null,
                        ),
                        child: sel
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Toggles
                SwitchListTile(
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                  title: const Text(
                    'Boleh Absen & Cuti',
                    style: TextStyle(fontSize: 14),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: Colors.green,
                ),
                SwitchListTile(
                  value: isVisible,
                  onChanged: (v) => setState(() => isVisible = v),
                  title: const Text(
                    'Tampil di Dropdown',
                    style: TextStyle(fontSize: 14),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        final code = codeCtrl.text.trim();
                        final label = labelCtrl.text.trim();
                        final sort = int.tryParse(sortCtrl.text.trim()) ?? 0;

                        if (code.isEmpty || label.isEmpty) {
                          Get.snackbar(
                            'Perhatian',
                            'Kode dan Label wajib diisi.',
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        Get.back(); // ← tutup dialog DULU sebelum await

                        if (isEdit) {
                          await controller.updateStatus(
                            id: existing!['id'],
                            code: code,
                            label: label,
                            color: selectedColor,
                            isActive: isActive,
                            isVisible: isVisible,
                            sortOrder: sort,
                          );
                        } else {
                          await controller.createStatus(
                            code: code,
                            label: label,
                            color: selectedColor,
                            isActive: isActive,
                            isVisible: isVisible,
                            sortOrder: sort,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEdit ? 'Simpan' : 'Tambah'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DELETE DIALOG
  // ───────────────────────────────────────────────────────────────────────────
  void _showDeleteDialog(
    BuildContext context,
    EmployeeStatusController controller,
    Map<String, dynamic> status,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hapus Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            children: [
              const TextSpan(text: 'Yakin ingin menghapus status '),
              TextSpan(
                text: status['label'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text:
                    '?\n\nStatus yang masih dipakai karyawan tidak bisa dihapus.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deleteStatus(status['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPER WIDGET
  // ───────────────────────────────────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
