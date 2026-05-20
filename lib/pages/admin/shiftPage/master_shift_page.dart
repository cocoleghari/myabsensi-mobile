import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/shift_controller.dart';
import '../master_drawer.dart';
import 'shift_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MASTER SHIFT PAGE — halaman mandiri (bukan tab)
// ─────────────────────────────────────────────────────────────────────────────

class MasterShiftPage extends StatelessWidget {
  const MasterShiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ShiftController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: const MasterDrawer(currentPage: 'shifts'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Master Shift',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1A1A2E),
          ),
        ),
        // ── BARU ──────────────────────────────────────────────
        actions: [
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
                    icon: const Icon(
                      Icons.import_export,
                      color: Color(0xFF1A1A2E),
                    ),
                    tooltip: 'Export / Import',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (action) async {
                      if (action == 'export') {
                        await ctrl.exportShifts();
                      } else if (action == 'import') {
                        await ctrl.importShifts();
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
                              color: Color(0xFF0288D1),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A2E)),
            onPressed: ctrl.fetchShifts,
            tooltip: 'Refresh',
          ),
        ],
        // ─────────────────────────────────────────────────────
      ),
      body: Column(
        children: [
          _FilterBar(ctrl: ctrl),
          Expanded(child: _ShiftList(ctrl: ctrl)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showShiftFormDialog(context, ctrl),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Shift',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── FILTER BAR ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final ShiftController ctrl;
  const _FilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama / kode shift…',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) {
                ctrl.searchQuery.value = v;
                ctrl.fetchShifts();
              },
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => StatusFilterChip(
              value: ctrl.filterIsActive.value,
              onChanged: (v) {
                ctrl.filterIsActive.value = v;
                ctrl.fetchShifts();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── SHIFT LIST ────────────────────────────────────────────────────────────────

class _ShiftList extends StatelessWidget {
  final ShiftController ctrl;
  const _ShiftList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingShifts.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (ctrl.shifts.isEmpty) {
        return buildEmpty('Belum ada shift', Icons.schedule_outlined);
      }
      return RefreshIndicator(
        onRefresh: ctrl.fetchShifts,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: ctrl.shifts.length,
          itemBuilder: (_, i) => _ShiftCard(shift: ctrl.shifts[i], ctrl: ctrl),
        ),
      );
    });
  }
}

// ── SHIFT CARD ────────────────────────────────────────────────────────────────

