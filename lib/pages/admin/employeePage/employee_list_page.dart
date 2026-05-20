import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/pages/admin/employeePage/employee_import_export_sheet.dart';
import '../../../controllers/employee_controller.dart';
import '../../../models/employee_model.dart';
import 'employee_form_page.dart';
import 'employee_detail_page.dart';
import '../master_drawer.dart';
import 'dart:async'; // tambah import

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  late final EmployeeController _ctrl;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce; // ← tambah

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<EmployeeController>();

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        _ctrl.loadMore();
      }
    });

    // Fetch setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.fetchOptions();
      _ctrl.fetchEmployees(reset: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // ← tambah
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _openForm({EmployeeModel? employee}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EmployeeFormPage(employee: employee)),
    );
    if (result == true) _ctrl.fetchEmployees(reset: true);
  }

  void _confirmDelete(EmployeeModel emp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Karyawan?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Data "${emp.displayName}" akan dihapus. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _ctrl.deleteEmployee(emp.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Karyawan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            tooltip: 'Export / Import',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => EmployeeImportExportSheet(employeeCtrl: _ctrl),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      drawer: const MasterDrawer(currentPage: 'employee'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Karyawan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Cari nama, NIK, atau kode karyawan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(
            () => _ctrl.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      _ctrl.applySearch('');
                    },
                  )
                : const SizedBox.shrink(),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (v) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            _ctrl.applySearch(v);
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Obx(() {
      final hasFilter =
          _ctrl.filterCompanyId.value != null ||
          _ctrl.filterDepartmentId.value != null ||
          _ctrl.filterJobLevelId.value != null ||
          _ctrl.filterJobGradeId.value != null ||
          _ctrl.filterEmploymentType.value != null;

      if (!hasFilter) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Text(
              'Filter aktif:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            Chip(
              label: const Text('Hapus semua'),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: _ctrl.clearFilters,
              backgroundColor: Colors.blue.shade50,
              labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 12),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildList() {
    return Obx(() {
      if (_ctrl.isLoading.value && _ctrl.employees.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_ctrl.employees.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Belum ada karyawan',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              if (_ctrl.searchQuery.isNotEmpty ||
                  _ctrl.filterCompanyId.value != null)
                TextButton(
                  onPressed: _ctrl.clearFilters,
                  child: const Text('Hapus filter'),
                ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Obx(
                () => Text(
                  '${_ctrl.total.value} karyawan',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount:
                  _ctrl.employees.length +
                  (_ctrl.currentPage.value < _ctrl.lastPage.value ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (i >= _ctrl.employees.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _buildCard(_ctrl.employees[i]);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCard(EmployeeModel emp) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => EmployeeDetailPage(employeeId: emp.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: emp.photoUrl != null
                    ? NetworkImage(emp.photoUrl!)
                    : null,
                child: emp.photoUrl == null
                    ? Text(
                        emp.fullName.isNotEmpty
                            ? emp.fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (emp.employeeCode != null)
                      Text(
                        emp.employeeCode!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (emp.departmentName != null)
                          Flexible(
                            // ← tambah Flexible
                            child: _chip(emp.departmentName!, Colors.purple),
                          ),
                        if (emp.positionName != null) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            // ← tambah Flexible
                            child: _chip(emp.positionName!, Colors.teal),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) {
                  if (v == 'edit') _openForm(employee: emp);
                  if (v == 'delete') _confirmDelete(emp);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
        overflow: TextOverflow.ellipsis, // ← tambah ini
        maxLines: 1,
      ),
    );
  }

  void _showFilterSheet() {
    int? tmpCompany = _ctrl.filterCompanyId.value;
    int? tmpDept = _ctrl.filterDepartmentId.value;
    int? tmpJobLevel = _ctrl.filterJobLevelId.value;
    int? tmpJobGrade = _ctrl.filterJobGradeId.value;
    String? tmpType = _ctrl.filterEmploymentType.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filter Karyawan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Company filter
              Obx(
                () => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Perusahaan',
                    border: OutlineInputBorder(),
                  ),
                  value: tmpCompany,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua perusahaan'),
                    ),
                    ..._ctrl.companies.map(
                      (c) => DropdownMenuItem(
                        value: c['id'],
                        child: Text(c['name']),
                      ),
                    ),
                  ],
                  onChanged: (v) => setLocal(() => tmpCompany = v),
                ),
              ),
              const SizedBox(height: 12),

              // Department filter
              Obx(
                () => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Departemen',
                    border: OutlineInputBorder(),
                  ),
                  value: tmpDept,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua departemen'),
                    ),
                    ..._ctrl.departments.map(
                      (d) => DropdownMenuItem(
                        value: d['id'],
                        child: Text(d['name']),
                      ),
                    ),
                  ],
                  onChanged: (v) => setLocal(() => tmpDept = v),
                ),
              ),
              const SizedBox(height: 12),

              // Job Level filter
              Obx(
                () => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Job Level',
                    border: OutlineInputBorder(),
                  ),
                  value: tmpJobLevel,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua job level'),
                    ),
                    ..._ctrl.jobLevels.map(
                      (l) => DropdownMenuItem(
                        value: l['id'],
                        child: Text(l['name']),
                      ),
                    ),
                  ],
                  onChanged: (v) => setLocal(() => tmpJobLevel = v),
                ),
              ),
              const SizedBox(height: 12),

              // Job Grade filter
              Obx(
                () => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Job Grade',
                    border: OutlineInputBorder(),
                  ),
                  value: tmpJobGrade,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua job grade'),
                    ),
                    ..._ctrl.jobGrades.map((g) {
                      final name = g['name']?.toString() ?? '';
                      final code = g['code']?.toString() ?? '';
                      final label = code.isNotEmpty ? '$name ($code)' : name;
                      return DropdownMenuItem(
                        value: g['id'],
                        child: Text(label),
                      );
                    }),
                  ],
                  onChanged: (v) => setLocal(() => tmpJobGrade = v),
                ),
              ),
              const SizedBox(height: 12),

              // Employment type filter
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipe Kepegawaian',
                  border: OutlineInputBorder(),
                ),
                value: tmpType,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua tipe')),
                  DropdownMenuItem(value: 'permanent', child: Text('Tetap')),
                  DropdownMenuItem(value: 'contract', child: Text('Kontrak')),
                  DropdownMenuItem(value: 'intern', child: Text('Magang')),
                ],
                onChanged: (v) => setLocal(() => tmpType = v),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _ctrl.clearFilters();
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _ctrl.applyFilter(
                          companyId: tmpCompany,
                          departmentId: tmpDept,
                          jobLevelId: tmpJobLevel,
                          jobGradeId: tmpJobGrade,
                          employmentType: tmpType,
                        );
                      },
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
