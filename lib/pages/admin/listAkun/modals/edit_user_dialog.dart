import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/user_controller.dart';
import 'package:myabsensi_mobile/models/user_model.dart';

class EditUserDialog extends StatefulWidget {
  final UserModel user;
  final UserController userController;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.userController,
  });

  static Future<void> show({
    required BuildContext context,
    required UserModel user,
    required UserController userController,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditUserDialog(
        user: user,
        userController: userController,
      ),
    );
  }

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();

  late String _selectedRole;
  late bool _isActive;
  bool _showPassword = false;

  static const _roles = [
    'superadmin',
    'admin',
    'hrd',
    'manager',
    'employee',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.user.name);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive == true || widget.user.isActive == 1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── warna per role ────────────────────────────────────────────────────
  Color _roleBg(String role) {
    switch (role) {
      case 'superadmin':
      case 'admin':   return Colors.purple.shade50;
      case 'hrd':     return Colors.teal.shade50;
      case 'manager': return Colors.orange.shade50;
      default:        return Colors.blue.shade50;
    }
  }

  Color _roleFg(String role) {
    switch (role) {
      case 'superadmin':
      case 'admin':   return Colors.purple.shade800;
      case 'hrd':     return Colors.teal.shade800;
      case 'manager': return Colors.orange.shade800;
      default:        return Colors.blue.shade800;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    widget.userController.updateUser(
      id:       widget.user.id,
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      role:     _selectedRole,
      isActive: _isActive,
      password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inisial avatar dari nama
    final initials = widget.user.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      titlePadding: EdgeInsets.zero,
      title: _buildHeader(initials),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              _buildNameField(),
              const SizedBox(height: 12),
              _buildEmailField(),
              const SizedBox(height: 12),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildRoleSelector(),
              const SizedBox(height: 16),
              _buildActiveToggle(),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Batal'),
        ),
        Obx(() => ElevatedButton(
          onPressed: widget.userController.isLoading.value ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: widget.userController.isLoading.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        )),
      ],
    );
  }

  // ── header dengan avatar ──────────────────────────────────────────────
  Widget _buildHeader(String initials) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade200,
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit akun',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.user.email,
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── field nama ────────────────────────────────────────────────────────
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: const InputDecoration(
        labelText: 'Nama',
        prefixIcon: Icon(Icons.person_outline, size: 18),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
    );
  }

  // ── field email ───────────────────────────────────────────────────────
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email_outlined, size: 18),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
        if (!GetUtils.isEmail(v.trim())) return 'Format email tidak valid';
        return null;
      },
    );
  }

  // ── field password (opsional) ─────────────────────────────────────────
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: !_showPassword,
      decoration: InputDecoration(
        labelText: 'Password baru (opsional)',
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
            size: 18,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        border: const OutlineInputBorder(),
        isDense: true,
        helperText: 'Kosongkan jika tidak ingin mengubah password',
        helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
      validator: (v) {
        if (v != null && v.isNotEmpty && v.length < 8) {
          return 'Password minimal 8 karakter';
        }
        return null;
      },
    );
  }

  // ── selector role (chip-style) ────────────────────────────────────────
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
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
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected ? _roleBg(role) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? _roleFg(role)
                        : Colors.grey.shade300,
                    width: selected ? 1.5 : 0.5,
                  ),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? _roleFg(role) : Colors.grey.shade500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── toggle status aktif ───────────────────────────────────────────────
  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: _isActive ? Colors.green : Colors.red.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Status akun: ${_isActive ? "Aktif" : "Nonaktif"}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Switch(
            value: _isActive,
            activeColor: Colors.green,
            onChanged: (val) => setState(() => _isActive = val),
          ),
        ],
      ),
    );
  }
}