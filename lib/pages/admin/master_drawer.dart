import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import 'riwayatSemuaUserPage/riwayat_semua_user_page.dart';

class MasterDrawer extends StatelessWidget {
  final String currentPage;

  const MasterDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(authController),

            const SizedBox(height: 8),

            // ── SHIFT SECTION ─────────────────────────────────────────────
            _buildSectionDivider('Pengaturan Akun'),

            _buildMenuItem(
              icon: Icons.people,
              title: 'List Akun',
              routeName: '/admin',
              pageName: 'admin',
              iconColor: Colors.blue,
            ),

            _buildMenuItem(
              icon: Icons.location_on,
              title: 'Lokasi User',
              routeName: '/admin/lokasi',
              pageName: 'lokasi',
              iconColor: Colors.green,
            ),

            _buildMenuItem(
              icon: Icons.map,
              title: 'Pengaturan Lokasi',
              routeName: '/admin/pusat-lokasi',
              pageName: 'pusat-lokasi',
              iconColor: Colors.purple,
            ),

            // ── SHIFT SECTION ─────────────────────────────────────────────
            _buildSectionDivider('Pengaturan Karyawan'),

            _buildMenuItem(
              icon: Icons.account_tree,
              title: 'Department',
              routeName: '/admin/department',
              pageName: 'department',
              iconColor: Colors.deepPurple,
            ),

            _buildMenuItem(
              icon: Icons.badge,
              title: 'Karyawan',
              routeName: '/admin/employees',
              pageName: 'employee',
              iconColor: Colors.indigo,
            ),

            _buildMenuItem(
              icon: Icons.work_outline,
              title: 'Posisi / Jabatan',
              routeName: '/admin/positions',
              pageName: 'positions',
              iconColor: Colors.indigo,
            ),

            _buildMenuItem(
              icon: Icons.grade,
              title: 'Job Grade',
              routeName: '/admin/job-grades',
              pageName: 'job-grades',
              iconColor: Colors.amber,
            ),

            _buildMenuItem(
              icon: Icons.layers,
              title: 'Job Level',
              routeName: '/admin/job-levels',
              pageName: 'job-levels',
              iconColor: Colors.teal,
            ),

            _buildMenuItem(
              icon: Icons.label_outline,
              title: 'Status Karyawan',
              routeName: '/admin/employee-statuses',
              pageName: 'employee-statuses',
              iconColor: Colors.deepOrange,
            ),

            // ── SHIFT SECTION ─────────────────────────────────────────────
            _buildSectionDivider('Pengaturan Shift'),

            _buildMenuItem(
              icon: Icons.schedule,
              title: 'Master Shift',
              routeName: '/admin/shifts',
              pageName: 'shifts',
              iconColor: const Color(0xFF0288D1),
            ),

            _buildMenuItem(
              icon: Icons.calendar_view_week,
              title: 'Pola Shift Mingguan',
              routeName: '/admin/shift-patterns',
              pageName: 'shift-patterns',
              iconColor: const Color(0xFF00897B),
            ),

            _buildMenuItem(
              icon: Icons.people_alt_outlined,
              title: 'Assign Shift Karyawan',
              routeName: '/admin/employee-shifts',
              pageName: 'employee-shifts',
              iconColor: const Color(0xFF5E35B1),
            ),

            // ── LAPORAN SECTION ─────────────────────────────────────────────
            _buildSectionDivider('Laporan'),

            _buildMenuItem(
              icon: Icons.bar_chart_rounded,
              title: 'Laporan Absensi',
              routeName: '/admin/laporan-absensi',
              pageName: 'laporan-absensi',
              iconColor: Colors.green,
            ),

            _buildMenuItem(
              icon: Icons.assignment_rounded,
              title: 'Laporan Aktivitas',
              routeName: '/admin/laporan-aktivitas',
              pageName: 'laporan-aktivitas',
              iconColor: Colors.teal,
            ),

            // ─────────────────────────────────────────────────────────────
            _buildRiwayatMenuItem(),

            const Divider(height: 32, thickness: 1),

            _buildLogoutMenuItem(authController),

            const SizedBox(height: 20),

            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  /// Label pemisah section (tidak bisa diklik)
  Widget _buildSectionDivider(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildHeader(AuthController authController) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue, Colors.blueAccent],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Center(
              child: Obx(() {
                final userName = authController.userName;
                return Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Text(
              authController.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                authController.userRole.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String routeName,
    required String pageName,
    Color iconColor = Colors.blue,
  }) {
    final isSelected = currentPage == pageName;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : iconColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 5,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
            : null,
        onTap: () {
          Get.back();
          if (!isSelected) {
            Get.offAllNamed(routeName);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRiwayatMenuItem() {
    final isSelected = currentPage == 'riwayat_semua_user';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.history,
            color: isSelected ? Colors.white : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          'Riwayat Semua User',
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 5,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
            : null,
        onTap: () {
          Get.back();
          if (!isSelected) {
            Get.to(() => const RiwayatSemuaUserPage());
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLogoutMenuItem(AuthController authController) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        onTap: () {
          Get.back();
          _showLogoutDialog(authController);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Text(
            'Version 1.0.0',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2024 Absensi App',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Konfirmasi Logout',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(fontSize: 14),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
