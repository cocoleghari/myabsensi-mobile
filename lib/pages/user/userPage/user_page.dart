import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/riwayat_absensi_page.dart';
import 'package:get/get.dart';
import 'absen_page.dart';
import 'profil_page.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    if (!Get.isRegistered<UserLokasiController>()) {
      Get.put(UserLokasiController());
    }

    final bottomNavController = Get.put(UserBottomNavController());

    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: bottomNavController.currentIndex.value,
          children: const [AbsenPage(), RiwayatAbsensiPage(), ProfilPage()],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(bottomNavController),
      ),
    );
  }

  Widget _buildBottomNavigationBar(UserBottomNavController controller) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: controller.currentIndex.value,
        onTap: controller.changePage,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'Absen',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class UserBottomNavController extends GetxController {
  var currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}
