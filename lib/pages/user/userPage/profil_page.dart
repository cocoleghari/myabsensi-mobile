import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/user/userPage/daftar_wajah_page.dart';
import 'package:get/get.dart';
import '../modals/daftar_lokasi_modal.dart';
import '../modals/ganti_password_modal.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final lokasiController = Get.find<UserLokasiController>();
    final bool isWeb = kIsWeb;
    final double maxWidth = isWeb ? 500 : double.infinity;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade700, Colors.blue.shade300, Colors.white],
          stops: isWeb ? const [0.0, 0.2, 0.4] : const [0.0, 0.3, 0.7],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profil Saya',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Informasi Profil
                          _buildProfileInfo(authController),
                          const SizedBox(height: 20),

                          // Informasi Lokasi
                          _buildLocationInfo(lokasiController, context),
                          const SizedBox(height: 20),

                          // ===== DAFTARKAN WAJAH =====
                          _buildDaftarWajahMenu(lokasiController),
                          const SizedBox(height: 20),

                          // Divider
                          const Divider(height: 1),
                          const SizedBox(height: 20),

                          // ===== GANTI PASSWORD =====
                          _buildGantiPasswordMenu(context),
                          const SizedBox(height: 30),

                          // Tombol Logout
                          _buildLogoutButton(authController),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.shade300],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil Pengguna',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                'Informasi Akun',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(AuthController authController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person,
            label: 'Nama',
            value: authController.userName,
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.email,
            label: 'Email',
            value: authController.userEmail,
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.badge,
            label: 'Role',
            value: authController.userRole.toUpperCase(),
            valueColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(
    UserLokasiController controller,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        if (controller.userLokasis.isNotEmpty) {
          DaftarLokasiModal.show(context, controller);
        } else {
          Get.snackbar(
            'Info',
            'Belum ada lokasi tersedia',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green[100]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lokasi Tersedia',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    final total = controller.userLokasis.length;
                    return Text(
                      total > 0 ? '$total Lokasi' : 'Belum ada lokasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: total > 0 ? Colors.green[700] : Colors.grey[600],
                      ),
                    );
                  }),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.green[400], size: 20),
          ],
        ),
      ),
    );
  }

  // ── MENU DAFTARKAN WAJAH ─────────────────────────────────────────────
  Widget _buildDaftarWajahMenu(UserLokasiController controller) {
    return Obx(() {
      final sudahTerdaftar = controller.wajahTerdaftar.value;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: sudahTerdaftar ? Colors.green[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sudahTerdaftar ? Colors.green[100]! : Colors.orange[100]!,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: sudahTerdaftar ? Colors.green[100] : Colors.orange[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.face_retouching_natural,
              color: sudahTerdaftar ? Colors.green[700] : Colors.orange[700],
              size: 20,
            ),
          ),
          title: Text(
            sudahTerdaftar ? 'Perbarui Wajah' : 'Daftarkan Wajah',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            sudahTerdaftar
                ? 'Wajah sudah terdaftar — tap untuk perbarui'
                : 'Belum terdaftar — tap untuk mendaftarkan',
            style: TextStyle(
              fontSize: 12,
              color: sudahTerdaftar ? Colors.green[600] : Colors.orange[600],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sudahTerdaftar
                      ? Colors.green[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sudahTerdaftar ? 'Aktif' : 'Belum',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sudahTerdaftar
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: sudahTerdaftar ? Colors.green[400] : Colors.orange[400],
              ),
            ],
          ),
          onTap: () => Get.to(() => const DaftarWajahPage()),
        ),
      );
    });
  }

  Widget _buildGantiPasswordMenu(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_reset, color: Colors.orange[700], size: 20),
        ),
        title: const Text(
          'Ganti Password',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Ubah password akun Anda'),
        trailing: Icon(Icons.chevron_right, color: Colors.orange[400]),
        onTap: () => GantiPasswordModal.show(context),
      ),
    );
  }

  Widget _buildLogoutButton(AuthController authController) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(authController),
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
