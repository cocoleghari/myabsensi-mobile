import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/position_controller.dart';
import '../../../models/position_model.dart';

class PositionFormDialog extends StatefulWidget {
  final Position? position;
  final PositionController ctrl;

  const PositionFormDialog({super.key, this.position, required this.ctrl});

  @override
  State<PositionFormDialog> createState() => _PositionFormDialogState();
}

class _PositionFormDialogState extends State<PositionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController(
    text: widget.position?.name,
  );
  late final TextEditingController _code = TextEditingController(
    text: widget.position?.code,
  );
  late final TextEditingController _desc = TextEditingController(
    text: widget.position?.description,
  );
  late final TextEditingController _order = TextEditingController(
    text: widget.position?.order.toString() ?? '0',
  );

  late bool _isActive = widget.position?.isActive ?? true;
  int? _selectedCompanyId;
  bool _isSaving = false;

  bool get isEdit => widget.position != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      _selectedCompanyId = widget.position!.companyId;
    }

    if (widget.ctrl.companies.isEmpty) {
      widget.ctrl.fetchCompanies().then((_) {
        if (!isEdit && mounted) _tryAutoSelectCompany();
      });
    } else {
      if (!isEdit) _tryAutoSelectCompany();
    }
  }

  void _tryAutoSelectCompany() {
    if (widget.ctrl.companies.length == 1 && mounted) {
      setState(
        () => _selectedCompanyId = widget.ctrl.companies.first['id'] as int?,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _desc.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final data = {
      'company_id': _selectedCompanyId,
      'name': _name.text.trim(),
      'code': _code.text.trim().isEmpty ? null : _code.text.trim(),
      'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      'order': int.tryParse(_order.text) ?? 0,
      'is_active': _isActive,
    };

    bool ok = false;
    String? errorMsg;

    try {
      if (isEdit) {
        ok = await widget.ctrl.updatePosition(widget.position!.id, data);
      } else {
        ok = await widget.ctrl.createPosition(data);
      }
    } catch (e) {
      errorMsg = e.toString();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      Get.snackbar(
        'Berhasil',
        isEdit ? 'Posisi berhasil diperbarui' : 'Posisi berhasil dibuat',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      widget.ctrl.fetchPositions();
    } else if (errorMsg != null) {
      Get.snackbar(
        'Error',
        errorMsg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? 'Edit Posisi' : 'Tambah Posisi'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionLabel('Perusahaan'),
                _buildCompanyDropdown(),
                const SizedBox(height: 16),
                _buildSectionLabel('Informasi Posisi'),
                TextFormField(
                  controller: _name,
                  decoration: _inputDecoration(
                    'Nama Posisi *',
                    icon: Icons.work_outline,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _code,
                  decoration: _inputDecoration(
                    'Kode (opsional)',
                    hint: 'Misal: SE, SHR',
                    icon: Icons.tag,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  decoration: _inputDecoration('Deskripsi', icon: Icons.notes),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Pengaturan'),
                TextFormField(
                  controller: _order,
                  decoration: _inputDecoration('Urutan', icon: Icons.sort),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  title: const Text('Aktif'),
                  subtitle: const Text('Posisi dapat dipilih oleh karyawan'),
                  value: _isActive,
                  onChanged: _isSaving
                      ? null
                      : (v) => setState(() => _isActive = v),
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.indigo,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEdit ? 'Simpan' : 'Tambah',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  // ─── Dropdown ─────────────────────────────────────────────────────────────

  Widget _buildCompanyDropdown() {
    return Obx(() {
      final loading = widget.ctrl.isLoadingCompanies.value;
      final companies = widget.ctrl.companies;

      if (loading) return _loadingField('Memuat perusahaan...');
      if (companies.isEmpty) {
        return _warningField(
          'Tidak ada perusahaan. Tambahkan perusahaan terlebih dahulu.',
        );
      }
      if (companies.length == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_selectedCompanyId == null && mounted) {
            setState(() => _selectedCompanyId = companies.first['id'] as int?);
          }
        });
        return _readOnlyField(
          label: 'Perusahaan',
          value: companies.first['name']?.toString() ?? '-',
          icon: Icons.business,
        );
      }
      return DropdownButtonFormField<int>(
        value: _selectedCompanyId,
        decoration: _inputDecoration('Perusahaan *', icon: Icons.business),
        hint: const Text('Pilih perusahaan'),
        isExpanded: true,
        items: companies
            .map(
              (c) => DropdownMenuItem<int>(
                value: c['id'] as int?,
                child: Text(
                  c['name']?.toString() ?? '-',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => _selectedCompanyId = val),
        validator: (v) => v == null ? 'Perusahaan wajib dipilih' : null,
      );
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.indigo.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _loadingField(String label) {
    return InputDecorator(
      decoration: _inputDecoration(label),
      child: const SizedBox(height: 20, child: LinearProgressIndicator()),
    );
  }

  Widget _warningField(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Colors.orange.shade600,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo.shade400, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.indigo.shade400),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 14, color: Colors.indigo.shade300),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