class _ShiftCard extends StatelessWidget {
  final ShiftModel shift;
  final ShiftController ctrl;
  const _ShiftCard({required this.shift, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Color(0xFF0288D1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        '${shift.kode}  •  ${shift.companyName ?? '-'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(active: shift.isActive),
              ],
            ),
            const SizedBox(height: 12),
            // ── Row jam: gunakan Wrap agar tidak overflow ──
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                InfoChip(
                  icon: Icons.login,
                  label: 'Masuk',
                  value: shift.jamMasuk,
                  color: Colors.green,
                ),
                InfoChip(
                  icon: Icons.logout,
                  label: 'Pulang',
                  value: shift.jamPulang,
                  color: Colors.orange,
                ),
                if (shift.melewatiTengahMalam)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.nights_stay,
                          size: 12,
                          color: Color(0xFF5E35B1),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Malam',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5E35B1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 13,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Toleransi ${shift.toleransiTerlambatMenit} menit  •  '
                    'Window masuk ${shift.windowMasukAwalMenit} menit',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
                ActionButtons(
                  onEdit: () =>
                      _showShiftFormDialog(context, ctrl, existing: shift),
                  onDelete: () => showDeleteConfirm(
                    context,
                    title: 'Hapus Shift',
                    message:
                        'Hapus shift "${shift.nama}"? Shift yang masih digunakan tidak dapat dihapus.',
                    onConfirm: () async => ctrl.deleteShift(shift.id),
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
// DIALOG FORM SHIFT
// ─────────────────────────────────────────────────────────────────────────────

void _showShiftFormDialog(
  BuildContext context,
  ShiftController ctrl, {
  ShiftModel? existing,
}) {
  Get.dialog(
    _ShiftFormDialog(ctrl: ctrl, existing: existing),
    barrierDismissible: false,
  );
}

class _ShiftFormDialog extends StatefulWidget {
  final ShiftController ctrl;
  final ShiftModel? existing;
  const _ShiftFormDialog({required this.ctrl, this.existing});

  @override
  State<_ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends State<_ShiftFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nama, _kode, _keterangan, _toleransi, _window;
  String _jamMasuk = '08:00';
  String _jamPulang = '17:00';
  String _batasWaktuPulang = '23:00';
  bool _melewatiTengahMalam = false;
  bool _berlakuHariLibur = false;
  bool _berlakuAkhirPekan = false;
  bool _isActive = true;
  int? _companyId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nama = TextEditingController(text: e?.nama ?? '');
    _kode = TextEditingController(text: e?.kode ?? '');
    _keterangan = TextEditingController(text: e?.keterangan ?? '');
    _toleransi = TextEditingController(
      text: (e?.toleransiTerlambatMenit ?? 15).toString(),
    );
    _window = TextEditingController(
      text: (e?.windowMasukAwalMenit ?? 30).toString(),
    );
    _jamMasuk = _formatJamForDisplay(e?.jamMasuk ?? '08:00');
    _jamPulang = _formatJamForDisplay(e?.jamPulang ?? '17:00');
    _batasWaktuPulang = _formatJamForDisplay(e?.batasWaktuPulang ?? '23:00');
    _melewatiTengahMalam = e?.melewatiTengahMalam ?? false;
    _berlakuHariLibur = e?.berlakuHariLibur ?? false;
    _berlakuAkhirPekan = e?.berlakuAkhirPekan ?? false;
    _isActive = e?.isActive ?? true;
    _companyId = e?.companyId;
  }

  @override
  void dispose() {
    _nama.dispose();
    _kode.dispose();
    _keterangan.dispose();
    _toleransi.dispose();
    _window.dispose();
    super.dispose();
  }

  Future<void> _pickTime(String current, void Function(String) onPick) async {
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      onPick(
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_companyId == null) {
      Get.snackbar(
        'Error',
        'Pilih perusahaan terlebih dahulu',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    setState(() => _loading = true);

    final payload = {
      'company_id': _companyId,
      'nama': _nama.text.trim(),
      'kode': _kode.text.trim().toUpperCase(),
      'jam_masuk': _formatJamForApi(_jamMasuk),
      'jam_pulang': _formatJamForApi(_jamPulang),
      'toleransi_terlambat_menit': int.tryParse(_toleransi.text) ?? 15,
      'window_masuk_awal_menit': int.tryParse(_window.text) ?? 30,
      'melewati_tengah_malam': _melewatiTengahMalam,
      'batas_waktu_pulang': _formatJamForApi(_batasWaktuPulang),
      'berlaku_hari_libur': _berlakuHariLibur,
      'berlaku_akhir_pekan': _berlakuAkhirPekan,
      'keterangan': _keterangan.text.trim().isEmpty
          ? null
          : _keterangan.text.trim(),
      'is_active': _isActive,
    };

    bool ok;
    if (widget.existing != null) {
      ok = await widget.ctrl.updateShift(widget.existing!.id, payload);
    } else {
      ok = await widget.ctrl.createShift(payload);
    }
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Get.back();
      await widget.ctrl.fetchShifts();
      widget.ctrl.showSuccessSnackbar(
        widget.existing != null
            ? 'Shift berhasil diperbarui'
            : 'Shift berhasil dibuat',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    // Ambil companiesList sekali — tidak pakai Obx di StatefulWidget
    final companies = widget.ctrl.companiesList.toList();

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
                  icon: Icons.schedule,
                  title: isEdit ? 'Edit Shift' : 'Tambah Shift',
                  color: const Color(0xFF0288D1),
                ),
                const SizedBox(height: 16),

                buildDropdown<int>(
                  label: 'Perusahaan',
                  value: _companyId,
                  items: companies
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'] as int?,
                          child: Text(c['name'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _companyId = v),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: buildTextField(
                        _nama,
                        'Nama Shift',
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: buildTextField(
                        _kode,
                        'Kode',
                        required: true,
                        upperCase: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: buildTimeTile(
                        label: 'Jam Masuk',
                        value: _jamMasuk,
                        color: Colors.green,
                        onTap: () => _pickTime(
                          _jamMasuk,
                          (v) => setState(() => _jamMasuk = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildTimeTile(
                        label: 'Jam Pulang',
                        value: _jamPulang,
                        color: Colors.orange,
                        onTap: () => _pickTime(
                          _jamPulang,
                          (v) => setState(() => _jamPulang = v),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                buildTimeTile(
                  label: 'Batas Waktu Pulang (absen otomatis)',
                  value: _batasWaktuPulang,
                  color: Colors.red,
                  onTap: () => _pickTime(
                    _batasWaktuPulang,
                    (v) => setState(() => _batasWaktuPulang = v),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: buildTextField(
                        _toleransi,
                        'Toleransi Terlambat (menit)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildTextField(
                        _window,
                        'Window Masuk Awal (menit)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                buildSwitch(
                  'Melewati tengah malam',
                  _melewatiTengahMalam,
                  (v) => setState(() => _melewatiTengahMalam = v),
                ),
                buildSwitch(
                  'Berlaku hari libur',
                  _berlakuHariLibur,
                  (v) => setState(() => _berlakuHariLibur = v),
                ),
                buildSwitch(
                  'Berlaku akhir pekan',
                  _berlakuAkhirPekan,
                  (v) => setState(() => _berlakuAkhirPekan = v),
                ),
                buildSwitch(
                  'Aktif',
                  _isActive,
                  (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 8),

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
                  submitLabel: isEdit ? 'Simpan' : 'Buat Shift',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. Tambah helper method di _ShiftFormDialogState
  // untuk strip leading zero dan detik
  String _formatJamForApi(String jam) {
    // "08:00" → "8:00", "05:00:00" → "5:00"
    final parts = jam.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '$hour:${minute.toString().padLeft(2, '0')}';
  }

  // 3. Tambah helper untuk display (tetap HH:mm di UI)
  String _formatJamForDisplay(String jam) {
    final parts = jam.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
