import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/app_config.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/models/user_model.dart';
import 'package:http/http.dart' as http;

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

class _SearchSheet extends StatefulWidget {
  const _SearchSheet();

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  // ← TIDAK ada FocusNode auto-focus
  final ScrollController _scrollCtrl = ScrollController();

  String _query = '';
  bool _isLoading = false;

  List<UserModel> _users = [];
  _PaginationMeta? _meta;
  int _currentPage = 1;

  // Jabatan filter
  List<String> _allJabatan = [];
  List<String> _selectedJabatan = [];
  bool _loadingJabatan = false;

  // Kantor filter
  List<String> _allKantor = [];
  List<String> _selectedKantor = [];
  bool _loadingKantor = false;

  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _baseUrl = await AppConfig.getBaseUrl();
      _fetchPage(1); // langsung load data, TIDAK request focus
      _fetchJabatanList(); // load daftar jabatan untuk filter
      _fetchKantorList();
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

  Future<void> _fetchJabatanList() async {
    if (_baseUrl.isEmpty) return;
    setState(() => _loadingJabatan = true);
    try {
      final auth = Get.find<AuthController>();
      final res = await http.get(
        Uri.parse('$_baseUrl/user/jabatan-list'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${auth.token.value}',
        },
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          _allJabatan = List<String>.from(json['data']);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingJabatan = false);
    }
  }

  Future<void> _fetchKantorList() async {
    if (_baseUrl.isEmpty) return;
    setState(() => _loadingKantor = true);
    try {
      final auth = Get.find<AuthController>();
      final res = await http.get(
        Uri.parse('$_baseUrl/user/kantor-list'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${auth.token.value}',
        },
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          _allKantor = List<String>.from(json['data']);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingKantor = false);
    }
  }

