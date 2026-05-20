import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/department_controller.dart';

class DepartmentFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const DepartmentFormDialog({super.key, this.existing});

  @override
  State<DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<DepartmentFormDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController codeCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController orderCtrl;
  late final RxBool isActive;
  late final Rxn<int> selectedCompanyId;
  late final Rxn<int> selectedParentId;
  late final Rxn<int> selectedManagerId;
  late final Rx<String> selectedManagerName;

  final formKey = GlobalKey<FormState>();
  late final DepartmentController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<DepartmentController>();

    final e = widget.existing;
    nameCtrl = TextEditingController(text: e?['name'] ?? '');
    codeCtrl = TextEditingController(text: e?['code'] ?? '');
    descCtrl = TextEditingController(text: e?['description'] ?? '');
    orderCtrl = TextEditingController(text: (e?['order'] ?? 0).toString());

    isActive = RxBool(e?['is_active'] == true || e?['is_active'] == 1);
    selectedCompanyId = Rxn<int>(e?['company_id'] as int?);
    selectedParentId = Rxn<int>(e?['parent_id'] as int?);
    selectedManagerId = Rxn<int>(e?['manager_id'] as int?);
    selectedManagerName = Rx<String>(
      e?['manager']?['full_name']?.toString() ?? '',
    );

    if (ctrl.employeesDropdown.isEmpty) {
      ctrl.fetchEmployeesDropdown();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    descCtrl.dispose();
    orderCtrl.dispose();
    super.dispose();
  }

  // ── Searchable Manager Picker ─────────────────────────────────────────────

  Future<void> _openManagerPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManagerPickerSheet(
        ctrl: ctrl,
        selectedCompanyId: selectedCompanyId,
        selectedManagerId: selectedManagerId,
        selectedManagerName: selectedManagerName,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_tree,
                      color: Colors.deepPurple.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Department' : 'Tambah Department',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Company ──────────────────────────────────────
              _fieldLabel('Company *'),
              Obx(() {
                if (ctrl.isLoadingCompanies.value) return _loadingBox();
                if (ctrl.companies.isEmpty) {
                  return _emptyBox('Tidak ada company tersedia');
                }
                return DropdownButtonFormField<int>(
                  value: selectedCompanyId.value,
                  decoration: _inputDec('Pilih Company'),
                  isExpanded: true,
                  hint: const Text('Pilih Company'),
                  items: ctrl.companies.map((c) {
                    final id = c['id'] as int;
                    final name = c['name']?.toString() ?? '-';
                    final code = c['code']?.toString();
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.business,
                              size: 14,
                              color: Colors.deepPurple.shade400,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              code != null ? '$name ($code)' : name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    selectedCompanyId.value = v;
                    selectedParentId.value = null;
                    selectedManagerId.value = null;
                    selectedManagerName.value = '';
                  },
                  validator: (v) => v == null ? 'Company wajib dipilih' : null,
                );
              }),
              const SizedBox(height: 14),

              // ── Parent Department ────────────────────────────
              _fieldLabel('Parent Department (opsional)'),
              Obx(() {
                final parents = ctrl.departments.where((d) {
                  if (d['id'] == widget.existing?['id']) return false;
                  if (selectedCompanyId.value != null &&
                      d['company_id'] != selectedCompanyId.value) {
                    return false;
                  }
                  return true;
                }).toList();

                return DropdownButtonFormField<int?>(
                  value: selectedParentId.value,
                  decoration: _inputDec('Pilih Parent (kosongkan jika root)'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('— Tidak ada (Root) —'),
                    ),
                    ...parents.map(
                      (d) => DropdownMenuItem<int?>(
                        value: d['id'] as int,
                        child: Text(
                          d['name'] ?? '-',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => selectedParentId.value = v,
                );
              }),
              const SizedBox(height: 14),

              // ── Manajer ──────────────────────────────────────
              _fieldLabel('Manajer Department (opsional)'),
              Obx(() {
                if (ctrl.isLoadingEmployeesDropdown.value) {
                  return _loadingBox();
                }
                final hasManager = selectedManagerId.value != null;
                final managerLabel = hasManager
                    ? (selectedManagerName.value.isNotEmpty
                          ? selectedManagerName.value
                          : 'ID: ${selectedManagerId.value}')
                    : 'Ketuk untuk memilih manajer...';

                return GestureDetector(
                  onTap: () => _openManagerPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(
                        color: hasManager
                            ? Colors.deepPurple.shade200
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: hasManager
                                ? Colors.deepPurple.shade50
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasManager ? Icons.person : Icons.person_add_alt,
                            size: 15,
                            color: hasManager
                                ? Colors.deepPurple.shade400
                                : Colors.grey.shade400,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            managerLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: hasManager
                                  ? Colors.black87
                                  : Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasManager)
                          GestureDetector(
                            onTap: () {
                              selectedManagerId.value = null;
                              selectedManagerName.value = '';
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.search,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 14),

              // ── Nama ─────────────────────────────────────────
              _fieldLabel('Nama Department *'),
              TextFormField(
                controller: nameCtrl,
                decoration: _inputDec('Contoh: Engineering'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // ── Kode ─────────────────────────────────────────
              _fieldLabel('Kode'),
              TextFormField(
                controller: codeCtrl,
                decoration: _inputDec('Contoh: ENG'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 14),

              // ── Deskripsi ─────────────────────────────────────
              _fieldLabel('Deskripsi'),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: _inputDec('Deskripsi singkat...'),
              ),
              const SizedBox(height: 14),

              // ── Urutan ────────────────────────────────────────
              _fieldLabel('Urutan Tampil'),
              TextFormField(
                controller: orderCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDec('0'),
              ),
              const SizedBox(height: 14),

              // ── Status aktif ──────────────────────────────────
              Obx(
                () => SwitchListTile(
                  value: isActive.value,
                  onChanged: (v) => isActive.value = v,
                  title: const Text('Status Aktif'),
                  activeColor: Colors.deepPurple,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 20),

              // ── Actions ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => ElevatedButton(
                      onPressed: ctrl.isSaving.value
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final body = <String, dynamic>{
                                'company_id': selectedCompanyId.value,
                                'parent_id': selectedParentId.value,
                                'manager_id': selectedManagerId.value,
                                'name': nameCtrl.text.trim(),
                                'code': codeCtrl.text.trim().isEmpty
                                    ? null
                                    : codeCtrl.text.trim(),
                                'description': descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                                'order': int.tryParse(orderCtrl.text) ?? 0,
                                'is_active': isActive.value,
                              };
                              final ok = isEdit
                                  ? await ctrl.updateDepartment(
                                      widget.existing!['id'] as int,
                                      body,
                                    )
                                  : await ctrl.createDepartment(body);
                              if (ok && mounted) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: ctrl.isSaving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEdit ? 'Simpan' : 'Tambah'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingBox() => Container(
    height: 50,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(10),
      color: Colors.grey.shade50,
    ),
    child: const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );

  Widget _emptyBox(String message) => Container(
    height: 50,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(10),
      color: Colors.grey.shade50,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.warning_amber_outlined,
          size: 16,
          color: Colors.orange.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          message,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    ),
  );

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGER PICKER SHEET — StatefulWidget terpisah dengan pagination lokal
// Mencegah ANR karena tidak merender 1000+ item sekaligus
// ─────────────────────────────────────────────────────────────────────────────

class _ManagerPickerSheet extends StatefulWidget {
  final DepartmentController ctrl;
  final Rxn<int> selectedCompanyId;
  final Rxn<int> selectedManagerId;
  final Rx<String> selectedManagerName;

  const _ManagerPickerSheet({
    required this.ctrl,
    required this.selectedCompanyId,
    required this.selectedManagerId,
    required this.selectedManagerName,
  });

  @override
  State<_ManagerPickerSheet> createState() => _ManagerPickerSheetState();
}

class _ManagerPickerSheetState extends State<_ManagerPickerSheet> {
  static const int _pageSize = 30; // render 30 item per batch

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _allFiltered = [];
  List<Map<String, dynamic>> _visible = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _buildFiltered('');
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Bangun list hasil filter dari semua data, lalu tampilkan batch pertama.
  void _buildFiltered(String q) {
    final source = widget.selectedCompanyId.value == null
        ? widget.ctrl.employeesDropdown.toList()
        : widget.ctrl.employeesDropdown
              .where((e) => e['company_id'] == widget.selectedCompanyId.value)
              .toList();

    final query = q.trim().toLowerCase();
    _allFiltered = query.isEmpty
        ? source
        : source.where((emp) {
            final name = (emp['full_name'] ?? '').toString().toLowerCase();
            final code = (emp['employee_code'] ?? '').toString().toLowerCase();
            return name.contains(query) || code.contains(query);
          }).toList();

    // Tampilkan batch pertama saja
    _visible = _allFiltered.take(_pageSize).toList();
  }

  /// Saat scroll mendekati bawah, tambah batch berikutnya.
  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (_visible.length < _allFiltered.length) {
        setState(() {
          _isLoadingMore = true;
          final next = _allFiltered
              .skip(_visible.length)
              .take(_pageSize)
              .toList();
          _visible.addAll(next);
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearch(String q) {
    setState(() => _buildFiltered(q));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, __) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Judul
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      color: Colors.deepPurple.shade400,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pilih Manajer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_allFiltered.length} karyawan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau kode karyawan...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    isDense: true,
                  ),
                  onChanged: _onSearch,
                ),
              ),
              const SizedBox(height: 4),

              // Opsi kosongkan
              ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_off_outlined,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
                title: Text(
                  '— Tidak ada manajer —',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                onTap: () {
                  widget.selectedManagerId.value = null;
                  widget.selectedManagerName.value = '';
                  Navigator.of(context).pop();
                },
              ),
              Divider(height: 1, color: Colors.grey.shade100),

              // List dengan pagination lokal
              Expanded(
                child: _visible.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _searchCtrl.text.isNotEmpty
                                  ? 'Tidak ada hasil pencarian'
                                  : 'Tidak ada karyawan tersedia',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        // +1 untuk footer loading
                        itemCount:
                            _visible.length +
                            (_visible.length < _allFiltered.length ? 1 : 0),
                        itemBuilder: (_, i) {
                          // Footer loading indicator
                          if (i == _visible.length) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final emp = _visible[i];
                          final empId = emp['id'] as int;
                          final empName = emp['full_name']?.toString() ?? '-';
                          final empCode =
                              emp['employee_code']?.toString() ?? '';
                          final photoUrl = emp['photo_url']?.toString();
                          final initials = empName
                              .split(' ')
                              .take(2)
                              .map(
                                (w) => w.isNotEmpty ? w[0].toUpperCase() : '',
                              )
                              .join();

                          return Obx(() {
                            final isSelected =
                                widget.selectedManagerId.value == empId;
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.deepPurple.shade50,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.deepPurple.shade50,
                                backgroundImage:
                                    (photoUrl != null && photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: (photoUrl == null || photoUrl.isEmpty)
                                    ? Text(
                                        initials,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple.shade400,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                empName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: empCode.isNotEmpty
                                  ? Text(
                                      empCode,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    )
                                  : null,
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Colors.deepPurple.shade400,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () {
                                widget.selectedManagerId.value = empId;
                                widget.selectedManagerName.value = empName;
                                Navigator.of(context).pop();
                              },
                            );
                          });
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
