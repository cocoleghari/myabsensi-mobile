import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/shift_controller.dart';
import 'shift_shared_widgets.dart';

class BulkAssignShiftDialog extends StatefulWidget {
  final ShiftController ctrl;
  const BulkAssignShiftDialog({super.key, required this.ctrl});

  @override
  State<BulkAssignShiftDialog> createState() => _BulkAssignShiftDialogState();
}

class _BulkAssignShiftDialogState extends State<BulkAssignShiftDialog> {
  static const _purple = Color(0xFF5E35B1);
  static const _indigo = Color(0xFF311B92);

  int _activeTab = 0;

  // Config shift
  int? _shiftId;
  int? _patternId;
  bool _usePattern = false;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  final _keteranganCtrl = TextEditingController();

  // Karyawan
  final Set<int> _selectedIds = {};
  String _searchLeft = '';
  String _searchRight = '';

  // ── FILTER BARU ───────────────────────────────────────────────
  int? _filterPositionId;
  int? _filterJobGradeId;
  List<Map<String, dynamic>> _positionOptions = [];
  List<Map<String, dynamic>> _jobGradeOptions = [];
  // ─────────────────────────────────────────────────────────────

  // Snapshot lists
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _patterns = [];

  bool _isLoading = true;
  bool _isSaving = false;
  int _progressDone = 0;
  int _progressTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    setState(() => _isLoading = true);
    await Future.wait([
      widget.ctrl.fetchEmployeesDropdownShift(),
      widget.ctrl.fetchShiftsDropdown(),
      widget.ctrl.fetchPatternsDropdown(),
    ]);
    if (mounted) {
      setState(() {
        _employees = widget.ctrl.employeesList.toList();
        _shifts = widget.ctrl.shiftsList.toList();
        _patterns = widget.ctrl.patternsList.toList();
        _isLoading = false;

        // ── Ekstrak opsi filter unik dari data karyawan ──
        _extractFilterOptions();
      });
    }
  }

  /// Ekstrak list position & job_grade unik dari employeesList
  void _extractFilterOptions() {
    final posMap = <int, Map<String, dynamic>>{};
    final gradeMap = <int, Map<String, dynamic>>{};

    for (final e in _employees) {
      final pos = e['position'];
      if (pos != null && pos['id'] != null) {
        posMap[pos['id'] as int] = {
          'id': pos['id'],
          'name': pos['name'] ?? '-',
        };
      }
      final grade = e['job_grade'];
      if (grade != null && grade['id'] != null) {
        gradeMap[grade['id'] as int] = {
          'id': grade['id'],
          'name': grade['name'] ?? '-',
          'code': grade['code'] ?? '',
        };
      }
    }

    _positionOptions = posMap.values.toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    _jobGradeOptions = gradeMap.values.toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Filter logic ─────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredLeft {
    var list = _employees
        .where((e) => !_selectedIds.contains(e['id']))
        .toList();

    // filter position
    if (_filterPositionId != null) {
      list = list
          .where((e) => e['position']?['id'] == _filterPositionId)
          .toList();
    }
    // filter job_grade
    if (_filterJobGradeId != null) {
      list = list
          .where((e) => e['job_grade']?['id'] == _filterJobGradeId)
          .toList();
    }
    // search teks
    if (_searchLeft.isNotEmpty) {
      final q = _searchLeft.toLowerCase();
      list = list.where((e) {
        final name = (e['full_name'] ?? '').toString().toLowerCase();
        final code = (e['employee_code'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    }
    return list;
  }

  List<Map<String, dynamic>> get _filteredRight {
    final selected = _employees
        .where((e) => _selectedIds.contains(e['id']))
        .toList();
    if (_searchRight.isEmpty) return selected;
    final q = _searchRight.toLowerCase();
    return selected.where((e) {
      final name = (e['full_name'] ?? '').toString().toLowerCase();
      final code = (e['employee_code'] ?? '').toString().toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  bool get _hasActiveFilter =>
      _filterPositionId != null || _filterJobGradeId != null;

  // ── Submit ────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) {
      Get.snackbar(
        'Error',
        'Pilih minimal 1 karyawan',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
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

    setState(() {
      _isSaving = true;
      _progressDone = 0;
      _progressTotal = _selectedIds.length;
    });

    final basePayload = {
      if (_usePattern) 'pattern_id': _patternId else 'shift_id': _shiftId,
      'tanggal_mulai': _fmt(_tanggalMulai!),
      if (_tanggalSelesai != null) 'tanggal_selesai': _fmt(_tanggalSelesai!),
      if (_keteranganCtrl.text.trim().isNotEmpty)
        'keterangan': _keteranganCtrl.text.trim(),
    };

    final result = await widget.ctrl.bulkAssignShift(
      employeeIds: _selectedIds.toList(),
      basePayload: basePayload,
      onProgress: (done, total) {
        if (mounted) setState(() => _progressDone = done);
      },
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    final success = result['success'] as int;
    final failed = result['failed'] as int;
    final skipped = result['skipped'] as int;

    String msg = '$success karyawan berhasil di-assign';
    if (skipped > 0) msg += ', $skipped dilewati (sudah ada)';
    if (failed > 0) msg += ', $failed gagal';

    Get.back();
    Get.snackbar(
      failed == 0 ? 'Berhasil' : 'Selesai dengan error',
      msg,
      backgroundColor: failed == 0 ? Colors.green : Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F4FA),
        body: Column(
          children: [
            _buildHeader(context),
            _buildConfigSection(),
            _buildTabBar(),
            Expanded(child: _buildBody()),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

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
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.group_add_outlined,
              color: _purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk Assign Shift',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A1A2E),
                    height: 1.2,
                  ),
                ),
                Text(
                  'Assign shift ke banyak karyawan sekaligus',
                  style: TextStyle(
                    fontSize: 12,
                    color: _purple,
                    fontWeight: FontWeight.w500,
                  ),
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

  // ── Config Section ────────────────────────────────────────────

  Widget _buildConfigSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Mode toggle
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _modeTab(
                  'Shift Langsung',
                  Icons.schedule,
                  !_usePattern,
                  () => setState(() => _usePattern = false),
                ),
                _modeTab(
                  'Pola Mingguan',
                  Icons.calendar_view_week,
                  _usePattern,
                  () => setState(() => _usePattern = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (!_usePattern)
            buildDropdown<int>(
              label: 'Pilih Shift',
              value: _shifts.any((s) => s['id'] == _shiftId) ? _shiftId : null,
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
              label: 'Pilih Pola Mingguan',
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
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
          buildTextField(_keteranganCtrl, 'Keterangan (opsional)', maxLines: 2),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBFF),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _tabItem(
              label: 'Dapat Dipilih',
              count: _filteredLeft.length,
              isActive: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
            ),
            _tabItem(
              label: 'Terpilih',
              count: _selectedIds.length,
              isActive: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
            ),
          ],
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

  // ── Body ──────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
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
    return _activeTab == 0 ? _buildLeftPanel() : _buildRightPanel();
  }

  // ── Panel Tersedia (dengan filter) ────────────────────────────

  Widget _buildLeftPanel() {
    final list = _filteredLeft;
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: _searchField(
            hint: 'Cari nama atau kode karyawan...',
            onChanged: (v) => setState(() => _searchLeft = v),
          ),
        ),

        // ── FILTER CHIPS ─────────────────────────────────────────
        if (_positionOptions.isNotEmpty || _jobGradeOptions.isNotEmpty)
          _buildFilterBar(),
        // ─────────────────────────────────────────────────────────

        // Action bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Text(
                '${list.length} karyawan tersedia',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIds.addAll(list.map((e) => e['id'] as int));
                    _activeTab = 1;
                  });
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

        // List
        Expanded(
          child: list.isEmpty
              ? _emptyState(
                  icon: Icons.people_outline,
                  message: (_searchLeft.isNotEmpty || _hasActiveFilter)
                      ? 'Tidak ada hasil pencarian'
                      : 'Semua karyawan sudah dipilih',
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 68,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (_, i) => _employeeTile(
                    employee: list[i],
                    trailing: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDE7F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 15, color: _purple),
                    ),
                    onTap: () =>
                        setState(() => _selectedIds.add(list[i]['id'] as int)),
                    bgColor: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  // ── Filter Bar ────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: label + tombol reset
          Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: 14,
                color: _hasActiveFilter ? _purple : Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                'Filter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hasActiveFilter ? _purple : Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilter)
                GestureDetector(
                  onTap: () => setState(() {
                    _filterPositionId = null;
                    _filterJobGradeId = null;
                  }),
                  child: Text(
                    'Reset filter',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Chips scroll horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // ── Dropdown Position ──────────────────────────
                _FilterDropdown(
                  label: 'Posisi',
                  icon: Icons.work_outline,
                  selectedId: _filterPositionId,
                  options: _positionOptions,
                  displayText: (opt) => opt['name'] as String,
                  onSelected: (id) => setState(() => _filterPositionId = id),
                  activeColor: _purple,
                ),
                const SizedBox(width: 8),

                // ── Dropdown Job Grade ─────────────────────────
                _FilterDropdown(
                  label: 'Job Grade',
                  icon: Icons.grade_outlined,
                  selectedId: _filterJobGradeId,
                  options: _jobGradeOptions,
                  displayText: (opt) {
                    final code = opt['code'] as String? ?? '';
                    final name = opt['name'] as String? ?? '';
                    return code.isNotEmpty ? '$code - $name' : name;
                  },
                  onSelected: (id) => setState(() => _filterJobGradeId = id),
                  activeColor: Colors.orange.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel Terpilih ────────────────────────────────────────────

  Widget _buildRightPanel() {
    final list = _filteredRight;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _searchField(
            hint: 'Cari dari yang sudah dipilih...',
            onChanged: (v) => setState(() => _searchRight = v),
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
              Text(
                '${_selectedIds.length} karyawan dipilih',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedIds.removeAll(
                    _filteredRight.map((e) => e['id'] as int),
                  );
                }),
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
          child: list.isEmpty
              ? _emptyState(
                  icon: Icons.person_add_alt_outlined,
                  message:
                      'Belum ada karyawan dipilih.\nBuka tab "Dapat Dipilih" untuk menambahkan.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 68,
                    color: Colors.grey.shade100,
                  ),
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
                    onTap: () => setState(
                      () => _selectedIds.remove(list[i]['id'] as int),
                    ),
                    bgColor: const Color(0xFFFDFBFF),
                    leftAccent: _purple,
                  ),
                ),
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSaving) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressTotal > 0
                          ? _progressDone / _progressTotal
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      color: _purple,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$_progressDone/$_progressTotal',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedIds.length} dipilih',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _purple,
                    ),
                  ),
                  Text(
                    'dari ${_employees.length} karyawan',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
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
                  _isSaving
                      ? 'Memproses...'
                      : 'Assign${_selectedIds.isEmpty ? '' : ' (${_selectedIds.length})'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigo,
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
            ],
          ),
        ],
      ),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────

  Widget _modeTab(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
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

  Widget _searchField({
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
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
    final position = employee['position']?['name']?.toString() ?? '';
    final grade = employee['job_grade'];
    final gradeStr = grade != null
        ? ((grade['code'] as String? ?? '').isNotEmpty
              ? '${grade['code']} · ${grade['name']}'
              : grade['name']?.toString() ?? '')
        : '';
    final photoUrl = employee['photo_url']?.toString();
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    // Sub-label: gabung position & grade
    final subParts = [
      if (code.isNotEmpty) code,
      if (position.isNotEmpty) position,
      if (gradeStr.isNotEmpty) gradeStr,
    ];

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFFEDE7F6),
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
                backgroundColor: const Color(0xFFEDE7F6),
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
                    const SizedBox(height: 2),
                    Text(
                      subParts.join(' · '),
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
                color: Color(0xFFEDE7F6),
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
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_tanggalMulai ?? DateTime.now())
          : (_tanggalSelesai ?? _tanggalMulai ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null)
      setState(() {
        if (isStart)
          _tanggalMulai = picked;
        else
          _tanggalSelesai = picked;
      });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE: Filter Dropdown Chip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final int? selectedId;
  final List<Map<String, dynamic>> options;
  final String Function(Map<String, dynamic>) displayText;
  final void Function(int?) onSelected;
  final Color activeColor;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.selectedId,
    required this.options,
    required this.displayText,
    required this.onSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selectedId != null;
    final selected = isActive
        ? options.firstWhere((o) => o['id'] == selectedId, orElse: () => {})
        : null;
    final chipLabel = (selected != null && selected.isNotEmpty)
        ? displayText(selected)
        : label;

    return PopupMenuButton<int?>(
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        // Opsi "Semua" untuk reset
        PopupMenuItem<int?>(
          value: null,
          child: Row(
            children: [
              Icon(
                Icons.clear_all,
                size: 16,
                color: isActive ? Colors.grey : activeColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Semua $label',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.grey.shade600 : activeColor,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...options.map(
          (opt) => PopupMenuItem<int?>(
            value: opt['id'] as int,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: opt['id'] == selectedId
                      ? activeColor
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayText(opt),
                    style: TextStyle(
                      fontWeight: opt['id'] == selectedId
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: opt['id'] == selectedId
                          ? activeColor
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (opt['id'] == selectedId)
                  Icon(Icons.check, size: 14, color: activeColor),
              ],
            ),
          ),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.4)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? activeColor : Colors.grey.shade500,
            ),
            const SizedBox(width: 5),
            Text(
              chipLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? activeColor : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}
