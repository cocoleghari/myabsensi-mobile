import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/utils/riwayat_formatter.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/widget/riwayat_card_widget.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/widget/riwayat_detail_dialog.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/widget/riwayat_empty_widget.dart';
import 'package:myabsensi_mobile/pages/user/riwayatAbsensiPage/widget/riwayat_loading_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';

class RiwayatAbsensiPage extends StatefulWidget {
  const RiwayatAbsensiPage({super.key});

  @override
  State<RiwayatAbsensiPage> createState() => _RiwayatAbsensiPageState();
}

class _RiwayatAbsensiPageState extends State<RiwayatAbsensiPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1565C0),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserLokasiController>();
    final bool isWeb = kIsWeb;
    final double maxWidth = isWeb ? 500 : double.infinity;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Obx(() {
              return RefreshIndicator(
                onRefresh: () async => controller.fetchRiwayatAbsensi(),
                color: const Color(0xFFFF7A30),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── HEADER BIRU ──
                    SliverToBoxAdapter(
                      child: _buildHeader(context, controller),
                    ),

                    // ── KONTEN ──
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                        child: _buildBody(controller),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserLokasiController controller) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -20,
                top: -10,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                right: 60,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Riwayat Absensi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      // Refresh button
                      GestureDetector(
                        onTap: () => controller.fetchRiwayatAbsensi(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 20),

                  // Summary row
                  Obx(() {
                    final total = controller.riwayatAbsensi.length;
                    return Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.history_rounded,
                          label: 'Total Absensi',
                          value: '$total Data',
                        ),
                        const SizedBox(width: 10),
                        _buildStatChip(
                          icon: Icons.calendar_today_outlined,
                          label: 'Bulan Ini',
                          value: _countThisMonth(controller.riwayatAbsensi),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.85), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(UserLokasiController controller) {
    if (controller.isLoadingRiwayat.value) {
      return const RiwayatLoadingWidget();
    }

    if (controller.riwayatAbsensi.isEmpty) {
      return RiwayatEmptyWidget(
        onRefresh: () => controller.fetchRiwayatAbsensi(),
      );
    }

    final groupedData = RiwayatFormatter.groupByDate(controller.riwayatAbsensi);
    final dates = groupedData.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Daftar Absensi'),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8A94A6),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  String _countThisMonth(List riwayat) {
    final now = DateTime.now();
    int count = 0;
    for (final item in riwayat) {
      try {
        final dt = DateTime.parse(item['waktu_absen'].toString());
        if (dt.month == now.month && dt.year == now.year) count++;
      } catch (_) {}
    }
    return '$count Data';
  }
}
