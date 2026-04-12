import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/pages/admin/profil_admin_page.dart';
import 'package:myabsensi_mobile/pages/splash_pages.dart';
import 'package:myabsensi_mobile/pages/user/absenPage/employee_profile_page.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/riwayat_absensi_page.dart';
import 'package:myabsensi_mobile/pages/user/userPage/user_page.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'bindings/initial_binding.dart';
import 'bindings/user_lokasi_binding.dart';
import 'bindings/lokasi_binding.dart';
import 'bindings/pusat_lokasi_binding.dart';
import 'pages/auth/login_page.dart';
import 'pages/admin/listAkun/list_akun.dart';
import 'pages/admin/lokasiPage/lokasi_page.dart';
import 'pages/admin/pusatLokasi/pusat_lokasi_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Absensi App',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashPage()),
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/admin', page: () => const ListAkunPage()),
        GetPage(
          name: '/admin/lokasi',
          page: () => LokasiPage(),
          binding: LokasiBinding(),
        ),
        GetPage(
          name: '/admin/pusat-lokasi',
          page: () => const PusatLokasiPage(),
          binding: PusatLokasiBinding(),
        ),

        GetPage(name: '/admin/profil', page: () => const ProfilAdminPage()),
        GetPage(
          name: '/user',
          page: () => const UserPage(),
          binding: UserLokasiBinding(),
        ),
        GetPage(name: '/user/riwayat', page: () => const RiwayatAbsensiPage()),
        GetPage(
          name: '/employee/profile',
          page: () => const EmployeeProfilePage(),
        ),
      ],
    );
  }
}
