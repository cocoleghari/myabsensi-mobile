import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/pages/user/modals/ganti_password_modal.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import 'master_drawer.dart';

class ProfilAdminPage extends StatelessWidget {
  const ProfilAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    // SAFE CHECK: pastikan user tidak null
    final userData = authController.user;
    final bool isSuperAdmin =
        authController.userEmail == 'superadmin@absensi.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const MasterDrawer(currentPage: 'profil-admin'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeader(authController, isSuperAdmin),
                const SizedBox(height: 30),

                _buildInfoCard(authController, isSuperAdmin),
                const SizedBox(height: 30),

                if (!isSuperAdmin) _buildGantiPasswordMenu(context),

                if (isSuperAdmin) _buildSuperAdminInfo(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthController authController, bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSuperAdmin
                    ? [Colors.purple, Colors.purple.shade300]
                    : [Colors.blue, Colors.blue.shade300],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                authController.userName.isNotEmpty
                    ? authController.userName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            authController.userName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSuperAdmin ? Colors.purple : Colors.blue,
            ),
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSuperAdmin ? Colors.purple.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSuperAdmin
                    ? Colors.purple.shade200
                    : Colors.blue.shade200,
              ),
            ),
            child: Text(
              isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN',
              style: TextStyle(
                color: isSuperAdmin ? Colors.purple : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AuthController authController, bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Akun',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),

          _buildInfoRow(
            icon: Icons.email,
            label: 'Email',
            value: authController.userEmail,
            color: isSuperAdmin ? Colors.purple : Colors.blue,
          ),
          const Divider(height: 20),

          _buildInfoRow(
            icon: Icons.badge,
            label: 'Role',
            value: isSuperAdmin ? 'Super Admin' : 'Admin',
            color: isSuperAdmin ? Colors.purple : Colors.blue,
          ),
          const Divider(height: 20),

          // PERBAIKAN: SAFE CHECK UNTUK ID
          _buildInfoRow(
            icon: Icons.numbers,
            label: 'ID User',
            value: _getUserId(authController),
            color: isSuperAdmin ? Colors.purple : Colors.blue,
          ),
        ],
      ),
    );
  }

  // ========== FUNGSI UNTUK MENDAPATKAN USER ID DENGAN AMAN ==========
  String _getUserId(AuthController authController) {
    try {
      final user = authController.user;
      if (user is Map && user.containsKey('id')) {
        final id = user['id'];
        return id?.toString() ?? '-';
      }
      return '-';
    } catch (e) {
      print('❌ Error getting user ID: $e');
      return '-';
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGantiPasswordMenu(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_reset, color: Colors.orange[700], size: 24),
        ),
        title: const Text(
          'Ganti Password',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Ubah password akun Anda',
          style: TextStyle(fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.orange[400]),
        onTap: () {
          GantiPasswordModal.show(context);
        },
      ),
    );
  }

  Widget _buildSuperAdminInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.purple, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Akun Super Admin',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Akun ini adalah akun utama sistem.\n'
            'Tidak dapat dihapus dan tidak perlu mengganti password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.purple),
          ),
        ],
      ),
    );
  }
}
