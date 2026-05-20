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

  // Tab: 0 = Tersedia, 1 = Terpilih
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
      widget.ctrl.fetchEmployeesDropdown(),
      widget.ctrl.fetchShiftsDropdown(),
      widget.ctrl.fetchPatternsDropdown(),
    ]);
    if (mounted) {
      setState(() {
        _employees = widget.ctrl.employeesList.toList();
        _shifts = widget.ctrl.shiftsList.toList();
        _patterns = widget.ctrl.patternsList.toList();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> get _filteredLeft {
    var list = _employees
        .where((e) => !_selectedIds.contains(e['id']))
        .toList();
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

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

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

  // ── Config Section (shift + tanggal) ─────────────────────────────────────

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

          // Shift / Pattern dropdown
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

          // Tanggal
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

  // ── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final availCount = _filteredLeft.length;
    final selCount = _selectedIds.length;

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
              count: availCount,
              isActive: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
            ),
            _tabItem(
              label: 'Terpilih',
              count: selCount,
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

  // ── Body ──────────────────────────────────────────────────────────────────

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

  // ── Panel Tersedia ────────────────────────────────────────────────────────

  Widget _buildLeftPanel() {
    final list = _filteredLeft;
    return Column(
      children: [
        // Search
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _searchField(
            hint: 'Cari nama atau kode karyawan...',
            onChanged: (v) => setState(() => _searchLeft = v),
          ),
        ),
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
                  setState(
                    () => _selectedIds.addAll(list.map((e) => e['id'] as int)),
                  );
                  setState(() => _activeTab = 1);
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
                  message: _searchLeft.isNotEmpty
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

  // ── Panel Terpilih ────────────────────────────────────────────────────────

  Widget _buildRightPanel() {
    final list = _filteredRight;
    return Column(
      children: [
        // Search
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _searchField(
            hint: 'Cari dari yang sudah dipilih...',
            onChanged: (v) => setState(() => _searchRight = v),
          ),
        ),
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
        // List
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
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

  // ── Reusable Widgets ──────────────────────────────────────────────────────

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
    final position =
        employee['position']?['name']?.toString() ??
        employee['position']?.toString() ??
        '';
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
                      [
                        if (code.isNotEmpty) code,
                        if (position.isNotEmpty) position,
                      ].join(' · '),
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
