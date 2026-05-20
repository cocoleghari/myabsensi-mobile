import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/employee_pusat_lokasi_controller.dart';

class LokasiTableWidget extends GetView<EmployeePusatLokasiController> {
  const LokasiTableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const _LoadingState();
      }

      if (controller.employeeLokasis.isEmpty) {
        return const _EmptyState();
      }

      // Group by employee_id
      final Map<int, List<Map<String, dynamic>>> groupedByEmployee = {};
      for (var lokasi in controller.employeeLokasis) {
        final empId = lokasi['employee_id'] as int?;
        if (empId == null) continue;
        groupedByEmployee.putIfAbsent(empId, () => []).add(lokasi);
      }

      final sortedEmployeeIds = groupedByEmployee.keys.toList()
        ..sort((a, b) {
          final nameA = controller.getEmployeeName(a);
          final nameB = controller.getEmployeeName(b);
          return nameA.compareTo(nameB);
        });

      return _PaginatedLokasiList(
        sortedEmployeeIds: sortedEmployeeIds,
        groupedByEmployee: groupedByEmployee,
        controller: controller,
      );
    });
  }
}

// ── Helper global ───────────────────────────────────────────────
String extractFieldName(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map) {
    return value['name']?.toString() ??
        value['nama']?.toString() ??
        value['nama_jabatan']?.toString() ??
        value['nama_departemen']?.toString() ??
        '';
  }
  return value.toString();
}

// ── Paginated List ──────────────────────────────────────────────
class _PaginatedLokasiList extends StatefulWidget {
  final List<int> sortedEmployeeIds;
  final Map<int, List<Map<String, dynamic>>> groupedByEmployee;
  final EmployeePusatLokasiController controller;

  const _PaginatedLokasiList({
    required this.sortedEmployeeIds,
    required this.groupedByEmployee,
    required this.controller,
  });

  @override
  State<_PaginatedLokasiList> createState() => _PaginatedLokasiListState();
}

class _PaginatedLokasiListState extends State<_PaginatedLokasiList> {
  static const int _pageSize = 20;
  int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getEmpData(int empId) {
    try {
      return widget.controller.employees.firstWhere(
        (e) => e['id'] == empId,
        orElse: () => {},
      );
    } catch (_) {
      return {};
    }
  }

  List<int> get _filteredIds {
    if (_searchQuery.isEmpty) return widget.sortedEmployeeIds;
    return widget.sortedEmployeeIds.where((id) {
      final name = widget.controller.getEmployeeName(id).toLowerCase();
      final emp = _getEmpData(id);
      final position = extractFieldName(emp['position']).toLowerCase();
      final department = extractFieldName(emp['department']).toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || position.contains(q) || department.contains(q);
    }).toList();
  }

  int get _totalPages =>
      (_filteredIds.length / _pageSize).ceil().clamp(1, 9999);

  List<int> get _pageIds {
    final filtered = _filteredIds;
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }

  void _onSearch(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIds;
    final pageIds = _pageIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats
        _buildStatsRow(filtered.length),
        const SizedBox(height: 12),

        // Search
        _buildSearchBar(),
        const SizedBox(height: 14),

        // Cards
        if (pageIds.isEmpty)
          _buildNoResult()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageIds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final empId = pageIds[index];
              final empLokasis = widget.groupedByEmployee[empId]!;
              final empData = _getEmpData(empId);
              final empName = widget.controller.getEmployeeName(empId);
              final globalIndex = _currentPage * _pageSize + index;

              return _EmployeeCard(
                index: globalIndex,
                empId: empId,
                empName: empName,
                empData: empData,
                empLokasis: empLokasis,
                controller: widget.controller,
              );
            },
          ),

        // Pagination
        if (_totalPages > 1) ...[
          const SizedBox(height: 16),
          _buildPagination(),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStatsRow(int filteredCount) {
    final totalLokasi = widget.controller.employeeLokasis.length;
    final totalKaryawan = widget.sortedEmployeeIds.length;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _StatPill(
          icon: Icons.people_rounded,
          label: '$totalKaryawan Karyawan',
          color: Colors.blue,
        ),
        _StatPill(
          icon: Icons.location_on_rounded,
          label: '$totalLokasi Lokasi',
          color: Colors.teal,
        ),
        if (_searchQuery.isNotEmpty)
          _StatPill(
            icon: Icons.filter_list_rounded,
            label: '$filteredCount hasil',
            color: Colors.orange,
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari nama, jabatan, departemen...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResult() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Tidak ada hasil untuk "$_searchQuery"',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── FIXED Pagination — max 5 slots, no overflow ─────────────
  Widget _buildPagination() {
    final start = _currentPage * _pageSize + 1;
    final end = ((_currentPage + 1) * _pageSize).clamp(0, _filteredIds.length);
    final slots = _buildPageSlots();

    return Column(
      children: [
        Text(
          'Menampilkan $start–$end dari ${_filteredIds.length} karyawan',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              enabled: _currentPage > 0,
              onTap: () => setState(() => _currentPage--),
            ),
            const SizedBox(width: 4),
            // Fixed 5-slot pagination — never overflows
            ...slots.map((page) {
              if (page == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '···',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      letterSpacing: 1,
                    ),
                  ),
                );
              }
              return _PageButton(
                page: page,
                current: _currentPage,
                onTap: (p) => setState(() => _currentPage = p),
              );
            }),
            const SizedBox(width: 4),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              enabled: _currentPage < _totalPages - 1,
              onTap: () => setState(() => _currentPage++),
            ),
          ],
        ),
      ],
    );
  }

  /// Returns EXACTLY 5 slots. null = ellipsis, int = page index.
  /// Total width: 2 nav (34×2) + 4 gaps + 3 page btns (34×3) + 2 ellipsis (~20×2)
  /// ≈ 68 + ~16 + 102 + 40 = ~226px — fits any phone screen.
  List<int?> _buildPageSlots() {
    if (_totalPages <= 5) {
      // Show all pages, pad with nulls not needed
      return List.generate(_totalPages, (i) => i);
    }

    final cur = _currentPage;
    final last = _totalPages - 1;

    if (cur <= 2) {
      // [0, 1, 2, ···, last]
      return [0, 1, 2, null, last];
    }
    if (cur >= last - 2) {
      // [0, ···, last-2, last-1, last]
      return [0, null, last - 2, last - 1, last];
    }
    // Middle: [0, ···, cur, ···, last]
    return [0, null, cur, null, last];
  }
}

