import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/shift_controller.dart';
import '../master_drawer.dart';
import 'shift_shared_widgets.dart';
import 'bulk_assign_shift_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ASSIGN KARYAWAN PAGE
// ─────────────────────────────────────────────────────────────────────────────

class AssignKaryawanPage extends StatefulWidget {
  const AssignKaryawanPage({super.key});

  @override
  State<AssignKaryawanPage> createState() => _AssignKaryawanPageState();
}

class _AssignKaryawanPageState extends State<AssignKaryawanPage> {
  late ShiftController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ShiftController>();
    _ctrl.fetchEmployeeShifts();
    _ctrl.fetchShiftsDropdown();
    _ctrl.fetchPatternsDropdown();
    _ctrl.fetchEmployeesDropdown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: const MasterDrawer(currentPage: 'employee-shifts'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Assign Shift Karyawan',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: Column(
        children: [
          _SearchBar(ctrl: _ctrl),
          Expanded(child: _AssignList(ctrl: _ctrl)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'bulk',
        onPressed: () => Get.dialog(
          BulkAssignShiftDialog(ctrl: _ctrl),
          barrierDismissible: false,
        ),
        backgroundColor: const Color(0xFF311B92),
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: const Text(
          'Bulk Assign',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── SEARCH BAR ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ShiftController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari nama karyawan…',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (_) => ctrl.fetchEmployeeShifts(),
      ),
    );
  }
}

// ── ASSIGN LIST ───────────────────────────────────────────────────────────────

class _AssignList extends StatelessWidget {
  final ShiftController ctrl;
  const _AssignList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingEmployeeShifts.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (ctrl.employeeShifts.isEmpty) {
        return buildEmpty(
          'Belum ada assignment shift',
          Icons.people_alt_outlined,
        );
      }
      return RefreshIndicator(
        onRefresh: ctrl.fetchEmployeeShifts,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: ctrl.employeeShifts.length,
          itemBuilder: (_, i) =>
              _AssignCard(item: ctrl.employeeShifts[i], ctrl: ctrl),
        ),
      );
    });
  }
}

// ── ASSIGN CARD ───────────────────────────────────────────────────────────────

