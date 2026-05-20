import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/app_config.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/models/employee_model.dart';
import 'package:http/http.dart' as http;

// ─── Pagination meta ─────────────────────────────────────────────────────────

class _PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const _PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });
}

// ─── Entry point ─────────────────────────────────────────────────────────────

class SearchEmployeeModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const _SearchSheet(),
    );
  }
}

// ─── Sheet ───────────────────────────────────────────────────────────────────

class _SearchSheet extends StatefulWidget {
  const _SearchSheet();

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String _query = '';
  bool _isLoading = false;

  List<EmployeeModel> _employees = [];
  _PaginationMeta? _meta;

  // Filter departemen — diisi dari GET /admin/departments
  // Response: { data: [{id, name}, ...] }
  List<String> _allDepartments = [];
  List<String> _selectedDepartments = [];
  bool _loadingDepartments = false;

  // Filter jabatan/posisi — diisi dari GET /admin/positions
  // Response: { data: [{id, name}, ...] }
  List<String> _allPositions = [];
  List<String> _selectedPositions = [];
  bool _loadingPositions = false;

  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _baseUrl = await AppConfig.getBaseUrl();
      _fetchPage(1); // departemen di-extract otomatis setelah ini
      _fetchPositionList(); // ← tetap ada
      // _fetchDepartmentList() ← HAPUS, sudah diganti _extractDepartmentsFromEmployees
    });

    _searchCtrl.addListener(() {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        final q = _searchCtrl.text.toLowerCase().trim();
        if (q != _query) {
          _query = q;
          _fetchPage(1);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Map<String, String> get _authHeaders {
    final auth = Get.find<AuthController>();
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${auth.token}',
    };
  }

  // =========================================================================
  // FETCH DEPARTMENTS
  // GET /admin/departments
  // Response: { data: [{id, name}, ...], meta: {...} }
  // =========================================================================

  Future<void> _fetchDepartmentList() async {
    if (_baseUrl.isEmpty) return;
    setState(() => _loadingDepartments = true);
    try {
      final res = await http.get(
        // Endpoint yang benar sesuai api.php: GET /admin/departments
        Uri.parse('$_baseUrl/admin/departments'),
        headers: _authHeaders,
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final data = json['data'];
        if (data is List) {
          setState(() {
            _allDepartments = data
                .map((e) {
                  if (e is String) return e;
                  return e['name']?.toString() ?? '';
                })
                .where((s) => s.isNotEmpty)
                .toList();
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingDepartments = false);
    }
  }

  // =========================================================================
  // FETCH POSITIONS
  // GET /admin/positions
  // Response: { data: [{id, name}, ...], meta: {...} }
  // =========================================================================

  Future<void> _fetchPositionList() async {
    if (_baseUrl.isEmpty) return;
    setState(() => _loadingPositions = true);
    try {
      // ← GANTI: pakai endpoint employee
      final res = await http.get(
        Uri.parse('$_baseUrl/user/jabatan-list'),
        headers: _authHeaders,
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final data = json['data'];
        if (data is List) {
          setState(() {
            _allPositions = data
                .map((e) => e is String ? e : e['name']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPositions = false);
    }
  }

  // =========================================================================
  // FETCH EMPLOYEES
  // GET /admin/employees
  // Query params yang didukung EmployeeController@index:
  //   search        → cari full_name, nik, employee_code
  //   department_id → filter by department
  //   per_page      → jumlah per halaman
  //   page          → halaman
  //
  // Response:
  //   { data: [...], meta: { total, current_page, last_page } }
  //
  // CATATAN: EmployeeController@index filter by department_id (integer),
  // bukan nama department. Maka perlu resolve nama → id terlebih dahulu.
  // Untuk sederhananya, filter departemen & posisi dilakukan client-side
  // dari hasil search, atau gunakan field 'search' saja untuk kata kunci.
  // =========================================================================

  Future<void> _fetchPage(int page) async {
    if (_baseUrl.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final queryParts = <String>[
        'page=$page',
        'per_page=50',
        if (_query.isNotEmpty) 'search=${Uri.encodeComponent(_query)}',
      ];

      // ← GANTI: pakai endpoint employee
      final uri = Uri.parse('$_baseUrl/user/karyawan?${queryParts.join('&')}');
      final res = await http.get(uri, headers: _authHeaders);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);

        List<dynamic> rawList = [];
        Map<String, dynamic>? metaData;

        if (json['data'] is List) {
          rawList = json['data'];
          // ← GANTI: UserController pakai key 'pagination', bukan 'meta'
          metaData = json['pagination'] ?? json['meta'];
        }

        final parsed = <EmployeeModel>[];
        for (final e in rawList) {
          try {
            // ← GANTI: flatten dulu sebelum parse
            parsed.add(EmployeeModel.fromJson(_flattenUserResponse(e)));
          } catch (_) {}
        }

        final filtered = parsed.where((emp) {
          if (_selectedDepartments.isNotEmpty) {
            final deptMatch = _selectedDepartments.any(
              (d) =>
                  d.toLowerCase() == (emp.departmentName ?? '').toLowerCase(),
            );
            if (!deptMatch) return false;
          }
          if (_selectedPositions.isNotEmpty) {
            final posMatch = _selectedPositions.any(
              (p) => p.toLowerCase() == (emp.positionName ?? '').toLowerCase(),
            );
            if (!posMatch) return false;
          }
          return true;
        }).toList();

        setState(() {
          _employees = filtered;
          if (metaData != null) {
            _meta = _PaginationMeta(
              currentPage: metaData['current_page'] ?? page,
              lastPage: metaData['last_page'] ?? 1,
              perPage: metaData['per_page'] ?? 20,
              total: metaData['total'] ?? rawList.length,
            );
          }
        });

        // Extract departemen dari hasil fetch
        _extractDepartmentsFromEmployees();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// UserController@index return struktur User (bukan Employee langsung):
  /// { id, name, email, role, employee: { id, full_name, department: {id,name}, ... } }
  ///
  /// EmployeeModel.fromJson butuh struktur Employee langsung:
  /// { id, full_name, department: {id,name}, position: {id,name}, ... }
  ///
  /// Method ini flatten keduanya jadi satu map.
  Map<String, dynamic> _flattenUserResponse(Map<String, dynamic> json) {
    final employee = json['employee'] as Map<String, dynamic>? ?? {};

    return {
      // ← PENTING: gunakan employee['id'] sebagai ID utama, bukan json['id']
      'id': employee['id'], // ← employee ID untuk /user/karyawan/{id}
      'user_id': json['id'], // ← user ID disimpan terpisah

      'full_name': employee['full_name'] ?? json['name'] ?? '',
      'nickname': employee['nickname'],
      'employee_code': employee['employee_code'],
      'nik': employee['nik'],
      'photo_url': employee['photo_url'],
      'department_id': employee['department_id'],
      'position_id': employee['position_id'],
      'employment_type': employee['employment_type'],
      'join_date': employee['join_date'],
      'department': employee['department'],
      'position': employee['position'],
      'company': employee['company'],
      'status': employee['status'],
      'user': {'email': json['email'], 'role': json['role']},
    };
  }

  void _extractDepartmentsFromEmployees() {
    final departments =
        _employees
            .map((e) => e.departmentName ?? '')
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (mounted) {
      setState(() {
        _allDepartments = departments;
        _loadingDepartments = false;
      });
    }
  }

  // =========================================================================
  // FILTER SHEET
  // =========================================================================

  void _showFilterSheet() {
    List<String> tempDepartments = List.from(_selectedDepartments);
    List<String> tempPositions = List.from(_selectedPositions);
    int activeTab = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final isDeptTab = activeTab == 0;
          final currentList = isDeptTab ? _allDepartments : _allPositions;
          final currentSelected = isDeptTab ? tempDepartments : tempPositions;
          final isLoadingCurrent = isDeptTab
              ? _loadingDepartments
              : _loadingPositions;

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (_, scrollCtrl) => Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8DCE8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      const Spacer(),
                      if (currentSelected.isNotEmpty)
                        GestureDetector(
                          onTap: () => setLocal(() => currentSelected.clear()),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF42A5F5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _filterTab(
                        label: 'Departemen',
                        count: tempDepartments.length,
                        isActive: activeTab == 0,
                        onTap: () => setLocal(() => activeTab = 0),
                      ),
                      const SizedBox(width: 8),
                      _filterTab(
                        label: 'Jabatan',
                        count: tempPositions.length,
                        isActive: activeTab == 1,
                        onTap: () => setLocal(() => activeTab = 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                // List item
                Expanded(
                  child: isLoadingCurrent
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF42A5F5),
                            strokeWidth: 3,
                          ),
                        )
                      : currentList.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada data',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          itemCount: currentList.length,
                          itemBuilder: (_, i) {
                            final item = currentList[i];
                            final checked = currentSelected.contains(item);
                            return InkWell(
                              onTap: () => setLocal(() {
                                if (checked) {
                                  currentSelected.remove(item);
                                } else {
                                  currentSelected.add(item);
                                }
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade100,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: checked
                                            ? const Color(0xFF42A5F5)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: checked
                                              ? const Color(0xFF42A5F5)
                                              : const Color(0xFFD0D5E0),
                                          width: 2,
                                        ),
                                      ),
                                      child: checked
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: checked
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: checked
                                              ? const Color(0xFF1A1F36)
                                              : const Color(0xFF3A3F56),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Tombol
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF42A5F5),
                            side: const BorderSide(color: Color(0xFF42A5F5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => setLocal(() {
                            tempDepartments.clear();
                            tempPositions.clear();
                          }),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedDepartments = List.from(tempDepartments);
                              _selectedPositions = List.from(tempPositions);
                            });
                            _fetchPage(1);
                          },
                          child: const Text(
                            'Terapkan',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterTab({
    required String label,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF42A5F5) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF8A94A6),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.3)
                      : const Color(0xFF42A5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildTopBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD8DCE8),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final hasActiveFilter =
        _selectedDepartments.isNotEmpty || _selectedPositions.isNotEmpty;
    final totalFilter = _selectedDepartments.length + _selectedPositions.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 230, 245, 255),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 20,
                  color: Color(0xFF42A5F5),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Daftar Karyawan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF5A6480),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search + filter button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5E8F0),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1F36),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, NIK, kode karyawan...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF8A94A6),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _searchCtrl.clear(),
                              child: const Icon(
                                Icons.cancel_rounded,
                                size: 18,
                                color: Color(0xFFB0B8C8),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showFilterSheet,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: hasActiveFilter
                            ? const Color(0xFF42A5F5)
                            : const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasActiveFilter
                              ? const Color(0xFF42A5F5)
                              : const Color(0xFFE5E8F0),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: hasActiveFilter
                            ? Colors.white
                            : const Color(0xFF8A94A6),
                      ),
                    ),
                    if (hasActiveFilter)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5252),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$totalFilter',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Active filter chips
          if (_selectedDepartments.isNotEmpty ||
              _selectedPositions.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._selectedDepartments.asMap().entries.map(
                    (e) => _filterChip(
                      label: e.value,
                      color: const Color(0xFF42A5F5),
                      bgColor: const Color(0xFFFFF0E6),
                      onRemove: () {
                        setState(() => _selectedDepartments.removeAt(e.key));
                        _fetchPage(1);
                      },
                    ),
                  ),
                  ..._selectedPositions.asMap().entries.map(
                    (e) => _filterChip(
                      label: e.value,
                      color: const Color(0xFF1565C0),
                      bgColor: const Color(0xFFEAF0FF),
                      onRemove: () {
                        setState(() => _selectedPositions.removeAt(e.key));
                        _fetchPage(1);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF42A5F5),
          strokeWidth: 3,
        ),
      );
    }

    if (_employees.isEmpty) {
      final noFilter =
          _query.isEmpty &&
          _selectedDepartments.isEmpty &&
          _selectedPositions.isEmpty;
      return _buildEmptyState(
        icon: noFilter
            ? Icons.people_outline_rounded
            : Icons.search_off_rounded,
        title: noFilter ? 'Tidak ada karyawan' : 'Tidak ditemukan',
        subtitle: noFilter
            ? 'Belum ada data karyawan tersedia'
            : 'Coba ubah kata kunci atau filter',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Text(
                _meta != null
                    ? 'Menampilkan ${_employees.length} dari ${_meta!.total} karyawan'
                    : '${_employees.length} karyawan',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A94A6),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            itemCount: _employees.length,
            itemBuilder: (_, i) => _buildCard(_employees[i]),
          ),
        ),
        if (_meta != null) _buildPagination(),
      ],
    );
  }

  // ─── Employee card ────────────────────────────────────────────────────────
  // Navigation: Get.toNamed('/employee/profile', arguments: emp)
  // EmployeeProfilePage membaca: Get.arguments as EmployeeModel
  // Pastikan route '/employee/profile' terdaftar di app_pages.dart

  Widget _buildCard(EmployeeModel emp) {
    final initial = emp.displayName.isNotEmpty
        ? emp.displayName[0].toUpperCase()
        : '?';

    // Subtitle: NIK · Jabatan · Departemen
    // Menggunakan field dari EmployeeModel yang sudah ter-parse dari
    // eager-load: company:id,name department:id,name position:id,name
    final subtitleParts = <String>[
      if ((emp.nik ?? '').isNotEmpty) emp.nik!,
      if ((emp.positionName ?? '').isNotEmpty)
        (emp.departmentName ?? '').isNotEmpty
            ? '${emp.positionName} · ${emp.departmentName}'
            : emp.positionName!,
    ];
    final subtitle = subtitleParts.join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Tutup modal, baru navigasi ke profil
            Navigator.pop(context);
            // arguments bertipe EmployeeModel — diterima di EmployeeProfilePage
            // via: _emp = Get.arguments as EmployeeModel;
            Get.toNamed('/employee/profile', arguments: emp);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildAvatar(initial, emp.photoUrl, 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F36),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A94A6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if ((emp.employeeCode ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.qr_code_rounded,
                              size: 11,
                              color: Color(0xFFB0B8C8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              emp.employeeCode!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB0B8C8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFD0D5E0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Pagination ───────────────────────────────────────────────────────────

  Widget _buildPagination() {
    final meta = _meta!;
    if (meta.lastPage <= 1) return const SizedBox.shrink();

    final pages = _buildPageNumbers(meta.currentPage, meta.lastPage);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Text(
            'Showing ${(meta.currentPage - 1) * meta.perPage + 1}–'
            '${(meta.currentPage * meta.perPage).clamp(0, meta.total)} '
            'of ${meta.total} Data',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8A94A6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pageBtn(
                child: const Icon(Icons.chevron_left_rounded, size: 18),
                enabled: meta.currentPage > 1,
                onTap: () => _fetchPage(meta.currentPage - 1),
                active: false,
              ),
              const SizedBox(width: 4),
              ...pages.map((p) {
                if (p == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '...',
                      style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _pageBtn(
                    child: Text(
                      '$p',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p == meta.currentPage
                            ? Colors.white
                            : const Color(0xFF5A6480),
                      ),
                    ),
                    enabled: true,
                    onTap: () => _fetchPage(p),
                    active: p == meta.currentPage,
                  ),
                );
              }),
              const SizedBox(width: 4),
              _pageBtn(
                child: const Icon(Icons.chevron_right_rounded, size: 18),
                enabled: meta.currentPage < meta.lastPage,
                onTap: () => _fetchPage(meta.currentPage + 1),
                active: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({
    required Widget child,
    required bool enabled,
    required VoidCallback onTap,
    required bool active,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF42A5F5) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(
              color: active
                  ? Colors.white
                  : enabled
                  ? const Color(0xFF5A6480)
                  : const Color(0xFFD0D5E0),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  List<int?> _buildPageNumbers(int current, int last) {
    if (last <= 7) return List.generate(last, (i) => i + 1);
    final show = <int>{1, last, current};
    if (current > 1) show.add(current - 1);
    if (current < last) show.add(current + 1);
    final sorted = show.toList()..sort();
    final result = <int?>[];
    for (int i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i]! - sorted[i - 1]! > 1) result.add(null);
      result.add(sorted[i]);
    }
    return result;
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F2F8),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: const Color(0xFFB0B8C8)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A6480),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Avatar ───────────────────────────────────────────────────────────────

  Widget _buildAvatar(String initial, String? photoUrl, double size) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(initial, size),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _buildInitialAvatar(initial, size),
        ),
      );
    }
    return _buildInitialAvatar(initial, size);
  }

  Widget _buildInitialAvatar(String initial, double size) {
    const palettes = [
      [Color(0xFFDCE8FF), Color(0xFF2B5FBF)],
      [Color(0xFFD5EDD5), Color(0xFF256325)],
      [Color(0xFFFFEDD5), Color(0xFFC45C0A)],
      [Color(0xFFEDD5FF), Color(0xFF7030A8)],
      [Color(0xFFD5F0FF), Color(0xFF0669A8)],
      [Color(0xFFFFD5D5), Color(0xFFA82B2B)],
      [Color(0xFFD5FFF0), Color(0xFF0A7A55)],
      [Color(0xFFFFEED5), Color(0xFFB86A00)],
    ];
    final idx = initial.isEmpty ? 0 : initial.codeUnitAt(0) % palettes.length;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palettes[idx][0],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: palettes[idx][1],
          ),
        ),
      ),
    );
  }
}
