import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/pusat_lokasi_controller.dart';
import '../../../../models/pusat_lokasi_model.dart';
import '../../../../controllers/app_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class PusatLokasiAssignController extends GetxController {
  final PusatLokasiModel lokasi;
  final PusatLokasiController pusatLokasiCtrl;

  PusatLokasiAssignController({
    required this.lokasi,
    required this.pusatLokasiCtrl,
  });

  final _auth = Get.find<AuthController>();

  var isLoadingEmployees = false.obs;
  var isSaving = false.obs;
  var activeTab = 0.obs;

  var allEmployees = <Map<String, dynamic>>[].obs;
  final selectedIds = <int>{}.obs;

  var searchLeft = ''.obs;
  var searchRight = ''.obs;

  var radiusMeter = 100.obs;
  var overwrite = false.obs;

  // ← FIX: TextEditingController stabil, tidak dibuat ulang di Obx
  late final TextEditingController radiusTextCtrl;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    radiusTextCtrl = TextEditingController(text: radiusMeter.value.toString());
    _init();
  }

  @override
  void onClose() {
    radiusTextCtrl.dispose();
    super.onClose();
  }

  Future<void> _init() async {
    _baseUrl = await AppConfig.getBaseUrl();
    await Future.wait([_loadEmployees(), _loadAssignedEmployees()]);
  }

  Future<void> _loadAssignedEmployees() async {
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/admin/pusat-lokasi/${lokasi.id}'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${_auth.token.value}',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        final employees = json['data']?['employees'] as List?;
        if (employees != null) {
          for (final emp in employees) {
            selectedIds.add(emp['id'] as int);
          }
          debugPrint('Pre-loaded ${selectedIds.length} assigned employees');
        }
      }
    } catch (e) {
      debugPrint('_loadAssignedEmployees error: $e');
    }
  }

  Future<void> _loadEmployees() async {
    isLoadingEmployees.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/admin/employees-dropdown');

      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${_auth.token.value}',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        final raw = json['data'];
        if (raw is List) {
          allEmployees.value = List<Map<String, dynamic>>.from(raw);
        }
      } else {
        _showError('Gagal memuat karyawan: ${res.statusCode}');
      }
    } catch (e) {
      _showError('Koneksi error: $e');
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  // ── Filtered lists ────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get filteredLeft {
    var list = allEmployees
        .where((e) => !selectedIds.contains(e['id'] as int))
        .toList();

    final q = searchLeft.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) {
        final name = (e['full_name'] ?? '').toString().toLowerCase();
        final code = (e['employee_code'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    }
    return list;
  }

  List<Map<String, dynamic>> get filteredRight {
    var list = allEmployees
        .where((e) => selectedIds.contains(e['id'] as int))
        .toList();

    final q = searchRight.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) {
        final name = (e['full_name'] ?? '').toString().toLowerCase();
        final code = (e['employee_code'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    }
    return list;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void addEmployee(int id) => selectedIds.add(id);
  void removeEmployee(int id) => selectedIds.remove(id);

  void addAll() => selectedIds.addAll(filteredLeft.map((e) => e['id'] as int));
  void removeAll() =>
      selectedIds.removeAll(filteredRight.map((e) => e['id'] as int));

  Future<bool> save() async {
    if (selectedIds.isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Pilih minimal 1 karyawan',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    isSaving.value = true;
    try {
      final res = await http
          .post(
            Uri.parse(
              '$_baseUrl/admin/pusat-lokasi/${lokasi.id}/bulk-assign-employees',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_auth.token.value}',
            },
            body: jsonEncode({
              'employee_ids': selectedIds.toList(),
              'radius_meter': radiusMeter.value,
              'overwrite': overwrite.value,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));

      if (res.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          data['message'] ?? 'Karyawan berhasil di-assign',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        pusatLokasiCtrl.fetchPusatLokasi();
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
    snackPosition: SnackPosition.TOP,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class BulkAssignKaryawanModal extends StatefulWidget {
  final PusatLokasiModel lokasi;
  final PusatLokasiController pusatLokasiCtrl;

  const BulkAssignKaryawanModal({
    super.key,
    required this.lokasi,
    required this.pusatLokasiCtrl,
  });

  static void show(
    BuildContext context,
    PusatLokasiController controller,
    PusatLokasiModel lokasi,
  ) {
    showDialog(
      context: context,
      builder: (_) =>
          BulkAssignKaryawanModal(lokasi: lokasi, pusatLokasiCtrl: controller),
    );
  }

  @override
  State<BulkAssignKaryawanModal> createState() =>
      _BulkAssignKaryawanModalState();
}

class _BulkAssignKaryawanModalState extends State<BulkAssignKaryawanModal> {
  static const _blue = Color(0xFF1565C0);
  static const _blueLight = Color(0xFFE3F0FF);
  static const _green = Color(0xFF2E7D32);

  late final PusatLokasiAssignController ctrl;
  late final String tag;

  // ✅ TextEditingController stabil di State — tidak pernah rebuild
  final _leftSearchCtrl = TextEditingController();
  final _rightSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    tag = 'assign_lokasi_${widget.lokasi.id}';

    if (Get.isRegistered<PusatLokasiAssignController>(tag: tag)) {
      Get.delete<PusatLokasiAssignController>(tag: tag);
    }

    ctrl = Get.put(
      PusatLokasiAssignController(
        lokasi: widget.lokasi,
        pusatLokasiCtrl: widget.pusatLokasiCtrl,
      ),
      tag: tag,
    );
  }

  @override
  void dispose() {
    _leftSearchCtrl.dispose();
    _rightSearchCtrl.dispose();
    Get.delete<PusatLokasiAssignController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: Column(
          children: [
            _buildHeader(context),
            _buildConfigPanel(),
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
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assign Karyawan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  widget.lokasi.namaLokasi,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _blue,
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

  // ── Config Panel ──────────────────────────────────────────────────────────

  Widget _buildConfigPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.radar_rounded,
                  size: 18,
                  color: Colors.blue.shade400,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Radius (meter)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 90,
                  height: 36,
                  child: TextField(
                    controller: ctrl.radiusTextCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (v) =>
                        ctrl.radiusMeter.value = int.tryParse(v) ?? 100,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade400),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() {
              final isOverwrite = ctrl.overwrite.value;
              return GestureDetector(
                onTap: () => ctrl.overwrite.value = !isOverwrite,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isOverwrite ? Colors.orange.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOverwrite
                          ? Colors.orange.shade300
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: isOverwrite
                            ? Colors.orange
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timpa assign lama',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isOverwrite
                                    ? Colors.orange.shade800
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              isOverwrite
                                  ? 'Semua assign lama lokasi ini akan dihapus'
                                  : 'Karyawan yang sudah di-assign akan dilewati',
                              style: TextStyle(
                                fontSize: 11,
                                color: isOverwrite
                                    ? Colors.orange.shade700
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isOverwrite,
                        onChanged: (v) => ctrl.overwrite.value = v,
                        activeColor: Colors.orange,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Obx(
        () => Container(
          decoration: BoxDecoration(
            color: _blueLight,
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
        ),
      ),
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
                  color: isActive ? _blue : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? _blue : Colors.grey.shade300,
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

  // ── Body — IndexedStack agar TextField tidak pernah dispose ───────────────

  Widget _buildBody() {
    return Obx(() {
      if (ctrl.isLoadingEmployees.value) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blue.shade700),
              const SizedBox(height: 14),
              Text(
                'Memuat data karyawan...',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        );
      }
      // ✅ IndexedStack — kedua panel tetap hidup, TextField tidak pernah rebuild
      return IndexedStack(
        index: ctrl.activeTab.value,
        children: [_buildLeftPanel(), _buildRightPanel()],
      );
    });
  }

  // ── Panel Kiri ────────────────────────────────────────────────────────────

  Widget _buildLeftPanel() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          // ✅ Pakai _leftSearchCtrl dari State — stabil selamanya
          child: _searchField(
            hint: 'Cari nama atau kode karyawan...',
            textCtrl: _leftSearchCtrl,
            onChanged: (v) => ctrl.searchLeft.value = v,
          ),
        ),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Text(
                  '${ctrl.filteredLeft.length} karyawan tersedia',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                      color: _blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final list = ctrl.filteredLeft;
            if (list.isEmpty) {
              return _emptyState(
                icon: Icons.people_outline,
                message: ctrl.searchLeft.value.isNotEmpty
                    ? 'Tidak ada hasil pencarian'
                    : 'Semua karyawan sudah dipilih',
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
                    color: _blueLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 15, color: _blue),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          // ✅ Pakai _rightSearchCtrl dari State — stabil selamanya
          child: _searchField(
            hint: 'Cari dari yang sudah dipilih...',
            textCtrl: _rightSearchCtrl,
            onChanged: (v) => ctrl.searchRight.value = v,
          ),
        ),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Text(
                  '${ctrl.selectedIds.length} karyawan dipilih',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
        ),
        Expanded(
          child: Obx(() {
            final list = ctrl.filteredRight;
            if (list.isEmpty) {
              return _emptyState(
                icon: Icons.person_add_alt_outlined,
                message:
                    'Belum ada karyawan dipilih.\nBuka tab "Dapat Dipilih" untuk menambahkan.',
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
                bgColor: const Color(0xFFF8FBFF),
                leftAccent: _blue,
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
                    color: _blue,
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
                backgroundColor: _green,
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
    required TextEditingController textCtrl, // ✅ wajib pakai controller
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: textCtrl,
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
          borderSide: BorderSide(color: _blue),
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
        splashColor: _blueLight,
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
                backgroundColor: _blueLight,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _blue,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: _blueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: _blue.withOpacity(0.4)),
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
      ),
    );
  }
}