class _AssignCard extends StatelessWidget {
  final EmployeeShiftModel item;
  final ShiftController ctrl;
  const _AssignCard({required this.item, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isAktif =
        item.tanggalSelesai == null ||
        DateTime.tryParse(
              item.tanggalSelesai ?? '',
            )?.isAfter(DateTime.now().subtract(const Duration(days: 1))) ==
            true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFEDE7F6),
              child: Text(
                (item.employeeName?.isNotEmpty == true)
                    ? item.employeeName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF5E35B1),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.employeeName ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    item.employeeCode ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        item.shiftNama != null
                            ? Icons.schedule
                            : Icons.calendar_view_week,
                        size: 13,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.shiftNama ?? item.shiftKode ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.shiftJamMasuk != null) ...[
                        Text(
                          '  ${item.shiftJamMasuk} – ${item.shiftJamPulang}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.tanggalMulai} '
                    '${item.tanggalSelesai != null ? '→ ${item.tanggalSelesai}' : '→ sekarang'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isAktif
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAktif ? 'Aktif' : 'Selesai',
                    style: TextStyle(
                      fontSize: 11,
                      color: isAktif
                          ? Colors.green.shade700
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ActionButtons(
                  onEdit: () => _showEditDialog(context, ctrl, item),
                  onDelete: () => showDeleteConfirm(
                    context,
                    title: 'Hapus Assignment',
                    message:
                        'Hapus assignment shift untuk "${item.employeeName}"?',
                    onConfirm: () async => ctrl.deleteEmployeeShift(item.id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT DIALOG — single assignment
// ─────────────────────────────────────────────────────────────────────────────

void _showEditDialog(
  BuildContext context,
  ShiftController ctrl,
  EmployeeShiftModel existing,
) {
  Get.dialog(
    _EditAssignDialog(ctrl: ctrl, existing: existing),
    barrierDismissible: false,
  );
}

class _EditAssignDialog extends StatefulWidget {
  final ShiftController ctrl;
  final EmployeeShiftModel existing;
  const _EditAssignDialog({required this.ctrl, required this.existing});

  @override
  State<_EditAssignDialog> createState() => _EditAssignDialogState();
}

class _EditAssignDialogState extends State<_EditAssignDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _keterangan;
  int? _shiftId;
  int? _patternId;
  bool _usePattern = false;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  bool _loading = false;

  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _patterns = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _keterangan = TextEditingController(text: e.keterangan ?? '');
    _shiftId = (e.shiftId != null && e.shiftId! > 0) ? e.shiftId : null;
    _patternId = e.patternId;
    _usePattern = e.shiftId == null || e.shiftId == 0;
    _tanggalMulai = DateTime.tryParse(e.tanggalMulai);
    _tanggalSelesai = e.tanggalSelesai != null
        ? DateTime.tryParse(e.tanggalSelesai!)
        : null;
    _shifts = widget.ctrl.shiftsList.toList();
    _patterns = widget.ctrl.patternsList.toList();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    await Future.wait([
      widget.ctrl.fetchShiftsDropdown(),
      widget.ctrl.fetchPatternsDropdown(),
    ]);
    if (mounted) {
      setState(() {
        _shifts = widget.ctrl.shiftsList.toList();
        _patterns = widget.ctrl.patternsList.toList();
      });
    }
  }

  @override
  void dispose() {
    _keterangan.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_tanggalMulai ?? DateTime.now())
          : (_tanggalSelesai ?? _tanggalMulai ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _tanggalMulai = picked;
        else
          _tanggalSelesai = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_usePattern && _patternId == null) {
      Get.snackbar(
        'Error',
        'Pilih pola shift',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (!_usePattern && _shiftId == null) {
      Get.snackbar(
        'Error',
        'Pilih shift',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_tanggalMulai == null) {
      Get.snackbar(
        'Error',
        'Pilih tanggal mulai',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _loading = true);

    final payload = {
      if (_usePattern) 'pattern_id': _patternId else 'shift_id': _shiftId,
      'tanggal_mulai': _fmt(_tanggalMulai!),
      'tanggal_selesai': _tanggalSelesai != null
          ? _fmt(_tanggalSelesai!)
          : null,
      'keterangan': _keterangan.text.trim().isEmpty
          ? null
          : _keterangan.text.trim(),
    };

    final ok = await widget.ctrl.updateEmployeeShift(
      widget.existing.id,
      payload,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Get.back();
      await widget.ctrl.fetchEmployeeShifts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShiftDialogHeader(
                  icon: Icons.edit_calendar_outlined,
                  title: 'Edit Assignment',
                  color: const Color(0xFF5E35B1),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.existing.employeeName ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF5E35B1),
                  ),
                ),
                const SizedBox(height: 16),

                // Mode toggle
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _ModeTab(
                        label: 'Shift Langsung',
                        icon: Icons.schedule,
                        selected: !_usePattern,
                        onTap: () => setState(() => _usePattern = false),
                      ),
                      _ModeTab(
                        label: 'Pola Mingguan',
                        icon: Icons.calendar_view_week,
                        selected: _usePattern,
                        onTap: () => setState(() => _usePattern = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (!_usePattern)
                  buildDropdown<int>(
                    label: 'Shift',
                    value: _shifts.any((s) => s['id'] == _shiftId)
                        ? _shiftId
                        : null,
                    items: _shifts
                        .map(
                          (s) => DropdownMenuItem<int>(
                            value: s['id'] as int?,
                            child: Text(
                              '${s['nama']} (${s['jam_masuk']} - ${s['jam_pulang']})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _shiftId = v),
                  )
                else
                  buildDropdown<int>(
                    label: 'Pola Mingguan',
                    value: _patterns.any((p) => p['id'] == _patternId)
                        ? _patternId
                        : null,
                    items: _patterns
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p['id'] as int?,
                            child: Text('${p['nama']} (${p['kode']})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _patternId = v),
                  ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: buildDateTile(
                        label: 'Tanggal Mulai',
                        value: _tanggalMulai,
                        onTap: () => _pickDate(isStart: true),
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildDateTile(
                        label: 'Tanggal Selesai',
                        value: _tanggalSelesai,
                        onTap: () => _pickDate(isStart: false),
                        hint: 'Selamanya',
                      ),
                    ),
                  ],
                ),
                if (_tanggalSelesai != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() => _tanggalSelesai = null),
                    child: Text(
                      'Hapus tanggal selesai',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                buildTextField(
                  _keterangan,
                  'Keterangan (opsional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                ShiftDialogActions(
                  loading: _loading,
                  onCancel: () => Get.back(),
                  onSubmit: _submit,
                  submitLabel: 'Simpan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── MODE TAB ──────────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
