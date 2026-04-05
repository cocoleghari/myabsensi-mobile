import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/admin_absensi_controller.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/pages/admin/riwayatSemuaUserPage/widget/admin_absensi_card_widget.dart';
import 'package:myabsensi_mobile/pages/admin/riwayatSemuaUserPage/widget/admin_detail_dialog.dart';
import 'package:myabsensi_mobile/pages/admin/riwayatSemuaUserPage/widget/admin_filter_widget.dart';
import 'package:myabsensi_mobile/pages/admin/riwayatSemuaUserPage/widget/admin_formatter.dart';
import 'package:myabsensi_mobile/pages/admin/riwayatSemuaUserPage/widget/admin_summary_widget.dart';
import 'package:myabsensi_mobile/pages/admin/riwayatSemuaUserPage/widget/admin_user_header_widget.dart';
import 'package:get/get.dart';

class RiwayatSemuaUserPage extends StatelessWidget {
  const RiwayatSemuaUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminAbsensiController());
    final auth = Get.find<AuthController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchAllUsers();
      controller.fetchAllAbsensi();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Semua User',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.resetFilter();
              controller.fetchAllUsers();
              controller.fetchAllAbsensi();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value || controller.isLoadingUsers.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                SizedBox(height: 16),
                Text('Memuat data...'),
              ],
            ),
          );
        }

        if (controller.semuaAbsensi.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Belum Ada Data Absensi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada user yang melakukan absensi',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            AdminFilterWidget(controller: controller),
            const Divider(height: 1),

            AdminSummaryWidget(
              totalUser: controller.semuaUsers.length,
              totalAbsensi: controller.semuaAbsensi.length,
              hariAktif: controller.getUniqueDatesCount(),
            ),
            const Divider(height: 1),

            Expanded(child: _buildAbsensiList(controller)),
          ],
        );
      }),
    );
  }

  Widget _buildAbsensiList(AdminAbsensiController controller) {
    final groupedData = AdminFormatter.groupByUserAndDate(
      controller.semuaAbsensi,
      (userId) => controller.getUserNameById(userId),
    );
    final userNames = groupedData.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: userNames.length,
      itemBuilder: (context, userIndex) {
        final userName = userNames[userIndex];
        final userDates = groupedData[userName]!;
        final dates = userDates.keys.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminUserHeaderWidget(userName: userName, totalDays: dates.length),

            ...dates.map((tanggal) {
              final items = userDates[tanggal]!;

              Map<String, dynamic>? dataMasuk;
              Map<String, dynamic>? dataPulang;

              try {
                dataMasuk = items.firstWhere(
                  (item) => item['tipe_absen'] == 'masuk',
                );
              } catch (e) {
                dataMasuk = null;
              }

              try {
                dataPulang = items.firstWhere(
                  (item) => item['tipe_absen'] == 'pulang',
                );
              } catch (e) {
                dataPulang = null;
              }

              String lokasi = '';
              if (items.isNotEmpty && items.first['lokasi'] != null) {
                if (items.first['lokasi'] is Map) {
                  lokasi = items.first['lokasi']['lokasi']?.toString() ?? '';
                } else {
                  lokasi = items.first['lokasi'].toString();
                }
              }

              return AdminAbsensiCardWidget(
                userIndex: userIndex,
                userName: userName,
                tanggal: tanggal,
                lokasi: lokasi,
                dataMasuk: dataMasuk,
                dataPulang: dataPulang,
                onTap: () {
                  AdminDetailDialog.show(
                    context: context,
                    dataMasuk: dataMasuk,
                    dataPulang: dataPulang,
                    userName: userName,
                    tanggal: tanggal,
                  );
                },
              );
            }).toList(),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
