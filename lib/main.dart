import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/bindings/company_binding.dart';
import 'package:myabsensi_mobile/bindings/department_binding.dart';
import 'package:myabsensi_mobile/bindings/employee_binding.dart';
import 'package:myabsensi_mobile/bindings/employee_pusat_lokasi_binding.dart';
import 'package:myabsensi_mobile/bindings/position_binding.dart';
import 'package:myabsensi_mobile/bindings/shift_binding.dart';
import 'package:myabsensi_mobile/controllers/app_config.dart';
import 'package:myabsensi_mobile/pages/admin/employeePage/employee_list_page.dart';
import 'package:myabsensi_mobile/pages/admin/employeeStatusPage/employee_status_page.dart';
import 'package:myabsensi_mobile/pages/admin/jobGradePage/job_grade_page.dart';
import 'package:myabsensi_mobile/pages/admin/jobLevelPage/job_level_page.dart';
import 'package:myabsensi_mobile/pages/admin/laporanAbsensiPage/laporan_absensi_page.dart';
import 'package:myabsensi_mobile/pages/admin/laporanAktivitasPage/laporan_aktivitas_page.dart';
import 'package:myabsensi_mobile/pages/admin/positionPage/position_page.dart';
import 'package:myabsensi_mobile/pages/admin/profil_admin_page.dart';
import 'package:myabsensi_mobile/pages/admin/shiftPage/assign_karyawan_page.dart';
import 'package:myabsensi_mobile/pages/admin/shiftPage/master_shift_page.dart';
import 'package:myabsensi_mobile/pages/admin/shiftPage/pola_mingguan_page.dart';
import 'package:myabsensi_mobile/pages/splash_pages.dart';
import 'package:myabsensi_mobile/pages/user/absenPage/modals/employee_profile_page.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/riwayat_absensi_page.dart';
import 'package:myabsensi_mobile/pages/user/userPage/user_page.dart';
import 'package:myabsensi_mobile/pages/admin/departmentPage/department_page.dart';
import 'package:myabsensi_mobile/pages/admin/companyPage/company_page.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'bindings/initial_binding.dart';
import 'bindings/user_lokasi_binding.dart';
import 'bindings/pusat_lokasi_binding.dart';
import 'pages/auth/login_page.dart';
import 'pages/admin/listAkun/list_akun.dart';
import 'pages/admin/lokasiPage/lokasi_page.dart';
import 'pages/admin/pusatLokasi/pusat_lokasi_page.dart';

void main() async {
  // Wajib dipanggil pertama agar native splash tetap tampil
  // selama proses inisialisasi berlangsung
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await initializeDateFormatting('id_ID', null);
  await GetStorage.init();
  await AppConfig.getBaseUrl();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'KaryaOne',
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
          binding: EmployeePusatLokasiBinding(),
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
        GetPage(
          name: '/admin/department',
          page: () => const DepartmentPage(),
          binding: DepartmentBinding(),
        ),
        GetPage(
          name: '/admin/companies',
          page: () => const CompanyPage(),
          binding: CompanyBinding(),
        ),
        GetPage(
          name: '/admin/employees',
          page: () => const EmployeeListPage(),
          binding: EmployeeBinding(),
        ),
        GetPage(
          name: '/admin/positions',
          page: () => const PositionPage(),
          binding: PositionBinding(),
        ),
        GetPage(name: '/admin/job-grades', page: () => const JobGradePage()),
        GetPage(name: '/admin/job-levels', page: () => const JobLevelPage()),
        GetPage(
          name: '/admin/shifts',
          page: () => const MasterShiftPage(),
          binding: ShiftBinding(),
        ),
        GetPage(
          name: '/admin/shift-patterns',
          page: () => const PolaMinggguanPage(),
          binding: ShiftBinding(),
        ),
        GetPage(
          name: '/admin/employee-shifts',
          page: () => const AssignKaryawanPage(),
          binding: ShiftBinding(),
        ),
        GetPage(
          name: '/admin/employee-statuses',
          page: () => const EmployeeStatusPage(),
          binding: EmployeeBinding(),
        ),
        GetPage(
          name: '/admin/laporan-absensi',
          page: () => const LaporanAbsensiPage(),
        ),
        GetPage(
          name: '/admin/laporan-aktivitas',
          page: () => const LaporanAktivitasPage(),
        ),
      ],
    );
  }
}
