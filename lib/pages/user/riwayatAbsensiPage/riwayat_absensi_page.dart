import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/utils/riwayat_formatter.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/widget/riwayat_card_widget.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/widget/riwayat_detail_dialog.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/widget/riwayat_empty_widget.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/widget/riwayat_loading_widget.dart';
import 'package:get/get.dart';

class RiwayatAbsensiPage extends StatelessWidget {
  const RiwayatAbsensiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserLokasiController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Absensi',
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
              controller.fetchRiwayatAbsensi();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingRiwayat.value) {
          return const RiwayatLoadingWidget();
        }

        if (controller.riwayatAbsensi.isEmpty) {
          return RiwayatEmptyWidget(
            onRefresh: () => controller.fetchRiwayatAbsensi(),
          );
        }

        final groupedData = RiwayatFormatter.groupByDate(
          controller.riwayatAbsensi,
        );
        final dates = groupedData.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final tanggal = dates[index];
            final items = groupedData[tanggal]!;

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

            return RiwayatCardWidget(
              index: index + 1,
              tanggal: tanggal,
              dataMasuk: dataMasuk,
              dataPulang: dataPulang,
              onTap: () {
                RiwayatDetailDialog.show(
                  context: context,
                  dataMasuk: dataMasuk,
                  dataPulang: dataPulang,
                  no: index + 1,
                  tanggal: tanggal,
                );
              },
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.fetchRiwayatAbsensi();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
