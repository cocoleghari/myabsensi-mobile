import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/job_level_controller.dart'; // sesuaikan path

class JobLevelFormPage extends StatelessWidget {
  const JobLevelFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<JobLevelController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Obx(
          () => Text(
            c.editingId.value == null ? 'Tambah Job Level' : 'Edit Job Level',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: c.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card: Informasi Utama ──────────────────────────────────────
              _SectionCard(
                title: 'Informasi Utama',
                icon: Icons.layers_outlined,
                iconColor: Colors.teal.shade700,
                children: [
                  // Perusahaan
                  _FieldLabel(label: 'Perusahaan', required: true),
                  const SizedBox(height: 8),
                  Obx(() {
                    if (c.companies.isEmpty) {
                      return _LoadingField(
                        label: 'Memuat daftar perusahaan...',
                      );
                    }
                    return DropdownButtonFormField<int?>(
                      value: c.formCompanyId.value,
                      decoration: _inputDecoration(
                        hint: 'Pilih perusahaan',
                        prefix: const Icon(Icons.business_outlined),
                      ),
                      items: c.companies
                          .map(
                            (company) => DropdownMenuItem(
                              value: company['id'] as int?,
                              child: Text(company['name'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => c.formCompanyId.value = val,
                      validator: (val) =>
                          val == null ? 'Perusahaan wajib dipilih' : null,
                    );
                  }),

                  const SizedBox(height: 16),

                  // Nama
                  _FieldLabel(label: 'Nama Level', required: true),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: c.nameController,
                    decoration: _inputDecoration(
                      hint: 'cth: Staff, Supervisor, Manager, Director',
                      prefix: const Icon(Icons.layers_outlined),
                    ),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Card: Detail Tambahan ──────────────────────────────────────
              _SectionCard(
                title: 'Detail Tambahan',
                icon: Icons.tune,
                iconColor: Colors.teal.shade700,
                children: [
                  // Deskripsi
                  _FieldLabel(label: 'Deskripsi'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: c.descriptionController,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      hint: 'Deskripsi singkat level ini (opsional)',
                    ).copyWith(contentPadding: const EdgeInsets.all(16)),
                  ),

                  const SizedBox(height: 16),

                  // Order & Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Urutan Tampil'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: c.orderController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                hint: '0',
                                prefix: const Icon(Icons.sort),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Status Aktif'),
                            const SizedBox(height: 8),
                            Obx(
                              () => GestureDetector(
                                onTap: () => c.formIsActive.value =
                                    !c.formIsActive.value,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: c.formIsActive.value
                                        ? Colors.teal.shade50
                                        : Colors.grey.shade50,
                                    border: Border.all(
                                      color: c.formIsActive.value
                                          ? Colors.teal.shade300
                                          : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 14,
                                        ),
                                        child: Text(
                                          c.formIsActive.value
                                              ? 'Aktif'
                                              : 'Nonaktif',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: c.formIsActive.value
                                                ? Colors.teal.shade700
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      Transform.scale(
                                        scale: 0.85,
                                        child: Switch(
                                          value: c.formIsActive.value,
                                          activeColor: Colors.teal.shade600,
                                          onChanged: (v) =>
                                              c.formIsActive.value = v,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Submit Button ─────────────────────────────────────────────
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: c.isSubmitting.value ? null : c.submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.teal.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    icon: c.isSubmitting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            c.editingId.value == null
                                ? Icons.save_outlined
                                : Icons.update,
                          ),
                    label: Text(
                      c.isSubmitting.value
                          ? 'Menyimpan...'
                          : c.editingId.value == null
                          ? 'Simpan Job Level'
                          : 'Perbarui Job Level',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
InputDecoration _inputDecoration({String? hint, Widget? prefix}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: prefix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.teal.shade400, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _LoadingField extends StatelessWidget {
  final String label;
  const _LoadingField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.teal.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: 14,
        ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red.shade400),
                ),
              ]
            : [],
      ),
    );
  }
}
