import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:myabsensi_mobile/controllers/app_config.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/notification_controller.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  static void show() {
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController());
    }
    Get.to(
      () => const NotificationPage(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final NotificationController _nc;

  final _tabs = const [
    {'key': 'all', 'label': 'All'},
    {'key': 'request', 'label': 'Request'},
    {'key': 'approvals', 'label': 'Approvals'},
  ];

  @override
  void initState() {
    super.initState();
    _nc = Get.find<NotificationController>();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1F36)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1F36),
          ),
        ),
        actions: [
          Obx(() {
            if (_nc.unreadCount.value == 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: _nc.markAllAsRead,
              child: const Text(
                'Tandai semua',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _nc.fetchNotifications,
        color: const Color(0xFFFF7A30),
        child: TabBarView(
          controller: _tabController,
          children: _tabs.map((t) {
            if (t['key'] == 'request') {
              return _RequestTabList(controller: _nc);
            }
            return _NotificationList(category: t['key']!, controller: _nc);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFFF7A30),
        unselectedLabelColor: const Color(0xFF8A94A6),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: const Color(0xFFFF7A30),
        indicatorWeight: 2.5,
        tabs: _tabs.map((t) {
          final key = t['key']!;
          return Obx(() {
            final unread = _nc.unreadByCategory(key);
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t['label']!),
                  if (unread > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          });
        }).toList(),
      ),
    );
  }
}

// ─── Request Tab ──────────────────────────────────────────────────────────────

class _RequestTabList extends StatefulWidget {
  final NotificationController controller;
  const _RequestTabList({required this.controller});

  @override
  State<_RequestTabList> createState() => _RequestTabListState();
}

class _RequestTabListState extends State<_RequestTabList> {
  List<Map<String, dynamic>> _permintaans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = Get.find<AuthController>().token.value;
      final baseUrl = await AppConfig.getBaseUrl();
      final res = await http
          .get(
            Uri.parse('$baseUrl/user/permintaan-absen/riwayat'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data']['data'] ?? data['data'] ?? [];
        if (mounted) {
          setState(() {
            _permintaans = List<Map<String, dynamic>>.from(list);
          });
        }
      }
    } catch (e) {
      debugPrint('fetchRiwayat permintaan error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7A30)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRiwayat,
      color: const Color(0xFFFF7A30),
      child: Obx(() {
        final notifItems = widget.controller.getByCategory('request');
        final hasNotif = notifItems.isNotEmpty;
        final hasPermintaan = _permintaans.isNotEmpty;

        if (!hasNotif && !hasPermintaan) {
          return ListView(
            children: [
              const SizedBox(height: 270),
              Center(
                child: Image.asset(
                  'assets/images/tidak_ada_permintaan.png',
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          children: [
            if (hasNotif) ...[
              _sectionLabel('Notifikasi'),
              const SizedBox(height: 8),
              ...notifItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NotificationItem(
                    data: item,
                    onTap: () {
                      widget.controller.markAsRead(item['id']);
                      if (item['type'] == 'permintaan_absen') {
                        final permintaanId = _parsePermintaanId(item['data']);
                        if (permintaanId != null) {
                          _ApproveDialog.show(context, permintaanId);
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (hasPermintaan) ...[
              _sectionLabel('Riwayat Izin Lokasi'),
              const SizedBox(height: 8),
              ..._permintaans.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PermintaanItem(data: item),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8A94A6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── List per tab ─────────────────────────────────────────────────────────────

class _NotificationList extends StatelessWidget {
  final String category;
  final NotificationController controller;

  const _NotificationList({required this.category, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7A30)),
        );
      }

      final items = controller.getByCategory(category);

      if (items.isEmpty) {
        return Center(
          child: Image.asset(
            category == 'approvals'
                ? 'assets/images/tidak_ada_persetujuan.png'
                : 'assets/images/tidak_ada_notif.png',
            width: 180,
            fit: BoxFit.contain,
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _NotificationItem(
          data: items[i],
          onTap: () {
            controller.markAsRead(items[i]['id']);
            if (items[i]['type'] == 'permintaan_absen') {
              final permintaanId = _parsePermintaanId(items[i]['data']);
              if (permintaanId != null) {
                _ApproveDialog.show(context, permintaanId);
              }
            }
          },
        ),
      );
    });
  }
}

// ─── Helper parse permintaan_id ───────────────────────────────────────────────

int? _parsePermintaanId(dynamic data) {
  if (data is Map) {
    return int.tryParse(data['permintaan_id']?.toString() ?? '');
  } else if (data is String) {
    try {
      final decoded = jsonDecode(data);
      return int.tryParse(decoded['permintaan_id']?.toString() ?? '');
    } catch (_) {}
  }
  return null;
}

// ─── Notification Item ────────────────────────────────────────────────────────

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotificationItem({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRead = data['is_read'] == true;
    final initials = _getInitials(data['title'] ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead ? const Color(0xFFE5E7EB) : const Color(0xFFFED7AA),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFFFEF3C7),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isRead
                        ? const Color(0xFF8A94A6)
                        : const Color(0xFFF97316),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: const Color(0xFF1A1F36),
                          ),
                        ),
                      ),
                      Text(
                        data['date'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: isRead
                              ? const Color(0xFF8A94A6)
                              : const Color(0xFFF97316),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['subtitle'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A94A6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFF97316),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getInitials(String title) {
    final words = title.trim().split(' ');
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }
}

// ─── Permintaan Item (sisi karyawan) ─────────────────────────────────────────

class _PermintaanItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PermintaanItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString() ?? 'pending';
    final alasan = data['alasan']?.toString() ?? '-';
    final tipe = data['tipe_absen']?.toString() ?? '-';
    final waktu = data['waktu_pengajuan']?.toString() ?? '';
    final approverNama = data['approver']?['full_name']?.toString() ?? 'Admin';
    final catatanAdmin = data['catatan_admin']?.toString();
    final namaLokasi = data['pusat_lokasi']?['nama_lokasi']?.toString() ?? '-';
    final alamatPengajuan = data['alamat_pengajuan']?.toString() ?? '';

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Disetujui';
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEF2F2);
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Ditolak';
        break;
      default:
        statusColor = const Color(0xFFF97316);
        statusBg = const Color(0xFFFFF7ED);
        statusIcon = Icons.hourglass_top_rounded;
        statusLabel = 'Menunggu';
    }

    String formattedWaktu = '-';
    try {
      final dt = DateTime.parse(waktu).toLocal();
      formattedWaktu =
          '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tipe == 'masuk'
                      ? const Color(0xFFE8F3FF)
                      : const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tipe == 'masuk' ? 'Absen Masuk' : 'Absen Pulang',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tipe == 'masuk'
                        ? const Color(0xFF1565C0)
                        : const Color(0xFFF97316),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),

          // ── Detail ──
          _infoRow(Icons.assignment_late_outlined, 'Alasan', alasan),
          const SizedBox(height: 6),
          _infoRow(
            Icons.my_location_rounded,
            'Lokasi Saat Absen',
            alamatPengajuan.isNotEmpty ? alamatPengajuan : '-',
          ),
          const SizedBox(height: 6),
          _infoRow(Icons.place_outlined, 'Lokasi Terdekat', namaLokasi),
          const SizedBox(height: 6),
          _infoRow(
            Icons.access_time_rounded,
            'Waktu Pengajuan',
            formattedWaktu,
          ),
          const SizedBox(height: 6),
          _infoRow(Icons.person_outline_rounded, 'Diteruskan ke', approverNama),

          // ── Catatan admin ──
          if (catatanAdmin != null && catatanAdmin.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: status == 'approved'
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment_outlined, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: $catatanAdmin',
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8A94A6)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1F36),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Approve Dialog ───────────────────────────────────────────────────────────

class _ApproveDialog {
  static void show(BuildContext context, int permintaanId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApproveBottomSheet(permintaanId: permintaanId),
    );
  }
}

class _ApproveBottomSheet extends StatefulWidget {
  final int permintaanId;
  const _ApproveBottomSheet({required this.permintaanId});

  @override
  State<_ApproveBottomSheet> createState() => _ApproveBottomSheetState();
}

class _ApproveBottomSheetState extends State<_ApproveBottomSheet> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isProcessing = false;
  final _catatanCtrl = TextEditingController();
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    try {
      final token = Get.find<AuthController>().token.value;
      final baseUrl = await AppConfig.getBaseUrl();
      final res = await http
          .get(
            Uri.parse('$baseUrl/user/permintaan-absen/${widget.permintaanId}'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (mounted) setState(() => _data = body['data']);
      }
    } catch (e) {
      debugPrint('fetchDetail error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _proses(String status) async {
    if (mounted) setState(() => _isProcessing = true);
    try {
      final token = Get.find<AuthController>().token.value;
      final baseUrl = await AppConfig.getBaseUrl();
      final res = await http
          .patch(
            Uri.parse(
              '$baseUrl/user/permintaan-absen/${widget.permintaanId}/proses',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'status': status,
              'catatan_admin': _catatanCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        Get.back();
        Get.snackbar(
          status == 'approved' ? 'Disetujui ✓' : 'Ditolak',
          status == 'approved'
              ? 'Absensi karyawan telah dicatat otomatis'
              : 'Permintaan telah ditolak',
          backgroundColor: status == 'approved'
              ? const Color(0xFF059669)
              : const Color(0xFFDC2626),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: 10,
        );

        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().fetchNotifications();
        }
        if (Get.isRegistered<UserLokasiController>()) {
          Get.find<UserLokasiController>()
              .cekStatusHariIni(); // ← refresh absen page
          Get.find<UserLokasiController>().fetchRiwayatAbsensi();
        }
      } else {
        final err = jsonDecode(res.body);
        Get.snackbar(
          'Gagal',
          err['message'] ?? 'Terjadi kesalahan',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        '$e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7A30)),
              ),
            )
          : _data == null
          ? const SizedBox(
              height: 200,
              child: Center(child: Text('Data tidak ditemukan')),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final status = d['status']?.toString() ?? 'pending';
    final isPending = status == 'pending';
    final namaKaryawan = d['employee']?['full_name']?.toString() ?? '-';
    final department = d['employee']?['department']?['name']?.toString() ?? '-';
    final tipe = d['tipe_absen']?.toString() ?? '-';
    final alasan = d['alasan']?.toString() ?? '-';
    final keterangan = d['keterangan']?.toString() ?? '';
    final lokasi = d['pusat_lokasi']?['nama_lokasi']?.toString() ?? '-';
    final jarak = (d['jarak_meter'] as num?)?.toStringAsFixed(0) ?? '-';
    final waktu = d['waktu_pengajuan']?.toString() ?? '';
    final alamatPengajuan = d['alamat_pengajuan']?.toString() ?? '';

    // Koordinat karyawan
    final lat = (d['latitude'] as num?)?.toDouble();
    final lng = (d['longitude'] as num?)?.toDouble();

    // Koordinat pusat lokasi dari titik_kordinat "lat,lng"
    double? pusatLat, pusatLng;
    final titikKordinat =
        d['pusat_lokasi']?['titik_kordinat']?.toString() ?? '';
    if (titikKordinat.isNotEmpty) {
      final parts = titikKordinat.split(',');
      if (parts.length == 2) {
        pusatLat = double.tryParse(parts[0].trim());
        pusatLng = double.tryParse(parts[1].trim());
      }
    }

    String formattedWaktu = '-';
    try {
      final dt = DateTime.parse(waktu).toLocal();
      formattedWaktu =
          '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_late_outlined,
                  color: Color(0xFFF97316),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Permintaan Izin Lokasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFFF7ED)
                      : status == 'approved'
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPending
                      ? 'Menunggu'
                      : status == 'approved'
                      ? 'Disetujui'
                      : 'Ditolak',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPending
                        ? const Color(0xFFF97316)
                        : status == 'approved'
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),

          // ── Info karyawan ──
          _row(Icons.person_outline_rounded, 'Karyawan', namaKaryawan),
          const SizedBox(height: 8),
          _row(Icons.business_outlined, 'Departemen', department),
          const SizedBox(height: 8),
          _row(
            Icons.login_rounded,
            'Tipe Absen',
            tipe == 'masuk' ? 'Absen Masuk' : 'Absen Pulang',
          ),
          const SizedBox(height: 8),
          _row(
            Icons.my_location_rounded,
            'Lokasi Saat Absen',
            alamatPengajuan.isNotEmpty
                ? alamatPengajuan
                : '$jarak m dari $lokasi',
          ),
          const SizedBox(height: 8),
          _row(Icons.place_outlined, 'Lokasi Terdekat', lokasi),
          const SizedBox(height: 8),
          _row(Icons.access_time_rounded, 'Waktu', formattedWaktu),
          const SizedBox(height: 8),
          _row(Icons.assignment_late_outlined, 'Alasan', alasan),
          if (keterangan.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row(Icons.notes_rounded, 'Keterangan', keterangan),
          ],

          // ── Peta Lokasi ──
          if (lat != null && lng != null && !_isLoading) ...[
            const SizedBox(height: 16),
            const Text(
              'Peta Lokasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('karyawan'),
                      position: LatLng(lat, lng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                      infoWindow: InfoWindow(title: namaKaryawan),
                    ),
                    if (pusatLat != null && pusatLng != null)
                      Marker(
                        markerId: const MarkerId('kantor'),
                        position: LatLng(pusatLat, pusatLng),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                        infoWindow: InfoWindow(title: lokasi),
                      ),
                  },
                  circles: pusatLat != null && pusatLng != null
                      ? {
                          Circle(
                            circleId: const CircleId('radius'),
                            center: LatLng(pusatLat, pusatLng),
                            radius: 100,
                            fillColor: const Color(0x1A4C9FF1),
                            strokeColor: const Color(0x734C9FF1),
                            strokeWidth: 2,
                          ),
                        }
                      : {},
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  onMapCreated: (c) => _mapController = c,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              children: [
                _legendDot(const Color(0xFF4C9FF1)),
                const SizedBox(width: 4),
                const Text(
                  'Posisi karyawan',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8A94A6)),
                ),
                const SizedBox(width: 16),
                _legendDot(Colors.red),
                const SizedBox(width: 4),
                const Text(
                  'Lokasi absen',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8A94A6)),
                ),
              ],
            ),
          ],

          // ── Foto Bukti ──
          if (d['foto_path'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Foto Bukti',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _resolveUrl(d['foto_path']),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: const Color(0xFFF3F6FB),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF8A94A6),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── Catatan (hanya saat pending) ──
          if (isPending) ...[
            const SizedBox(height: 16),
            const Text(
              'Catatan (opsional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catatanCtrl,
              maxLines: 2,
              maxLength: 200,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan untuk karyawan...',
                hintStyle: const TextStyle(
                  color: Color(0xFF8A94A6),
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: const Color(0xFFF3F6FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4EAF6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4EAF6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF97316),
                    width: 1.5,
                  ),
                ),
                counterStyle: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A94A6),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tombol Approve / Reject ──
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _proses('rejected'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text(
                        'Tolak',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(
                          color: Color(0xFFDC2626),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _proses('approved'),
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isProcessing ? 'Memproses...' : 'Setujui',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Sudah diproses ──
          if (!isPending) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: status == 'approved'
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status == 'approved'
                    ? 'Permintaan ini sudah disetujui'
                    : 'Permintaan ini sudah ditolak'
                          '${d['catatan_admin'] != null ? '\nCatatan: ${d['catatan_admin']}' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  color: status == 'approved'
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8A94A6)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D1B2A),
            ),
          ),
        ),
      ],
    );
  }

  String _resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    String base =
        Get.find<AuthController>().box.read('base_url')?.toString() ?? '';
    if (base.isEmpty) base = 'http://192.168.100.104:8000/api';
    final origin = base.replaceFirst(RegExp(r'/api/?$'), '');
    return '$origin/storage/$path';
  }
}
