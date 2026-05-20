import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/user_controller.dart';

class TambahUserModal extends StatefulWidget {
  final UserController userController;

  const TambahUserModal({super.key, required this.userController});

  static void show(BuildContext context, UserController userController) {
    Get.bottomSheet(
      TambahUserModal(userController: userController),
      isScrollControlled: true,
      enableDrag: false,
    );
  }

  @override
  State<TambahUserModal> createState() => _TambahUserModalState();
}

class _TambahUserModalState extends State<TambahUserModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmPassC = TextEditingController();

  String _selectedRole = 'employee';
  bool _showPass = false;
  bool _showConfirmPass = false;

  static const _roles = ['superadmin', 'admin', 'hrd', 'manager', 'employee'];

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    _confirmPassC.dispose();
    super.dispose();
  }

  // ── warna per role ────────────────────────────────────────────────────
  Color _roleBg(String role) {
    switch (role) {
      case 'superadmin':
      case 'admin':
        return Colors.purple.shade50;
      case 'hrd':
        return Colors.teal.shade50;
      case 'manager':
        return Colors.orange.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Color _roleFg(String role) {
    switch (role) {
      case 'superadmin':
      case 'admin':
        return Colors.purple.shade800;
      case 'hrd':
        return Colors.teal.shade800;
      case 'manager':
        return Colors.orange.shade800;
      default:
        return Colors.blue.shade800;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'superadmin':
        return Icons.star;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'hrd':
        return Icons.people;
      case 'manager':
        return Icons.business_center;
      default:
        return Icons.person;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Tutup bottom sheet lalu tampilkan dialog konfirmasi
    Get.back();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            children: [
              const TextSpan(text: 'Daftarkan akun '),
              TextSpan(
                text: _nameC.text.trim(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' sebagai '),
              TextSpan(
                text: _selectedRole,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _roleFg(_selectedRole),
                ),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              widget.userController.registerUser(
                name: _nameC.text.trim(),
                email: _emailC.text.trim(),
                password: _passC.text,
                role: _selectedRole,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ya, Daftarkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildNameField(),
              const SizedBox(height: 14),
              _buildEmailField(),
              const SizedBox(height: 14),
              _buildPasswordField(),
              const SizedBox(height: 14),
              _buildConfirmPasswordField(),
              const SizedBox(height: 20),
              _buildRoleSelector(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 10),
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── handle bar ────────────────────────────────────────────────────────
  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 50,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_add, color: Colors.blue, size: 24),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Akun Baru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Isi data dengan lengkap dan pilih role',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── field nama ────────────────────────────────────────────────────────
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameC,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Nama Lengkap',
        hintText: 'Masukkan nama lengkap',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        prefixIcon: const Icon(Icons.person, color: Colors.blue),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
    );
  }

  // ── field email ───────────────────────────────────────────────────────
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailC,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'contoh@email.com',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        prefixIcon: const Icon(Icons.email, color: Colors.blue),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
        if (!GetUtils.isEmail(v.trim())) return 'Format email tidak valid';
        return null;
      },
    );
  }

  // ── field password ────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passC,
      obscureText: !_showPass,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Minimal 8 karakter',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        prefixIcon: const Icon(Icons.lock, color: Colors.blue),
        suffixIcon: IconButton(
          icon: Icon(
            _showPass ? Icons.visibility_off : Icons.visibility,
            size: 18,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _showPass = !_showPass),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password wajib diisi';
        if (v.length < 8) return 'Password minimal 8 karakter';
        return null;
      },
    );
  }

  // ── field konfirmasi password ─────────────────────────────────────────
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPassC,
      obscureText: !_showConfirmPass,
      decoration: InputDecoration(
        labelText: 'Konfirmasi Password',
        hintText: 'Ulangi password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
        suffixIcon: IconButton(
          icon: Icon(
            _showConfirmPass ? Icons.visibility_off : Icons.visibility,
            size: 18,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _showConfirmPass = !_showConfirmPass),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
        if (v != _passC.text) return 'Password tidak cocok';
        return null;
      },
    );
  }

  // ── selector role ─────────────────────────────────────────────────────
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _roles.map((role) {
            final selected = _selectedRole == role;
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? _roleBg(role) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _roleFg(role) : Colors.grey.shade300,
                    width: selected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _roleIcon(role),
                      size: 14,
                      color: selected ? _roleFg(role) : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? _roleFg(role) : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── tombol submit ─────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.userController.isLoading.value ? null : _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
          ),
          child: widget.userController.isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'DAFTARKAN AKUN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  // ── tombol batal ──────────────────────────────────────────────────────
  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Get.back(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }
}
