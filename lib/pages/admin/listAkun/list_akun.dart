import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/user_controller.dart';
import 'package:myabsensi_mobile/pages/admin/listAkun/widget/akun_action_buttons.dart';
import 'package:myabsensi_mobile/pages/admin/listAkun/widget/akun_header_widget.dart';
import 'package:myabsensi_mobile/pages/admin/listAkun/widget/akun_info_card.dart';
import 'package:myabsensi_mobile/pages/admin/listAkun/widget/akun_table_widget.dart';
import 'package:myabsensi_mobile/pages/admin/master_drawer.dart';
import 'package:get/get.dart';

class ListAkunPage extends GetView<AuthController> {
  const ListAkunPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      userController.fetchUsers();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'List Akun',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Get.defaultDialog(
                title: 'Konfirmasi Logout',
                middleText: 'Yakin ingin logout?',
                textCancel: 'Batal',
                textConfirm: 'Logout',
                confirmTextColor: Colors.white,
                buttonColor: Colors.red,
                onConfirm: () {
                  Get.back();
                  controller.logout();
                },
              );
            },
          ),
        ],
      ),
      drawer: const MasterDrawer(currentPage: 'admin'),
      body: Obx(() {
        if (userController.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memuat data...'),
              ],
            ),
          );
        }

        // Hitung jumlah admin dan user
        final int totalUsers = userController.users.length;
        final int totalAdmins = userController.users
            .where((u) => u.role == 'admin')
            .length;
        final int totalRegularUsers = userController.users
            .where((u) => u.role == 'user')
            .length;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header dengan statistik
                AkunHeaderWidget(
                  totalUsers: totalUsers,
                  totalAdmins: totalAdmins,
                  totalRegularUsers: totalRegularUsers,
                ),

                // Tabel Data User
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: AkunTableWidget(userController: userController),
                  ),
                ),

                // Tombol Aksi dan Info Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AkunActionButtons(
                        userController: userController,
                        onTambahUser: () =>
                            _showTambahUserModal(context, userController),
                      ),
                      const SizedBox(height: 10),
                      const AkunInfoCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showTambahUserModal(
    BuildContext context,
    UserController userController,
  ) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();
    final confirmPassC = TextEditingController();
    final selectedRole = 'user'.obs; // Default role: user
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah User / Admin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Isi data dengan lengkap',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form Fields
                TextFormField(
                  controller: nameC,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Masukkan nama lengkap',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    if (value.length < 3) {
                      return 'Nama minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: emailC,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'contoh@email.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: passC,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Minimal 6 karakter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: confirmPassC,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    hintText: 'Ulangi password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.blue,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password wajib diisi';
                    }
                    if (value != passC.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ===== PILIHAN ROLE =====
                const Text(
                  'Pilih Role',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _buildRoleOption(
                          title: 'User',
                          value: 'user',
                          groupValue: selectedRole.value,
                          icon: Icons.person,
                          color: Colors.blue,
                          onChanged: (value) => selectedRole.value = value,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoleOption(
                          title: 'Admin',
                          value: 'admin',
                          groupValue: selectedRole.value,
                          icon: Icons.admin_panel_settings,
                          color: Colors.purple,
                          onChanged: (value) => selectedRole.value = value,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Informasi Role berdasarkan pilihan
                Obx(
                  () => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedRole.value == 'user'
                          ? Colors.blue.shade50
                          : Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selectedRole.value == 'user'
                            ? Colors.blue.shade200
                            : Colors.purple.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedRole.value == 'user'
                              ? Icons.person
                              : Icons.admin_panel_settings,
                          color: selectedRole.value == 'user'
                              ? Colors.blue
                              : Colors.purple,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedRole.value == 'user'
                                    ? 'Role: USER'
                                    : 'Role: ADMIN',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: selectedRole.value == 'user'
                                      ? Colors.blue
                                      : Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                selectedRole.value == 'user'
                                    ? 'User hanya dapat mengakses fitur terbatas'
                                    : 'Admin dapat mengelola semua fitur',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selectedRole.value == 'user'
                                      ? Colors.blue
                                      : Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tombol Register
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        _validateAndRegister(
                          nameC,
                          emailC,
                          passC,
                          selectedRole.value,
                          userController,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'DAFTARKAN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tombol Batal
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      enableDrag: false,
    );
  }

  // Widget untuk pilihan role
  Widget _buildRoleOption({
    required String title,
    required String value,
    required String groupValue,
    required IconData icon,
    required Color color,
    required Function(String) onChanged,
  }) {
    final isSelected = groupValue == value;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndRegister(
    TextEditingController nameC,
    TextEditingController emailC,
    TextEditingController passC,
    String role,
    UserController userController,
  ) {
    // Tutup bottom sheet
    Get.back();

    // Tampilkan dialog konfirmasi
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Konfirmasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Daftarkan akun sebagai ${role.toUpperCase()}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              userController.registerUser(
                name: nameC.text,
                email: emailC.text,
                password: passC.text,
                role: role,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ya, Daftar'),
          ),
        ],
      ),
    );
  }
}