  Future<void> _fetchPage(int page) async {
    if (_baseUrl.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final auth = Get.find<AuthController>();

      // Build query params — jabatan bisa multiple
      final params = <String, dynamic>{
        'page': '$page',
        'per_page': '20',
        if (_query.isNotEmpty) 'search': _query,
      };
      // Tambahkan jabatan[] jika ada yang dipilih
      final uri = Uri.parse('$_baseUrl/user/karyawan');
      final queryParts = <String>[];
      params.forEach((k, v) => queryParts.add('$k=${Uri.encodeComponent(v)}'));
      for (final j in _selectedJabatan) {
        queryParts.add('jabatan[]=${Uri.encodeComponent(j)}');
      }
      for (final k in _selectedKantor) {
        queryParts.add('kantor[]=${Uri.encodeComponent(k)}');
      }
      final finalUri = Uri.parse('${uri.toString()}?${queryParts.join('&')}');

      final res = await http.get(
        finalUri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${auth.token.value}',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = (json['data'] as List)
            .map((e) => UserModel.fromJson(e))
            .toList();
        final p = json['pagination'];

        setState(() {
          _users = list;
          _currentPage = page;
          _meta = _PaginationMeta(
            currentPage: p['current_page'],
            lastPage: p['last_page'],
            perPage: p['per_page'],
            total: p['total'],
          );
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    List<String> tempJabatan = List.from(_selectedJabatan);
    List<String> tempKantor = List.from(_selectedKantor);
    int activeTab = 0; // 0=Jabatan, 1=Kantor

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final bool isJabatanTab = activeTab == 0;
            final List<String> currentList = isJabatanTab
                ? _allJabatan
                : _allKantor;
            final List<String> currentSelected = isJabatanTab
                ? tempJabatan
                : tempKantor;
            final bool isLoadingCurrent = isJabatanTab
                ? _loadingJabatan
                : _loadingKantor;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollCtrl) {
                return Column(
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
                              onTap: () {
                                setLocal(() {
                                  if (isJabatanTab) {
                                    tempJabatan.clear();
                                  } else {
                                    tempKantor.clear();
                                  }
                                });
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE06020),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Tab Jabatan / Kantor
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _filterTab(
                            label: 'Jabatan',
                            count: tempJabatan.length,
                            isActive: activeTab == 0,
                            onTap: () => setLocal(() => activeTab = 0),
                          ),
                          const SizedBox(width: 8),
                          _filterTab(
                            label: 'Kantor',
                            count: tempKantor.length,
                            isActive: activeTab == 1,
                            onTap: () => setLocal(() => activeTab = 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    // List
                    Expanded(
                      child: isLoadingCurrent
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFE06020),
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
                                final bool checked = currentSelected.contains(
                                  item,
                                );
                                return InkWell(
                                  onTap: () {
                                    setLocal(() {
                                      if (checked) {
                                        currentSelected.remove(item);
                                      } else {
                                        currentSelected.add(item);
                                      }
                                    });
                                  },
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
                                                ? const Color(0xFFE06020)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            border: Border.all(
                                              color: checked
                                                  ? const Color(0xFFE06020)
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
                    // Bottom buttons
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
                                foregroundColor: const Color(0xFFE06020),
                                side: const BorderSide(
                                  color: Color(0xFFE06020),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () {
                                setLocal(() {
                                  tempJabatan.clear();
                                  tempKantor.clear();
                                });
                              },
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
                                backgroundColor: const Color(0xFFE06020),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _selectedJabatan = List.from(tempJabatan);
                                  _selectedKantor = List.from(tempKantor);
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
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper widget tab
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
          color: isActive ? const Color(0xFFE06020) : const Color(0xFFF2F4F7),
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
                      : const Color(0xFFE06020),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

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
    final bool hasActiveFilter =
        _selectedJabatan.isNotEmpty || _selectedKantor.isNotEmpty;
    final int totalFilter = _selectedJabatan.length + _selectedKantor.length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 20,
                  color: Color(0xFFE06020),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pencarian Karyawan',
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
                    // ← TIDAK ada focusNode
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1F36),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, NIK, jabatan, kantor...',
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
              // Filter button
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
                            ? const Color(0xFFE06020)
                            : const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasActiveFilter
                              ? const Color(0xFFE06020)
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
          // Active filter chips (scroll horizontal)
          if (_selectedJabatan.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 28,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedJabatan.length + _selectedKantor.length,
                itemBuilder: (_, i) {
                  final bool isJabatan = i < _selectedJabatan.length;
                  final String label = isJabatan
                      ? _selectedJabatan[i]
                      : _selectedKantor[i - _selectedJabatan.length];
                  final Color color = isJabatan
                      ? const Color(0xFFE06020)
                      : const Color(0xFF1565C0);
                  final Color bgColor = isJabatan
                      ? const Color(0xFFFFF0E6)
                      : const Color(0xFFEAF0FF);

                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
                          onTap: () {
                            setState(() {
                              if (isJabatan) {
                                _selectedJabatan.removeAt(i);
                              } else {
                                _selectedKantor.removeAt(
                                  i - _selectedJabatan.length,
                                );
                              }
                            });
                            _fetchPage(1);
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE06020),
          strokeWidth: 3,
        ),
      );
    }

    if (_users.isEmpty) {
      return _buildEmptyState(
        icon: _query.isEmpty && _selectedJabatan.isEmpty
            ? Icons.people_outline_rounded
            : Icons.search_off_rounded,
        title: _query.isEmpty && _selectedJabatan.isEmpty
            ? 'Tidak ada karyawan'
            : 'Tidak ditemukan',
        subtitle: _query.isEmpty && _selectedJabatan.isEmpty
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
                    ? 'Menampilkan ${_users.length} dari ${_meta!.total} karyawan'
                    : '${_users.length} karyawan',
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
            itemCount: _users.length,
            itemBuilder: (_, i) => _buildCard(_users[i]),
          ),
        ),
        if (_meta != null) _buildPagination(),
      ],
    );
  }

  Widget _buildPagination() {
    final meta = _meta!;
    if (meta.lastPage <= 1) return const SizedBox.shrink();

    final List<int?> pages = _buildPageNumbers(meta.currentPage, meta.lastPage);

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
          color: active ? const Color(0xFFE06020) : const Color(0xFFF2F4F7),
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
    final Set<int> show = {1, last, current};
    if (current > 1) show.add(current - 1);
    if (current < last) show.add(current + 1);
    final sorted = show.toList()..sort();
    final List<int?> result = [];
    for (int i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i]! - sorted[i - 1]! > 1) result.add(null);
      result.add(sorted[i]);
    }
    return result;
  }

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

  Widget _buildCard(UserModel user) {
    final String initial = user.name.isNotEmpty
        ? user.name[0].toUpperCase()
        : '?';

    final List<String> parts = [];
    if ((user.nik ?? '').isNotEmpty) parts.add(user.nik!);
    if ((user.jabatan ?? '').isNotEmpty) {
      parts.add(
        [
          user.jabatan!,
          if ((user.kantor ?? '').isNotEmpty) user.kantor!,
        ].join(' '),
      );
    }
    final String subtitle = parts.join(' · ');

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
            Navigator.pop(context); // tutup modal dulu
            // ← Navigate ke halaman profil karyawan
            Get.toNamed('/employee/profile', arguments: user);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildAvatar(initial, user.photoUrl, 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
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
                      if (user.email.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 11,
                              color: Color(0xFFB0B8C8),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFB0B8C8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
    const List<List<Color>> palettes = [
      [Color(0xFFDCE8FF), Color(0xFF2B5FBF)],
      [Color(0xFFD5EDD5), Color(0xFF256325)],
      [Color(0xFFFFEDD5), Color(0xFFC45C0A)],
      [Color(0xFFEDD5FF), Color(0xFF7030A8)],
      [Color(0xFFD5F0FF), Color(0xFF0669A8)],
      [Color(0xFFFFD5D5), Color(0xFFA82B2B)],
      [Color(0xFFD5FFF0), Color(0xFF0A7A55)],
      [Color(0xFFFFEED5), Color(0xFFB86A00)],
    ];
    final int idx = initial.isEmpty
        ? 0
        : initial.codeUnitAt(0) % palettes.length;
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
