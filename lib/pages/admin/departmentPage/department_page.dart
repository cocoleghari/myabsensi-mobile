import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/pages/admin/master_drawer.dart';
import '../../../controllers/department_controller.dart';
import 'package:myabsensi_mobile/pages/admin/departmentPage/department_bulk_assign_dialog.dart';
import 'department_form_dialog.dart';
import 'department_tree_dialog.dart';

class DepartmentPage extends StatefulWidget {
  const DepartmentPage({super.key});

  @override
  State<DepartmentPage> createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  late final DepartmentController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<DepartmentController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Department',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const DepartmentTreeDialog(),
            ),
            tooltip: 'Lihat Hierarki',
          ),
          // ── Tombol Export & Import ──────────────────────────────
          Obx(
            () => ctrl.isExporting.value
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
                        await ctrl.exportDepartments();
                      } else if (action == 'import') {
                        await ctrl.importDepartments();
                      } else if (action == 'template') {
                        await ctrl.downloadImportTemplate();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
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
                      const PopupMenuItem(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(
                              Icons.upload_outlined,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 8),
                            Text('Import dari Excel'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
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
          // ───────────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.fetchDepartments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const MasterDrawer(currentPage: 'department'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const DepartmentFormDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          _buildSearchFilter(ctrl),
          Expanded(child: _buildList(ctrl)),
        ],
      ),
    );
  }

  // ─── Search + Filter bar ───────────────────────────────────

  Widget _buildSearchFilter(DepartmentController ctrl) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: ctrl.setSearch,
              decoration: InputDecoration(
                hintText: 'Cari nama / kode...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final active = ctrl.filterIsActive.value;
            return PopupMenuButton<bool?>(
              initialValue: active,
              onSelected: ctrl.setFilterActive,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active != null
                      ? Colors.deepPurple.shade50
                      : Colors.grey.shade50,
                  border: Border.all(
                    color: active != null
                        ? Colors.deepPurple.shade200
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 18,
                      color: active != null
                          ? Colors.deepPurple
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      active == null
                          ? 'Semua'
                          : active
                          ? 'Aktif'
                          : 'Nonaktif',
                      style: TextStyle(
                        fontSize: 13,
                        color: active != null
                            ? Colors.deepPurple
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('Semua')),
                const PopupMenuItem(value: true, child: Text('Aktif')),
                const PopupMenuItem(value: false, child: Text('Nonaktif')),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── List ──────────────────────────────────────────────────

  Widget _buildList(DepartmentController ctrl) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (ctrl.filteredDepartments.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak ada department',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: ctrl.fetchDepartments,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: ctrl.filteredDepartments.length,
          itemBuilder: (ctx, i) =>
              _buildCard(ctrl.filteredDepartments[i], ctrl, ctx),
        ),
      );
    });
  }

  Widget _buildCard(
    Map<String, dynamic> dept,
    DepartmentController ctrl,
    BuildContext context,
  ) {
    final isActive = dept['is_active'] == true;
    final parentName = dept['parent']?['name']?.toString();
    final grandParentName = dept['parent']?['parent']?['name']?.toString();
    final managerName = dept['manager']?['full_name']?.toString();
    final company = dept['company']?['name']?.toString() ?? '-';
    final empCount = dept['employees_count'] ?? 0;

    String breadcrumb = dept['name'] ?? '-';
    if (parentName != null) {
      breadcrumb = grandParentName != null
          ? '$grandParentName > $parentName > ${dept['name']}'
          : '$parentName > ${dept['name']}';
    }

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
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_tree,
            color: Colors.deepPurple.shade400,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                dept['name'] ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (dept['code'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dept['code'],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.deepPurple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(Icons.business, company),
              if (parentName != null)
                _infoRow(
                  Icons.subdirectory_arrow_right,
                  'Sub dari: $parentName',
                ),
              if (managerName != null)
                _infoRow(Icons.person_outline, 'Manajer: $managerName'),
              _infoRow(Icons.people_outline, '$empCount karyawan'),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (action) {
            // Di popup menu card (edit):
            if (action == 'edit') {
              showDialog(
                context: context,
                builder: (_) => DepartmentFormDialog(existing: dept),
              );
            } else if (action == 'delete') {
              ctrl.deleteDepartment(dept['id'] as int, dept['name'] ?? '');
            } else if (action == 'assign') {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => DepartmentBulkAssignDialog(
                  departmentId: dept['id'] as int,
                  departmentName: dept['name'] ?? '',
                  onSaved: ctrl.fetchDepartments,
                ),
              );
            } else if (action == 'tree') {
              showDialog(
                context: context,
                builder: (_) => const DepartmentTreeDialog(),
              );
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'assign',
              child: Row(
                children: [
                  Icon(
                    Icons.group_add_outlined,
                    size: 18,
                    color: Colors.deepPurple,
                  ),
                  SizedBox(width: 8),
                  Text('Atur Karyawan'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'tree',
              child: Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 18,
                    color: Colors.teal,
                  ),
                  SizedBox(width: 8),
                  Text('Lihat Hierarki'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
