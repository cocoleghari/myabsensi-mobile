import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/shift_controller.dart';
import '../master_drawer.dart';
import 'shift_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POLA MINGGUAN PAGE — halaman mandiri
// ─────────────────────────────────────────────────────────────────────────────

class PolaMinggguanPage extends StatefulWidget {
  const PolaMinggguanPage({super.key});

  @override
  State<PolaMinggguanPage> createState() => _PolaMinggguanPageState();
}

class _PolaMinggguanPageState extends State<PolaMinggguanPage> {
  late ShiftController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ShiftController>();
    _ctrl.fetchWeeklyPatterns();
    _ctrl.fetchShiftsDropdown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: const MasterDrawer(currentPage: 'shift-patterns'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Pola Shift Mingguan',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoadingPatterns.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctrl.weeklyPatterns.isEmpty) {
          return buildEmpty(
            'Belum ada pola shift mingguan',
            Icons.calendar_view_week_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: _ctrl.fetchWeeklyPatterns,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: _ctrl.weeklyPatterns.length,
            itemBuilder: (_, i) =>
                _PatternCard(pattern: _ctrl.weeklyPatterns[i], ctrl: _ctrl),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPatternFormDialog(context, _ctrl),
        backgroundColor: const Color(0xFF00897B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Pola',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── PATTERN CARD ──────────────────────────────────────────────────────────────

class _PatternCard extends StatelessWidget {
  final WeeklyPatternModel pattern;
  final ShiftController ctrl;
  const _PatternCard({required this.pattern, required this.ctrl});

  static const _hariLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _hariColors = [
    Color(0xFF1565C0),
    Color(0xFF1565C0),
    Color(0xFF1565C0),
    Color(0xFF1565C0),
    Color(0xFF00695C),
    Color(0xFFE65100),
    Color(0xFFB71C1C),
  ];

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
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_view_week,
                    color: Color(0xFF00897B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pattern.nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        '${pattern.kode}  •  ${pattern.companyName ?? '-'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(active: pattern.isActive),
              ],
            ),
            const SizedBox(height: 12),
            // ── Day grid: gunakan LayoutBuilder agar tidak overflow ──
            if (pattern.days.isNotEmpty) _buildDayGrid(),
            const SizedBox(height: 10),
            Row(
              children: [
                if (pattern.keterangan != null) ...[
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pattern.keterangan!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                ActionButtons(
                  onEdit: () async {
                    Get.dialog(
                      const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false,
                    );

                    final detail = await ctrl.fetchWeeklyPatternDetail(
                      pattern.id,
                    );
                    Get.back(); // tutup loading indicator

                    if (detail != null) {
                      // ignore: use_build_context_synchronously
                      _showPatternFormDialog(context, ctrl, existing: detail);
                    }
                  },
                  onDelete: () => showDeleteConfirm(
                    context,
                    title: 'Hapus Pola Shift',
                    message:
                        'Hapus pola "${pattern.nama}"? Pola yang masih digunakan tidak dapat dihapus.',
                    onConfirm: () async => ctrl.deleteWeeklyPattern(pattern.id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayGrid() {
    // Pakai LayoutBuilder supaya lebar sel tepat dan tidak ada pixel error
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final cellWidth = (totalWidth - 6 * 3) / 7; // 3px gap × 6

        return Row(
          children: List.generate(7, (hari) {
            final day = pattern.days.firstWhereOrNull((d) => d.hari == hari);
            final isLibur = day?.isLibur ?? true;
            final hasShift = !isLibur && day?.shiftNama != null;
            final color = _hariColors[hari];

            return SizedBox(
              width: cellWidth,
              child: Container(
                margin: hari < 6
                    ? const EdgeInsets.only(right: 3)
                    : EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isLibur
                      ? Colors.grey.shade100
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isLibur
                        ? Colors.grey.shade200
                        : color.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _hariLabels[hari],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isLibur ? Colors.grey.shade400 : color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    if (isLibur)
                      Icon(Icons.remove, size: 10, color: Colors.grey.shade300)
                    else if (hasShift)
                      Text(
                        day!.shiftNama!.length > 4
                            ? day.shiftNama!.substring(0, 4)
                            : day.shiftNama!,
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG FORM POLA MINGGUAN
// Fix: hilangkan Obx di dalam StatefulWidget — gunakan setState + snapshot list
// ─────────────────────────────────────────────────────────────────────────────

void _showPatternFormDialog(
  BuildContext context,
  ShiftController ctrl, {
  WeeklyPatternModel? existing,
}) {
  Get.dialog(
    _PatternFormDialog(ctrl: ctrl, existing: existing),
    barrierDismissible: false,
  );
}

class _PatternFormDialog extends StatefulWidget {
  final ShiftController ctrl;
  final WeeklyPatternModel? existing;
  const _PatternFormDialog({required this.ctrl, this.existing});

  @override
  State<_PatternFormDialog> createState() => _PatternFormDialogState();
}

class _PatternFormDialogState extends State<_PatternFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nama, _kode, _keterangan;
  int? _companyId;
  bool _isActive = true;
  bool _loading = false;

  // hari 0=Senin … 6=Minggu
  final List<int?> _dayShiftIds = List.filled(7, null);
  final List<bool> _dayLibur = List.filled(7, true);

  static const _hariLabels = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  // Snapshot list agar tidak bergantung pada Obx di StatefulWidget
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _shifts = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nama = TextEditingController(text: e?.nama ?? '');
    _kode = TextEditingController(text: e?.kode ?? '');
    _keterangan = TextEditingController(text: e?.keterangan ?? '');
    _isActive = e?.isActive ?? true;
    _companyId = e?.companyId;

    // Isi data hari dari existing — dilakukan SEKALI di sini, tidak di setState
    if (e != null && e.days.isNotEmpty) {
      for (final day in e.days) {
        if (day.hari >= 0 && day.hari < 7) {
          _dayLibur[day.hari] = day.isLibur;
          _dayShiftIds[day.hari] = day.shiftId;
        }
      }
    }

    // Snapshot awal dari cache controller
    _companies = widget.ctrl.companiesList.toList();
    _shifts = widget.ctrl.shiftsList.toList();

    // Load dropdown tanpa mereset data hari
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    await Future.wait([
      widget.ctrl.fetchCompanies(),
      widget.ctrl.fetchShiftsDropdown(),
    ]);
    if (!mounted) return;
    setState(() {
      _companies = widget.ctrl.companiesList.toList();
      _shifts = widget.ctrl.shiftsList.toList();
      // ← TAMBAHKAN INI: re-apply data hari setelah shifts terisi
      // supaya rebuild baris yang tadinya render spinner
      final e = widget.existing;
      if (e != null && e.days.isNotEmpty) {
        for (final day in e.days) {
          if (day.hari >= 0 && day.hari < 7) {
            _dayLibur[day.hari] = day.isLibur;
            _dayShiftIds[day.hari] = day.shiftId;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _nama.dispose();
    _kode.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_companyId == null) {
      Get.snackbar(
        'Error',
        'Pilih perusahaan',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    for (int i = 0; i < 7; i++) {
      if (!_dayLibur[i] && _dayShiftIds[i] == null) {
        Get.snackbar(
          'Error',
          'Pilih shift untuk hari ${_hariLabels[i]}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    setState(() => _loading = true);

    final days = List.generate(
      7,
      (i) => {
        'hari': i,
        'is_libur': _dayLibur[i],
        'shift_id': _dayLibur[i] ? null : _dayShiftIds[i],
      },
    );

    final payload = {
      'company_id': _companyId,
      'nama': _nama.text.trim(),
      'kode': _kode.text.trim().toUpperCase(),
      'keterangan': _keterangan.text.trim().isEmpty
          ? null
          : _keterangan.text.trim(),
      'is_active': _isActive,
      'days': days,
    };

    bool ok;
    if (widget.existing != null) {
      ok = await widget.ctrl.updateWeeklyPattern(widget.existing!.id, payload);
    } else {
      ok = await widget.ctrl.createWeeklyPattern(payload);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      // Tutup dialog DULU, baru refresh + snackbar
      Get.back();
      await widget.ctrl.fetchWeeklyPatterns();
      widget.ctrl.showSuccessSnackbar(
        widget.existing != null
            ? 'Pola shift berhasil diperbarui'
            : 'Pola shift berhasil dibuat',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

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
                  icon: Icons.calendar_view_week,
                  title: isEdit ? 'Edit Pola Shift' : 'Tambah Pola Shift',
                  color: const Color(0xFF00897B),
                ),
                const SizedBox(height: 16),

                buildDropdown<int>(
                  label: 'Perusahaan',
                  value: _companies.any((c) => c['id'] == _companyId)
                      ? _companyId
                      : null,
                  items: _companies
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
                      child: buildTextField(_nama, 'Nama Pola', required: true),
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
                const SizedBox(height: 16),

                Text(
                  'Jadwal per hari',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),

                // 7 baris hari — pakai setState biasa, tidak ada Obx
                Column(
                  children: List.generate(7, (hari) => _buildDayRow(hari)),
                ),
                const SizedBox(height: 12),

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
                  submitLabel: isEdit ? 'Simpan' : 'Buat Pola',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayRow(int hari) {
    final isLibur = _dayLibur[hari];
    final isWeekend = hari >= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLibur ? Colors.grey.shade50 : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLibur ? Colors.grey.shade200 : Colors.blue.shade100,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              _hariLabels[hari],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isWeekend
                    ? Colors.orange.shade700
                    : Colors.grey.shade700,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _dayLibur[hari] = !_dayLibur[hari];
              if (_dayLibur[hari]) _dayShiftIds[hari] = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isLibur ? Colors.grey.shade200 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isLibur ? 'Libur' : 'Kerja',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isLibur ? Colors.grey.shade600 : Colors.blue.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (!isLibur)
            Expanded(
              child: _shifts.isEmpty
                  // Belum selesai load — tampilkan shimmer kecil
                  ? Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      value: _shifts.any((s) => s['id'] == _dayShiftIds[hari])
                          ? _dayShiftIds[hari]
                          : null, // hindari assertion error jika value tidak ada di items
                      isExpanded: true,
                      menuMaxHeight: 260,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                      ),
                      hint: const Text(
                        'Pilih shift',
                        style: TextStyle(fontSize: 12),
                      ),
                      selectedItemBuilder: (context) => _shifts
                          .map(
                            (s) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${s['nama']} (${s['jam_masuk']})',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      items: _shifts
                          .map(
                            (s) => DropdownMenuItem<int>(
                              value: s['id'] as int?,
                              child: Text(
                                '${s['nama']} '
                                '(${s['jam_masuk']} - ${s['jam_pulang']})',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _dayShiftIds[hari] = v),
                    ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
