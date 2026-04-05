// import 'package:flutter/material.dart';
// import 'package:frontend_flutter/controllers/auth_controller.dart';
// import 'package:frontend_flutter/controllers/lokasi_controller.dart';
// import 'package:frontend_flutter/pages/admin/lokasiPage/widget/lokasi_multiple_form.dart';
// import 'package:frontend_flutter/pages/admin/lokasiPage/widget/lokasi_table_widget.dart';
// import 'package:frontend_flutter/pages/admin/master_drawer.dart';
// import 'package:get/get.dart';

// class LokasiPage extends StatelessWidget {
//   LokasiPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final auth = Get.find<AuthController>();

//     if (!Get.isRegistered<LokasiController>()) {
//       Get.put(LokasiController());
//     }

//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text(
//             'Manajemen Lokasi User',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           backgroundColor: Colors.blue,
//           foregroundColor: Colors.white,
//           elevation: 2,
//           bottom: const TabBar(
//             indicatorColor: Colors.white,
//             indicatorWeight: 3,
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.white70,
//             tabs: [
//               Tab(icon: Icon(Icons.add_location), text: 'Tambah Lokasi'),
//               Tab(icon: Icon(Icons.list), text: 'Daftar Lokasi'),
//             ],
//           ),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: () {
//                 final controller = Get.find<LokasiController>();
//                 controller.fetchLokasi();
//                 controller.fetchUsers();
//                 controller.fetchPusatLokasi();
//                 Get.snackbar(
//                   'Sukses',
//                   'Data diperbarui',
//                   backgroundColor: Colors.green,
//                   colorText: Colors.white,
//                   snackPosition: SnackPosition.TOP,
//                   duration: const Duration(seconds: 1),
//                 );
//               },
//               tooltip: 'Refresh Data',
//             ),
//           ],
//         ),
//         drawer: const MasterDrawer(currentPage: 'lokasi'),
//         body: Obx(() {
//           if (auth.token.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.lock_outline, size: 64, color: Colors.grey),
//                   SizedBox(height: 16),
//                   Text(
//                     'Silahkan login terlebih dahulu',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             );
//           }

//           return const TabBarView(
//             children: [_TambahLokasiTab(), _DaftarLokasiTab()],
//           );
//         }),
//       ),
//     );
//   }
// }

// class _TambahLokasiTab extends StatelessWidget {
//   const _TambahLokasiTab();

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: () async {
//         final controller = Get.find<LokasiController>();
//         await controller.fetchUsers();
//         await controller.fetchPusatLokasi();
//       },
//       color: Colors.blue,
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const LokasiMultipleForm(),

//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.blue.shade200),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.info, color: Colors.blue.shade600, size: 20),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'Pilih user terlebih dahulu, lalu centang lokasi dari pusat atau input manual.',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.blue.shade800,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _DaftarLokasiTab extends StatelessWidget {
//   const _DaftarLokasiTab();

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: () async {
//         final controller = Get.find<LokasiController>();
//         await controller.fetchLokasi();
//       },
//       color: Colors.blue,
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const LokasiTableWidget(),

//             const SizedBox(height: 20),

//             Obx(() {
//               final controller = Get.find<LokasiController>();
//               final totalLokasi = controller.lokasis.length;

//               final Map<String, int> userCount = {};
//               for (var lokasi in controller.lokasis) {
//                 userCount[lokasi.user] = (userCount[lokasi.user] ?? 0) + 1;
//               }

//               return Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.green.shade200),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade100,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.stacked_bar_chart,
//                         color: Colors.green.shade700,
//                         size: 24,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Total: $totalLokasi lokasi',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green.shade800,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${userCount.length} user terdaftar',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.green.shade600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }),

//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/admin/lokasiPage/widget/lokasi_multiple_form.dart';
import 'package:myabsensi_mobile/pages/admin/lokasiPage/widget/lokasi_table_widget.dart';
import 'package:myabsensi_mobile/pages/admin/master_drawer.dart';
import 'package:get/get.dart';

class LokasiPage extends StatelessWidget {
  LokasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    // PASTIKAN CONTROLLER TERDAFTAR
    if (!Get.isRegistered<LokasiController>()) {
      Get.put(LokasiController());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Manajemen Lokasi User',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.add_location), text: 'Tambah Lokasi'),
              Tab(icon: Icon(Icons.list), text: 'Daftar Lokasi'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final controller = Get.find<LokasiController>();
                controller.fetchLokasi();
                controller.fetchUsers();
                controller.fetchPusatLokasi();
                Get.snackbar(
                  'Sukses',
                  'Data diperbarui',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 1),
                );
              },
              tooltip: 'Refresh Data',
            ),
          ],
        ),
        drawer: const MasterDrawer(currentPage: 'lokasi'),
        body: Obx(() {
          if (auth.token.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Silahkan login terlebih dahulu',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return const TabBarView(
            children: [_TambahLokasiTab(), _DaftarLokasiTab()],
          );
        }),
      ),
    );
  }
}

// ========== TAB 1: TAMBAH LOKASI ==========
class _TambahLokasiTab extends StatelessWidget {
  const _TambahLokasiTab();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final controller = Get.find<LokasiController>();
        await controller.fetchUsers();
        await controller.fetchPusatLokasi();
      },
      color: Colors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const LokasiMultipleForm(),
            const SizedBox(height: 20),
            _buildInfoCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pilih user terlebih dahulu, lalu centang lokasi dari pusat atau input manual.',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== TAB 2: DAFTAR LOKASI ==========
class _DaftarLokasiTab extends StatelessWidget {
  const _DaftarLokasiTab();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final controller = Get.find<LokasiController>();
        await controller.fetchLokasi();
      },
      color: Colors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const LokasiTableWidget(),
            const SizedBox(height: 20),
            _buildStatistikCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // PISAHKAN WIDGET STATISTIK MENGGUNAKAN GetBuilder
  Widget _buildStatistikCard() {
    return GetBuilder<LokasiController>(
      builder: (controller) {
        final totalLokasi = controller.lokasis.length;

        // GROUP BY USER
        final Map<String, int> userCount = {};
        for (var lokasi in controller.lokasis) {
          userCount[lokasi.user] = (userCount[lokasi.user] ?? 0) + 1;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stacked_bar_chart,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: $totalLokasi lokasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${userCount.length} user terdaftar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
