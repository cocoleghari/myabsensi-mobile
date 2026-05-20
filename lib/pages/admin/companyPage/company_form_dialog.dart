import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/company_controller.dart';

class CompanyFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const CompanyFormDialog({super.key, this.existing});

  @override
  State<CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends State<CompanyFormDialog> {
  late final CompanyController ctrl;

  late final TextEditingController nameCtrl;
  late final TextEditingController legalNameCtrl;
  late final TextEditingController codeCtrl;
  late final TextEditingController industryCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController npwpCtrl;
  late final TextEditingController nibCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController websiteCtrl;
  late final TextEditingController addressCtrl;
  late final TextEditingController cityCtrl;
  late final TextEditingController provinceCtrl;
  late final TextEditingController postalCtrl;
  late final TextEditingController clockInCtrl;
  late final TextEditingController clockOutCtrl;

  late bool isActive;
  late String selectedWorkDays;

  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // ✅ Get.find — pakai instance yang sudah ada dari CompanyPage
    ctrl = Get.find<CompanyController>();
    final e = widget.existing;

    nameCtrl = TextEditingController(text: e?['name'] ?? '');
    legalNameCtrl = TextEditingController(text: e?['legal_name'] ?? '');
    codeCtrl = TextEditingController(text: e?['code'] ?? '');
    industryCtrl = TextEditingController(text: e?['industry'] ?? '');
    descCtrl = TextEditingController(text: e?['description'] ?? '');
    npwpCtrl = TextEditingController(text: e?['npwp'] ?? '');
    nibCtrl = TextEditingController(text: e?['nib'] ?? '');
    emailCtrl = TextEditingController(text: e?['email'] ?? '');
    phoneCtrl = TextEditingController(text: e?['phone'] ?? '');
    websiteCtrl = TextEditingController(text: e?['website'] ?? '');
    addressCtrl = TextEditingController(text: e?['address'] ?? '');
    cityCtrl = TextEditingController(text: e?['city'] ?? '');
    provinceCtrl = TextEditingController(text: e?['province'] ?? '');
    postalCtrl = TextEditingController(text: e?['postal_code'] ?? '');
    clockInCtrl = TextEditingController(
      text: _formatTime(e?['default_clock_in'] ?? '08:00'),
    );
    clockOutCtrl = TextEditingController(
      text: _formatTime(e?['default_clock_out'] ?? '17:00'),
    );

    isActive = e?['is_active'] == true || e?['is_active'] == 1;
    selectedWorkDays = e?['work_days']?.toString() ?? '5';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    legalNameCtrl.dispose();
    codeCtrl.dispose();
    industryCtrl.dispose();
    descCtrl.dispose();
    npwpCtrl.dispose();
    nibCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    websiteCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    provinceCtrl.dispose();
    postalCtrl.dispose();
    clockInCtrl.dispose();
    clockOutCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    final name = nameCtrl.text.trim();
    final code = codeCtrl.text.trim();
    if (name.isEmpty || code.isEmpty) {
      Get.snackbar(
        'Error',
        'Nama dan Kode wajib diisi',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final body = <String, dynamic>{
      'name': name,
      'legal_name': legalNameCtrl.text.trim().isEmpty
          ? null
          : legalNameCtrl.text.trim(),
      'code': code,
      'industry': industryCtrl.text.trim().isEmpty
          ? null
          : industryCtrl.text.trim(),
      'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      'npwp': npwpCtrl.text.trim().isEmpty ? null : npwpCtrl.text.trim(),
      'nib': nibCtrl.text.trim().isEmpty ? null : nibCtrl.text.trim(),
      'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      'website': websiteCtrl.text.trim().isEmpty
          ? null
          : websiteCtrl.text.trim(),
      'address': addressCtrl.text.trim().isEmpty
          ? null
          : addressCtrl.text.trim(),
      'city': cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(),
      'province': provinceCtrl.text.trim().isEmpty
          ? null
          : provinceCtrl.text.trim(),
      'postal_code': postalCtrl.text.trim().isEmpty
          ? null
          : postalCtrl.text.trim(),
      'work_days': selectedWorkDays,
      'default_clock_in': clockInCtrl.text.trim(),
      'default_clock_out': clockOutCtrl.text.trim(),
      'is_active': isActive,
    };

    final isEdit = widget.existing != null;
    bool ok = false;

    try {
      ok = isEdit
          ? await ctrl.updateCompany(widget.existing!['id'] as int, body)
          : await ctrl.createCompany(body);
    } catch (e) {
      ok = false;
    }

    if (!mounted) return;

    if (ok) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context, rootNavigator: true).pop();
      });
    }
  }

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
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.business, color: Colors.teal.shade400),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Company' : 'Tambah Company',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Identitas ────────────────────────────────────
              _sectionHeader('Identitas Perusahaan'),

              _fieldLabel('Nama Perusahaan *'),
              TextFormField(
                controller: nameCtrl,
                decoration: _inputDec('Contoh: PT Maju Bersama'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              _fieldLabel('Nama Legal'),
              TextFormField(
                controller: legalNameCtrl,
                decoration: _inputDec('Sesuai akta'),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Kode *'),
                        TextFormField(
                          controller: codeCtrl,
                          decoration: _inputDec('PT-ABC'),
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Kode wajib diisi'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Industri'),
                        TextFormField(
                          controller: industryCtrl,
                          decoration: _inputDec('Teknologi'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _fieldLabel('Deskripsi'),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: _inputDec('Deskripsi singkat...'),
              ),
              const SizedBox(height: 20),

              // ── Legalitas ────────────────────────────────────
              _sectionHeader('Legalitas'),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('NPWP'),
                        TextFormField(
                          controller: npwpCtrl,
                          decoration: _inputDec('XX.XXX.XXX.X-XXX.XXX'),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('NIB'),
                        TextFormField(
                          controller: nibCtrl,
                          decoration: _inputDec('Nomor Induk Berusaha'),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Kontak ───────────────────────────────────────
              _sectionHeader('Kontak'),

              _fieldLabel('Email'),
              TextFormField(
                controller: emailCtrl,
                decoration: _inputDec('info@perusahaan.com'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v != null &&
                      v.trim().isNotEmpty &&
                      !GetUtils.isEmail(v.trim())) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Telepon'),
                        TextFormField(
                          controller: phoneCtrl,
                          decoration: _inputDec('021-XXXXXXX'),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Website'),
                        TextFormField(
                          controller: websiteCtrl,
                          decoration: _inputDec('https://...'),
                          keyboardType: TextInputType.url,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Lokasi ───────────────────────────────────────
              _sectionHeader('Lokasi'),

              _fieldLabel('Alamat'),
              TextFormField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: _inputDec('Jl. ...'),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Kota'),
                        TextFormField(
                          controller: cityCtrl,
                          decoration: _inputDec('Jakarta'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Provinsi'),
                        TextFormField(
                          controller: provinceCtrl,
                          decoration: _inputDec('DKI Jakarta'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Kode Pos'),
                        TextFormField(
                          controller: postalCtrl,
                          decoration: _inputDec('12345'),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Konfigurasi HRIS ─────────────────────────────
              _sectionHeader('Konfigurasi HRIS'),

              _fieldLabel('Hari Kerja per Minggu'),
              Row(
                children: [
                  _workDayChip('5', '5 Hari'),
                  const SizedBox(width: 10),
                  _workDayChip('6', '6 Hari'),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Jam Masuk'),
                        TextFormField(
                          controller: clockInCtrl,
                          decoration: _inputDec('08:00'),
                          keyboardType: TextInputType.datetime,
                          validator: _validateTime,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Jam Keluar'),
                        TextFormField(
                          controller: clockOutCtrl,
                          decoration: _inputDec('17:00'),
                          keyboardType: TextInputType.datetime,
                          validator: _validateTime,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              SwitchListTile(
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
                title: const Text('Status Aktif'),
                activeColor: Colors.teal,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),

              // ── Actions ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(
                    () => TextButton(
                      onPressed: ctrl.isSaving.value ? null : () => Get.back(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => ElevatedButton(
                      onPressed: ctrl.isSaving.value ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
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

  // ── Helpers ────────────────────────────────────────────────

  String? _validateTime(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final parts = v.trim().split(':');
    if (parts.length != 2) return 'Format HH:mm';
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) return 'Format HH:mm';
    return null;
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.teal,
          ),
        ),
      ],
    ),
  );

  Widget _workDayChip(String value, String label) {
    final isSelected = selectedWorkDays == value;
    return GestureDetector(
      onTap: () => setState(() => selectedWorkDays = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

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

  // Tambahkan helper function ini
  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return raw;
  }
}
