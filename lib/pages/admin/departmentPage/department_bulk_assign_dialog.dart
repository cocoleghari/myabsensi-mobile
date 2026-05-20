import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../controllers/auth_controller.dart';
import '../../../controllers/app_config.dart';
import '../../../controllers/department_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class DepartmentBulkAssignController extends GetxController {
  final int departmentId;
  final String departmentName;
  final DepartmentController deptCtrl = Get.find<DepartmentController>();

  DepartmentBulkAssignController({
    required this.departmentId,
    required this.departmentName,
  });

  final authController = Get.find<AuthController>();

  var isLoadingEmployees = false.obs;
  var isSaving = false.obs;
  var activeTab = 0.obs;

  var allEmployees = <Map<String, dynamic>>[].obs;
  final selectedIds = <int>{}.obs;

  var searchLeft = ''.obs;
  var searchRight = ''.obs;
  var jabatanFilter = ''.obs;
  var jabatanList = <String>[].obs;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _baseUrl = await AppConfig.getBaseUrl();
    await _loadEmployees();
  }

  /// Reset semua state pencarian & pilihan, lalu muat ulang data.
  /// Dipanggil setiap kali dialog dibuka agar data selalu fresh.
  Future<void> resetAndReload() async {
    // FIX BUG 2: reset search & selection sebelum load ulang
    searchLeft.value = '';
    searchRight.value = '';
    selectedIds.clear();
    activeTab.value = 0;
    await _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    isLoadingEmployees.value = true;
    try {
      // Selalu fetch ulang agar data department_id karyawan up-to-date
      await deptCtrl.fetchEmployeesDropdown();
      _applyEmployees(deptCtrl.employeesDropdown.toList());
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  void _applyEmployees(List<Map<String, dynamic>> list) {
    allEmployees.value = list;

    // Karyawan yang sudah di department ini → masuk selectedIds
    for (final emp in list) {
      if (emp['department_id'] == departmentId) {
        selectedIds.add(emp['id'] as int);
      }
    }

    jabatanList.value = [];
  }

  // ── Filtered lists ────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get filteredLeft {
    var result = allEmployees
        .where((e) => !selectedIds.contains(e['id'] as int))
        .toList();

    final q = searchLeft.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((e) {
        final name = (e['full_name'] ?? '').toString().toLowerCase();
        final code = (e['employee_code'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    }

    return result;
  }

  List<Map<String, dynamic>> get filteredRight {
    var result = allEmployees
        .where((e) => selectedIds.contains(e['id'] as int))
        .toList();

    final q = searchRight.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((e) {
        final name = (e['full_name'] ?? '').toString().toLowerCase();
        final code = (e['employee_code'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    }

    return result;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void addEmployee(int id) => selectedIds.add(id);
  void removeEmployee(int id) => selectedIds.remove(id);

  void addAll() => selectedIds.addAll(filteredLeft.map((e) => e['id'] as int));
  void removeAll() =>
      selectedIds.removeAll(filteredRight.map((e) => e['id'] as int));

  Future<bool> save() async {
    isSaving.value = true;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/departments/$departmentId/bulk-assign'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'employee_ids': selectedIds.toList()}),
          )
          .timeout(const Duration(seconds: 30));

      final bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
      final data = jsonDecode(bodyString);
      if (response.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          data['message'] ??
              '${selectedIds.length} karyawan berhasil ditetapkan',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return true;
      } else {
        _showError(data['message'] ?? 'Gagal menyimpan');
        return false;
      }
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void _showError(String msg) => Get.snackbar(
    'Error',
    msg,
    backgroundColor: Colors.red,
    colorText: Colors.white,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class DepartmentBulkAssignDialog extends StatefulWidget {
  final int departmentId;
  final String departmentName;
  final VoidCallback? onSaved;

  const DepartmentBulkAssignDialog({
    super.key,
    required this.departmentId,
    required this.departmentName,
    this.onSaved,
  });

  @override
  State<DepartmentBulkAssignDialog> createState() =>
      _DepartmentBulkAssignDialogState();
}

class _DepartmentBulkAssignDialogState
    extends State<DepartmentBulkAssignDialog> {
  static const _purple = Color(0xFF6C3DF4);
  static const _orange = Color(0xFFFF5C1A);

  // FIX BUG 2: search controller dikelola di sini agar bisa di-clear
  final _searchLeftCtrl = TextEditingController();
  final _searchRightCtrl = TextEditingController();

  late final DepartmentBulkAssignController ctrl;

  @override
  void initState() {
    super.initState();

    // Hapus controller lama (jika ada) agar state tidak tersisa dari sesi sebelumnya
    if (Get.isRegistered<DepartmentBulkAssignController>(
      tag: 'bulk_${widget.departmentId}',
    )) {
      Get.delete<DepartmentBulkAssignController>(
        tag: 'bulk_${widget.departmentId}',
      );
    }

    ctrl = Get.put(
      DepartmentBulkAssignController(
        departmentId: widget.departmentId,
        departmentName: widget.departmentName,
      ),
      tag: 'bulk_${widget.departmentId}',
    );
  }

  @override
  void dispose() {
    _searchLeftCtrl.dispose();
    _searchRightCtrl.dispose();
    // Hapus controller saat dialog ditutup
    Get.delete<DepartmentBulkAssignController>(
      tag: 'bulk_${widget.departmentId}',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F4FA),
        // FIX BUG 1: resizeToAvoidBottomInset = false mencegah layout
        // berubah saat keyboard muncul sehingga tidak terjadi overflow
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(child: _buildBody()),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 16,
        right: 4,
        bottom: 12,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.group_add_outlined,
              color: _purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Atur Karyawan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  widget.departmentName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _purple,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Obx(() {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0EBFF),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _tabItem(
                label: 'Dapat Dipilih',
                count: ctrl.filteredLeft.length,
                isActive: ctrl.activeTab.value == 0,
                onTap: () => ctrl.activeTab.value = 0,
              ),
              _tabItem(
                label: 'Terpilih',
                count: ctrl.selectedIds.length,
                isActive: ctrl.activeTab.value == 1,
                onTap: () => ctrl.activeTab.value = 1,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _tabItem({
    required String label,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? _purple : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? _purple : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Obx(() {
      if (ctrl.isLoadingEmployees.value) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _purple),
              const SizedBox(height: 14),
              Text(
                'Memuat data karyawan...',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        );
      }
      return ctrl.activeTab.value == 0 ? _buildLeftPanel() : _buildRightPanel();
    });
  }

  // ── Panel Kiri ────────────────────────────────────────────────────────────

  Widget _buildLeftPanel() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _searchField(
            hint: 'Cari nama atau kode karyawan...',
            controller: _searchLeftCtrl,
            onChanged: (v) => ctrl.searchLeft.value = v,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Obx(
                () => Text(
                  '${ctrl.filteredLeft.length} karyawan tersedia',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ctrl.addAll();
                  ctrl.activeTab.value = 1;
                },
                child: const Text(
                  'Pilih Semua →',
                  style: TextStyle(
                    fontSize: 12,
                    color: _purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final list = ctrl.filteredLeft;
            if (list.isEmpty) {
              // FIX BUG 1: bungkus dengan SingleChildScrollView agar tidak
              // overflow saat keyboard muncul dan ruang mengecil
              return SingleChildScrollView(
                child: _emptyState(
                  icon: Icons.people_outline,
                  message: ctrl.searchLeft.value.isNotEmpty
                      ? 'Tidak ada hasil pencarian'
                      : 'Semua karyawan sudah dipilih',
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(top: 6, bottom: 12),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, indent: 68, color: Colors.grey.shade100),
              itemBuilder: (_, i) => _employeeTile(
                employee: list[i],
                trailing: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE9FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 15, color: _purple),
                ),
                onTap: () => ctrl.addEmployee(list[i]['id'] as int),
                bgColor: Colors.white,
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Panel Kanan ───────────────────────────────────────────────────────────

  Widget _buildRightPanel() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _searchField(
            hint: 'Cari dari yang sudah dipilih...',
            controller: _searchRightCtrl,
            onChanged: (v) => ctrl.searchRight.value = v,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Obx(
                () => Text(
                  '${ctrl.selectedIds.length} karyawan dipilih',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: ctrl.removeAll,
                child: Text(
                  'Hapus Semua',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final list = ctrl.filteredRight;
            if (list.isEmpty) {
              // FIX BUG 1: sama, bungkus dengan SingleChildScrollView
              return SingleChildScrollView(
                child: _emptyState(
                  icon: Icons.person_add_alt_outlined,
                  message:
                      'Belum ada karyawan dipilih.\nBuka tab "Dapat Dipilih" untuk menambahkan.',
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(top: 6, bottom: 12),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, indent: 68, color: Colors.grey.shade100),
              itemBuilder: (_, i) => _employeeTile(
                employee: list[i],
                trailing: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 15,
                    color: Colors.red.shade400,
                  ),
                ),
                onTap: () => ctrl.removeEmployee(list[i]['id'] as int),
                bgColor: const Color(0xFFFDFBFF),
                leftAccent: _purple,
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${ctrl.selectedIds.length} dipilih',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _purple,
                  ),
                ),
                Text(
                  'dari ${ctrl.allEmployees.length} karyawan',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 6),
          Obx(
            () => ElevatedButton.icon(
              onPressed: ctrl.isSaving.value
                  ? null
                  : () async {
                      final ok = await ctrl.save();
                      if (ok && context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                        widget.onSaved?.call();
                      }
                    },
              icon: ctrl.isSaving.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(
                ctrl.isSaving.value ? 'Menyimpan...' : 'Simpan',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────────────

  Widget _searchField({
    required String hint,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: _purple),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        isDense: true,
      ),
    );
  }

  Widget _employeeTile({
    required Map<String, dynamic> employee,
    required Widget trailing,
    required VoidCallback onTap,
    required Color bgColor,
    Color? leftAccent,
  }) {
    final name = employee['full_name']?.toString() ?? '-';
    final code = employee['employee_code']?.toString() ?? '';
    final photoUrl = employee['photo_url']?.toString();
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFFEDE9FF),
        child: Container(
          decoration: leftAccent != null
              ? BoxDecoration(
                  border: Border(left: BorderSide(color: leftAccent, width: 3)),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEDE9FF),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _purple,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (code.isNotEmpty)
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: _purple.withOpacity(0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
