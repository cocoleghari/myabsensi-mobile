import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:myabsensi_mobile/pages/user/userPage/camera_page.dart';
import 'package:myabsensi_mobile/controllers/rekam_aktivitas_controller.dart';

class RekamAktivitasFormPage extends GetView<RekamAktivitasFormController> {
  const RekamAktivitasFormPage({super.key});

  // ── Warna tema ─────────────────────────────────────────────────────────
  static const _gradientStart = Color(0xFF1565C0);
  static const _gradientMid = Color(0xFF1E88E5);
  static const _gradientEnd = Color(0xFF42A5F5);
  static const _accent = Color(0xFFFF7A30);
  static const _bg = Color(0xFFF2F4F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Header biru ──────────────────────────────────────────────
          _buildHeader(),

          // ── Konten ──────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildMap(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFotoSection(),
                          const SizedBox(height: 16),
                          _buildTugasField(),
                          const SizedBox(height: 16),
                          _buildWaktuSection(context),
                          const SizedBox(height: 16),
                          _buildTipeAktivitasSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildSimpanButton(),
        ],
      ),
    );
  }

  // ── HEADER BIRU ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientMid, _gradientEnd],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Stack(
            children: [
              // Dekorasi
              Positioned(
                right: -20,
                top: -10,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Rekam Aktivitas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── MAP ──────────────────────────────────────────────────────────────
  Widget _buildMap() {
    return Obx(() {
      final pos = controller.currentPosition.value;
      final accuracy = controller.accuracyMeters.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: pos, zoom: 16),
                  onMapCreated: (c) => controller.mapController = c,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('current'),
                      position: pos,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                    ),
                  },
                  circles: {
                    Circle(
                      circleId: const CircleId('accuracy'),
                      center: pos,
                      radius: accuracy,
                      fillColor: _gradientMid.withOpacity(0.2),
                      strokeColor: _gradientMid.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  },
                ),

                if (controller.isLoadingLocation.value)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                if (!controller.isLoadingLocation.value)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          'Akurasi lokasi ${accuracy.toStringAsFixed(0)} meter',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  right: 10,
                  bottom: 50,
                  child: GestureDetector(
                    onTap: controller.refreshLocation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location,
                        size: 20,
                        color: _gradientMid,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── CARD WRAPPER ─────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, {bool required = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: Colors.red, fontSize: 14)),
        ],
      ],
    );
  }

  // ── FOTO ─────────────────────────────────────────────────────────────
  Widget _buildFotoSection() {
    return Obx(() {
      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Foto'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...controller.photos.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          entry.value,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => controller.removePhoto(entry.key),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (controller.photos.length < 5)
                  GestureDetector(
                    onTap: () async {
                      final File? result = await Get.to(
                        () => const CameraPage(),
                        transition: Transition.rightToLeft,
                      );
                      if (result != null) controller.addPhoto(result);
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3EDF8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        size: 28,
                        color: _gradientMid,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── TUGAS ─────────────────────────────────────────────────────────────
  Widget _buildTugasField() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Tugas', required: true),
          const SizedBox(height: 10),
          TextField(
            controller: controller.tugasController,
            decoration: InputDecoration(
              hintText: 'Ketik tugas anda',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gradientMid, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WAKTU ─────────────────────────────────────────────────────────────
  Widget _buildWaktuSection(BuildContext context) {
    return Obx(() {
      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Waktu Aktivitas'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Mulai',
                    value: controller.startTime.value,
                    onTap: () async {
                      final picked = await _pickDateTime(
                        context,
                        controller.startTime.value,
                      );
                      if (picked != null) controller.setStartTime(picked);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Berakhir',
                    value: controller.endTime.value,
                    onTap: () async {
                      final picked = await _pickDateTime(
                        context,
                        controller.endTime.value,
                      );
                      if (picked != null) controller.setEndTime(picked);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    final formatted = DateFormat('HH:mm | dd MMM yyyy', 'id_ID').format(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _bg,
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatted,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
                Icon(Icons.calendar_today, size: 14, color: _gradientMid),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _gradientMid),
        ),
        child: child!,
      ),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _gradientMid),
        ),
        child: child!,
      ),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ── TIPE AKTIVITAS ────────────────────────────────────────────────────
  Widget _buildTipeAktivitasSection() {
    return Obx(() {
      final isLoading = controller.isLoadingTipe.value;
      final isEmpty = controller.tipeAktivitasList.isEmpty;
      final needsTujuan = controller.needsTujuan;
      final needsKendaraan = controller.needsTujuanDanKendaraan;
      final selected = controller.selectedTipeAktivitas.value;

      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Tipe Aktivitas'),
            const SizedBox(height: 10),

            // ── Trigger tap buka bottom sheet ──────────────────
            GestureDetector(
              onTap: isLoading || isEmpty
                  ? (isEmpty ? controller.fetchTipeAktivitas : null)
                  : () => _showTipeBottomSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected != null
                        ? _gradientMid
                        : Colors.grey.shade200,
                    width: selected != null ? 1.5 : 1,
                  ),
                ),
                child: isLoading
                    ? Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _gradientMid,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Memuat tipe aktivitas...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      )
                    : isEmpty
                    ? Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.orange[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gagal memuat — tap untuk retry',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selected != null
                                  ? _gradientMid.withOpacity(0.1)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              selected != null
                                  ? Icons.check_circle_rounded
                                  : Icons.category_outlined,
                              size: 16,
                              color: selected != null
                                  ? _gradientMid
                                  : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selected != null
                                  ? selected['nama'] ?? '-'
                                  : 'Pilih tipe aktivitas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected != null
                                    ? const Color(0xFF1A1F36)
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: selected != null
                                ? _gradientMid
                                : Colors.grey[400],
                          ),
                        ],
                      ),
              ),
            ),

            // ── Tujuan ─────────────────────────────────────────
            if (needsTujuan) ...[
              const SizedBox(height: 14),
              Text(
                'Tujuan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.tujuanController,
                decoration: _inputDecoration('Masukkan tujuan'),
              ),
            ],

            // ── Kendaraan ──────────────────────────────────────
            if (needsKendaraan) ...[
              const SizedBox(height: 14),
              Text(
                'Kendaraan & Nopol',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.kendaraanNopolController,
                decoration: _inputDecoration('Contoh: Motor - H 1234 AB'),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── BOTTOM SHEET TIPE ─────────────────────────────────────────────────
  void _showTipeBottomSheet() {
    final searchController = TextEditingController();
    final filtered = controller.tipeAktivitasList.toList().obs;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Judul
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _gradientMid.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      size: 18,
                      color: _gradientMid,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pilih Tipe Aktivitas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF8A94A6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: searchController,
                autofocus: true,
                onChanged: (val) {
                  final q = val.toLowerCase();
                  filtered.value = controller.tipeAktivitasList
                      .where((t) => (t['nama'] ?? '').toLowerCase().contains(q))
                      .toList();
                },
                decoration: InputDecoration(
                  hintText: 'Cari tipe aktivitas...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                  suffixIcon: Obx(
                    () => filtered.length != controller.tipeAktivitasList.length
                        ? GestureDetector(
                            onTap: () {
                              searchController.clear();
                              filtered.value = controller.tipeAktivitasList
                                  .toList();
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2F4F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _gradientMid,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // List
            Obx(() {
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 40,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tipe tidak ditemukan',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: Get.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, index) {
                    final tipe = filtered[index];
                    final isSelected =
                        controller.selectedTipeAktivitas.value?['id'] ==
                        tipe['id'];

                    return InkWell(
                      onTap: () {
                        controller.selectedTipeAktivitas.value = tipe;
                        controller.tujuanController.clear();
                        controller.kendaraanNopolController.clear();
                        Get.back();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _gradientMid.withOpacity(0.12)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.label_rounded,
                                size: 18,
                                color: isSelected
                                    ? _gradientMid
                                    : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tipe['nama'] ?? '-',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? _gradientMid
                                      : const Color(0xFF1A1F36),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: _gradientMid,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: _bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _gradientMid, width: 1.5),
      ),
    );
  }

  // ── SIMPAN ─────────────────────────────────────────────────────────────
  Widget _buildSimpanButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Obx(
        () => ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.simpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.isLoading.value
                ? Colors.grey[300]
                : _gradientMid,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
