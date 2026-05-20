import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/pages/admin/master_drawer.dart';
import '../../../controllers/company_controller.dart';
import 'company_form_dialog.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key});

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  late final CompanyController ctrl;

  @override
  void initState() {
    super.initState();
    // ✅ Get.put hanya dipanggil sekali di initState, bukan di build()
    ctrl = Get.find<CompanyController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Companies',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.fetchCompanies,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const MasterDrawer(currentPage: 'companies'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const CompanyFormDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          _buildSearchFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: ctrl.setSearch,
              decoration: InputDecoration(
                hintText: 'Cari nama / kode / kota...',
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
                      ? Colors.teal.shade50
                      : Colors.grey.shade50,
                  border: Border.all(
                    color: active != null
                        ? Colors.teal.shade200
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
                          ? Colors.teal
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
                            ? Colors.teal
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

  Widget _buildList() {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (ctrl.filteredCompanies.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.business_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak ada company',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: ctrl.fetchCompanies,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: ctrl.filteredCompanies.length,
          itemBuilder: (_, i) => _buildCard(ctrl.filteredCompanies[i]),
        ),
      );
    });
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final isActive = c['is_active'] == true;
    final city = c['city']?.toString();
    final province = c['province']?.toString();
    final location = [
      city,
      province,
    ].where((s) => s != null && s.isNotEmpty).join(', ');
    final deptCount = c['departments_count'] ?? 0;
    final empCount = c['employees_count'] ?? 0;
    final industry = c['industry']?.toString();

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
            color: Colors.teal.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.business, color: Colors.teal.shade400, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                c['name'] ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (c['code'] != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c['code'],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
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
              if (industry != null && industry.isNotEmpty)
                _infoRow(Icons.category_outlined, industry),
              if (location.isNotEmpty)
                _infoRow(Icons.location_on_outlined, location),
              Row(
                children: [
                  _infoRowInline(
                    Icons.account_tree_outlined,
                    '$deptCount dept',
                  ),
                  const SizedBox(width: 16),
                  _infoRowInline(Icons.people_outline, '$empCount karyawan'),
                ],
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (action) {
            if (action == 'edit') {
              showDialog(
                context: context,
                builder: (_) => CompanyFormDialog(existing: c),
              );
            } else if (action == 'delete') {
              ctrl.deleteCompany(c['id'] as int, c['name'] ?? '');
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
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
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

  Widget _infoRowInline(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Colors.grey.shade500),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ],
  );
}