// ── Employee Card ───────────────────────────────────────────────
class _EmployeeCard extends StatelessWidget {
  final int index;
  final int empId;
  final String empName;
  final Map<String, dynamic> empData;
  final List<Map<String, dynamic>> empLokasis;
  final EmployeePusatLokasiController controller;

  const _EmployeeCard({
    required this.index,
    required this.empId,
    required this.empName,
    required this.empData,
    required this.empLokasis,
    required this.controller,
  });

  String get _position => extractFieldName(empData['position']);
  String get _department => extractFieldName(empData['department']);
  int get _lokasiCount => empLokasis.length;

  String get _initials {
    final parts = empName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return empName.isNotEmpty ? empName[0].toUpperCase() : '?';
  }

  Color get _avatarColor {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF0D9488),
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _avatarColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_position.isNotEmpty || _department.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        _position,
                        _department,
                      ].where((s) => s.isNotEmpty).join(' • '),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _lokasiCount > 0
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _lokasiCount > 0
                          ? '$_lokasiCount lokasi'
                          : 'Belum ada lokasi',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _lokasiCount > 0
                            ? Colors.blue.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: Icons.visibility_rounded,
                  color: const Color(0xFF6366F1),
                  tooltip: 'Detail',
                  onTap: () => _showDetailSheet(context),
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.add_location_alt_rounded,
                  color: const Color(0xFF10B981),
                  tooltip: 'Tambah Lokasi',
                  onTap: () => _showTambahDialog(context),
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.delete_rounded,
                  color: const Color(0xFFEF4444),
                  tooltip: 'Hapus Lokasi',
                  onTap: _lokasiCount == 0
                      ? null
                      : () => _lokasiCount == 1
                            ? _showDeleteSingleDialog(context, empLokasis.first)
                            : _showDeletePickerSheet(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail Sheet ──────────────────────────────────────────────
  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _avatarColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _avatarColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          empName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_position.isNotEmpty || _department.isNotEmpty)
                          Text(
                            [
                              _position,
                              _department,
                            ].where((s) => s.isNotEmpty).join(' • '),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_lokasiCount lokasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            Expanded(
              child: _lokasiCount == 0
                  ? Center(
                      child: Text(
                        'Belum ada lokasi',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: empLokasis.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (ctx, i) {
                        final lok = empLokasis[i];
                        final nama =
                            lok['pusat_lokasi']?['nama_lokasi']?.toString() ??
                            lok['nama_lokasi']?.toString() ??
                            '-';
                        final koordinat =
                            lok['pusat_lokasi']?['titik_kordinat']
                                ?.toString() ??
                            '-';
                        final radius = lok['radius_meter']?.toString() ?? '100';
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            nama,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                koordinat,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              Text(
                                'Radius: ${radius}m',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteSingleDialog(context, lok);
                            },
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tambah Dialog ─────────────────────────────────────────────
  void _showTambahDialog(BuildContext context) {
    final selectedIds = <int>[].obs;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_location_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tambah Lokasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          empName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: Obx(() {
                if (controller.pusatLokasis.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Tidak ada pusat lokasi tersedia.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: controller.pusatLokasis.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) {
                    final lok = controller.pusatLokasis[i];
                    final id = lok['id'] as int;
                    final nama = lok['nama_lokasi']?.toString() ?? '-';
                    final sudahAda = empLokasis.any(
                      (e) =>
                          (e['pusat_lokasi_id'] ?? e['pusat_lokasi']?['id']) ==
                          id,
                    );
                    return Obx(() {
                      final isChecked = selectedIds.contains(id);
                      return ListTile(
                        dense: true,
                        enabled: !sudahAda,
                        leading: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: sudahAda
                              ? Colors.grey.shade300
                              : Colors.blue.shade400,
                        ),
                        title: Text(
                          nama,
                          style: TextStyle(
                            fontSize: 13,
                            color: sudahAda
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                        ),
                        subtitle: sudahAda
                            ? Text(
                                'Sudah terdaftar',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                ),
                              )
                            : null,
                        trailing: sudahAda
                            ? Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.grey.shade300,
                              )
                            : Checkbox(
                                value: isChecked,
                                activeColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  val == true
                                      ? selectedIds.add(id)
                                      : selectedIds.remove(id);
                                },
                              ),
                        onTap: sudahAda
                            ? null
                            : () {
                                selectedIds.contains(id)
                                    ? selectedIds.remove(id)
                                    : selectedIds.add(id);
                              },
                      );
                    });
                  },
                );
              }),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Obx(() {
                      final count = selectedIds.length;
                      return ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: Text(
                          count == 0 ? 'Pilih Lokasi' : 'Simpan ($count)',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: count == 0
                            ? null
                            : () async {
                                Get.back();
                                int berhasil = 0;
                                for (final pid in List<int>.from(selectedIds)) {
                                  final ok = await controller.addEmployeeLokasi(
                                    employeeId: empId,
                                    pusatLokasiId: pid,
                                  );
                                  if (ok) berhasil++;
                                }
                                if (berhasil > 0) {
                                  Get.snackbar(
                                    'Berhasil',
                                    '$berhasil lokasi ditambahkan ke $empName',
                                    backgroundColor: Colors.green,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.TOP,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Single ─────────────────────────────────────────────
  void _showDeleteSingleDialog(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final nama =
        item['pusat_lokasi']?['nama_lokasi']?.toString() ??
        item['nama_lokasi']?.toString() ??
        '-';
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Hapus Lokasi', style: TextStyle(fontSize: 15)),
          ],
        ),
        content: Text.rich(
          TextSpan(
            text: 'Hapus lokasi ',
            style: const TextStyle(fontSize: 13),
            children: [
              TextSpan(
                text: '"$nama"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' dari karyawan ini?'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deleteEmployeeLokasi(item['id'] as int);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ── Delete Picker Sheet (jika > 1 lokasi) ────────────────────
  void _showDeletePickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hapus lokasi — $empName',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.red,
                  size: 18,
                ),
              ),
              title: Text(
                'Hapus semua ($_lokasiCount lokasi)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAllConfirm(context);
              },
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: empLokasis.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (ctx, i) {
                  final lok = empLokasis[i];
                  final nama =
                      lok['pusat_lokasi']?['nama_lokasi']?.toString() ??
                      lok['nama_lokasi']?.toString() ??
                      '-';
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: Colors.blue.shade400,
                    ),
                    title: Text(nama, style: const TextStyle(fontSize: 13)),
                    trailing: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteSingleDialog(context, lok);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAllConfirm(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Hapus Semua', style: TextStyle(fontSize: 15)),
          ],
        ),
        content: Text.rich(
          TextSpan(
            text: 'Hapus semua ',
            style: const TextStyle(fontSize: 13),
            children: [
              TextSpan(
                text: '$_lokasiCount lokasi',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' milik '),
              TextSpan(
                text: empName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );
              for (var lok in empLokasis) {
                await controller.deleteEmployeeLokasi(lok['id'] as int);
              }
              Get.back();
              Get.snackbar(
                'Berhasil',
                'Semua lokasi $empName dihapus',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}

// ── Action Button ───────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: disabled ? Colors.grey.shade100 : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: disabled ? Colors.grey.shade300 : color,
          ),
        ),
      ),
    );
  }
}

// ── Stat Pill ───────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav Button ──────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.white : Colors.grey.shade300,
        ),
      ),
    );
  }
}

// ── Page Button ─────────────────────────────────────────────────
class _PageButton extends StatelessWidget {
  final int page;
  final int current;
  final void Function(int) onTap;

  const _PageButton({
    required this.page,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = page == current;
    return GestureDetector(
      onTap: () => onTap(page),
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            '${page + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Loading State (fallback shimmer inside widget) ──────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada data lokasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lokasi karyawan akan muncul di sini',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
