import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/user_lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/user/profilPage/daftar_wajah_page.dart';
import 'package:get/get.dart';
import '../modals/daftar_lokasi_modal.dart';
import '../modals/ganti_password_modal.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  late final AuthController _auth;
  late final UserLokasiController _lokasi;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    _lokasi = Get.find<UserLokasiController>();
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
            child: RefreshIndicator(
              onRefresh: () async => _auth.fetchProfile(),
              color: const Color(0xFFFF7A30),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── HEADER BIRU — ikut scroll ──
                  SliverToBoxAdapter(child: _buildHeader()),

                  // ── KONTEN ABU ──
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
                      child: Obx(() {
                        final user = Map<String, dynamic>.from(_auth.user);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Informasi Akun ──
                            _sectionLabel('Informasi Akun'),
                            const SizedBox(height: 10),
                            _buildAkunCard(user),
                            const SizedBox(height: 20),

                            // ── Data Pribadi ──
                            _sectionLabel('Data Pribadi'),
                            const SizedBox(height: 10),
                            _buildPribadiCard(user),
                            const SizedBox(height: 20),

                            // ── Data Kepegawaian ──
                            _sectionLabel('Data Kepegawaian'),
                            const SizedBox(height: 10),
                            _buildKepegawaianCard(user),
                            const SizedBox(height: 20),

                            // ── Lokasi & Fitur ──
                            _sectionLabel('Pengaturan & Fitur'),
                            const SizedBox(height: 10),
                            _buildFeatureGroup(),
                            const SizedBox(height: 28),

                            // ── Logout ──
                            _buildLogoutButton(),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Obx(() {
      final user = Map<String, dynamic>.from(_auth.user);
      final name = user['name']?.toString() ?? 'User';
      final role =
          user['jabatan']?.toString() ?? user['role']?.toString() ?? '';
      final kantor = user['kantor']?.toString() ?? '';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

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

                // Konten
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris: Title + icon edit
                    Row(
                      children: [
                        const Text(
                          'Profil Saya',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        _whiteIconBtn(Icons.notifications_none_outlined),
                        const SizedBox(width: 8),
                        _whiteIconBtn(Icons.settings_outlined),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Container(height: 1, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 20),

                    // Avatar + info
                    Row(
                      children: [
                        // Avatar lingkaran
                        GestureDetector(
                          onTap:
                              _openFotoViewer, // ← ganti dari _showPhotoOptions
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Hero(
                                tag: 'profile_photo', // ← tambahkan Hero
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.25),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 2.5,
                                    ),
                                    image:
                                        (user['photo_url'] != null &&
                                            user['photo_url']
                                                .toString()
                                                .isNotEmpty)
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              user['photo_url'].toString(),
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child:
                                      (user['photo_url'] == null ||
                                          user['photo_url'].toString().isEmpty)
                                      ? Center(
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              // Badge kamera
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF7A30),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (role.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    role,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              if (kantor.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business_outlined,
                                      size: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        kantor,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showPhotoOptions() {
    final sudahAdaFoto =
        (_auth.user['photo_url'] != null &&
        _auth.user['photo_url'].toString().isNotEmpty);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ganti Foto Profil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _bottomSheetTile(
              icon: Icons.camera_alt_outlined,
              iconColor: const Color(0xFF1565C0),
              title: 'Kamera',
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            _bottomSheetTile(
              icon: Icons.photo_library_outlined,
              iconColor: const Color(0xFF7B2FBE),
              title: 'Galeri',
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (sudahAdaFoto) ...[
              const Divider(height: 16),
              _bottomSheetTile(
                icon: Icons.delete_outline,
                iconColor: const Color(0xFFE53935),
                title: 'Hapus Foto',
                titleColor: const Color(0xFFE53935),
                onTap: () {
                  Get.back();
                  _auth.deletePhoto();
                },
              ),
            ],
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _openFotoViewer() {
    final photoUrl = _auth.user['photo_url']?.toString() ?? '';
    final name = _auth.user['name']?.toString() ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final hasPhoto = photoUrl.isNotEmpty;

    // Jika belum ada foto, langsung buka pilihan
    if (!hasPhoto) {
      _showPhotoOptions();
      return;
    }

    // Tampilkan fullscreen viewer
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            // Tombol edit di pojok kanan atas
            IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Get.back(); // tutup viewer dulu
                Future.delayed(
                  const Duration(milliseconds: 200),
                  _showPhotoOptions,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: Hero(
            tag: 'profile_photo',
            child: InteractiveViewer(
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      transition: Transition.fadeIn,
    );
  }

  Widget _bottomSheetTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor ?? const Color(0xFF1A1F36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null) return;

      // Crop square dulu seperti WhatsApp
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Foto Profil',
            toolbarColor: const Color(0xFF1565C0),
            toolbarWidgetColor: Colors.white,
            statusBarColor: const Color(0xFF1565C0),
            activeControlsWidgetColor: const Color(0xFF1565C0),
            cropStyle: CropStyle.circle, // preview bulat, hasil tetap square
            lockAspectRatio: true,
            hideBottomControls: false,
            initAspectRatio: CropAspectRatioPreset.square,
          ),
          IOSUiSettings(
            title: 'Crop Foto Profil',
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (cropped == null) return;
      await _auth.uploadPhoto(File(cropped.path));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Tidak dapat membuka ${source == ImageSource.camera ? 'kamera' : 'galeri'}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Widget _whiteIconBtn(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // ─── SECTION LABEL ────────────────────────────────────────────────────────

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

  // ─── SHARED CARD ──────────────────────────────────────────────────────────

  Widget _buildCard({
    required List<_RowData> rows,
    Color accentColor = const Color(0xFF1976D2),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final row = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: row.multiline
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(row.icon, color: accentColor, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8A94A6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            row.value.isEmpty ? '-' : row.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: row.valueColor ?? const Color(0xFF1A1F36),
                            ),
                            softWrap: row.multiline,
                            maxLines: row.multiline ? null : 1,
                            overflow: row.multiline
                                ? null
                                : TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (row.trailing != null) row.trailing!,
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  color: Color(0xFFF0F2F5),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── AKUN CARD ────────────────────────────────────────────────────────────

  Widget _buildAkunCard(Map<String, dynamic> user) {
    return _buildCard(
      accentColor: const Color(0xFF1976D2),
      rows: [
        _RowData(
          icon: Icons.person_outline,
          label: 'Nama Lengkap',
          value: user['name']?.toString() ?? '-',
        ),
        _RowData(
          icon: Icons.email_outlined,
          label: 'Email',
          value: user['email']?.toString() ?? '-',
        ),
        _RowData(
          icon: Icons.badge_outlined,
          label: 'Role',
          value: (user['role']?.toString() ?? '-').toUpperCase(),
          valueColor: const Color(0xFF1976D2),
        ),
      ],
    );
  }

  // ─── PRIBADI CARD ─────────────────────────────────────────────────────────

  Widget _buildPribadiCard(Map<String, dynamic> user) {
    return _buildCard(
      accentColor: const Color(0xFF7B2FBE),
      rows: [
        _RowData(
          icon: Icons.credit_card_outlined,
          label: 'NIK',
          value: user['nik']?.toString() ?? '-',
        ),
        _RowData(
          icon: Icons.approval_outlined,
          label: 'Nama Stempel',
          value: user['nama_stempel']?.toString() ?? '-',
        ),
        _RowData(
          icon: Icons.cake_outlined,
          label: 'Tanggal Lahir',
          value: _formatDate(user['tgl_lahir']),
        ),
        _RowData(
          icon: Icons.wc_outlined,
          label: 'Jenis Kelamin',
          value: _formatJK(user['jk']),
        ),
        _RowData(
          icon: Icons.phone_outlined,
          label: 'Nomor Telepon',
          value: user['nomor_telp']?.toString() ?? '-',
        ),
        _RowData(
          icon: Icons.home_outlined,
          label: 'Alamat',
          value: user['alamat']?.toString() ?? '-',
          multiline: true,
        ),
      ],
    );
  }

  // ─── KEPEGAWAIAN CARD ─────────────────────────────────────────────────────

  Widget _buildKepegawaianCard(Map<String, dynamic> user) {
    return _buildCard(
      accentColor: const Color(0xFF00897B),
      rows: [
        _RowData(
          icon: Icons.work_outline,
          label: 'Jabatan',
          value: user['jabatan']?.toString() ?? '-',
        ),
        _RowData(
          icon: Icons.business_outlined,
          label: 'Kantor',
          value: user['kantor']?.toString() ?? '-',
        ),
        _RowData(
          icon: Icons.calendar_today_outlined,
          label: 'Tanggal Masuk',
          value: _formatDate(user['tgl_masuk']),
        ),
      ],
    );
  }

  // ─── FEATURE GROUP (Lokasi, Wajah, Password) ─────────────────────────────

  Widget _buildFeatureGroup() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFeatureTile(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF2E7D32),
            title: 'Lokasi Tersedia',
            subtitleWidget: Obx(() {
              final total = _lokasi.userLokasis.length;
              return Text(
                total > 0 ? '$total Lokasi terdaftar' : 'Belum ada lokasi',
                style: TextStyle(
                  fontSize: 12,
                  color: total > 0
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF8A94A6),
                ),
              );
            }),
            trailingWidget: Obx(() {
              final total = _lokasi.userLokasis.length;
              if (total == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              );
            }),
            onTap: () {
              if (_lokasi.userLokasis.isNotEmpty) {
                DaftarLokasiModal.show(context, _lokasi);
              } else {
                Get.snackbar(
                  'Info',
                  'Belum ada lokasi tersedia',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                );
              }
            },
            isLast: false,
          ),
          _buildFeatureTile(
            icon: Icons.face_retouching_natural,
            iconColor: const Color(0xFFE65100),
            title: 'Daftarkan Wajah',
            subtitleWidget: Obx(() {
              final sudah = _lokasi.wajahTerdaftar.value;
              return Text(
                sudah
                    ? 'Wajah sudah terdaftar — tap untuk perbarui'
                    : 'Belum terdaftar — tap untuk mendaftarkan',
                style: TextStyle(
                  fontSize: 12,
                  color: sudah
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                ),
              );
            }),
            trailingWidget: Obx(() {
              final sudah = _lokasi.wajahTerdaftar.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: sudah
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : const Color(0xFFE65100).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sudah ? 'Aktif' : 'Belum',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sudah
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              );
            }),
            onTap: () => Get.to(() => const DaftarWajahPage()),
            isLast: false,
          ),
          _buildFeatureTile(
            icon: Icons.lock_outline,
            iconColor: const Color(0xFF1565C0),
            title: 'Ganti Password',
            subtitleWidget: const Text(
              'Ubah password akun Anda',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
            ),
            trailingWidget: const SizedBox.shrink(),
            onTap: () => GantiPasswordModal.show(context),
            isLast: false,
          ),
          _buildFeatureTile(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF00897B),
            title: 'Tentang Aplikasi',
            subtitleWidget: const Text(
              'Versi, lisensi & informasi app',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
            ),
            trailingWidget: const SizedBox.shrink(),
            onTap: () => _showTentangAplikasi(),
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _showTentangAplikasi() {
    Get.to(
      () => Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1F36),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Tentang Aplikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F36),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Get.back(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Logo & Nama App ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'MyAbsensi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Versi 1.0.0',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sistem Absensi Digital',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Info Aplikasi ──
              _tentangCard(
                label: 'Informasi Aplikasi',
                accentColor: const Color(0xFF1565C0),
                rows: [
                  _tentangRow(
                    icon: Icons.apps_rounded,
                    label: 'Nama Aplikasi',
                    value: 'MyAbsensi',
                  ),
                  _tentangRow(
                    icon: Icons.tag_rounded,
                    label: 'Versi',
                    value: '1.0.0',
                  ),
                  _tentangRow(
                    icon: Icons.build_outlined,
                    label: 'Build Number',
                    value: '1',
                  ),
                  _tentangRow(
                    icon: Icons.phone_android_rounded,
                    label: 'Platform',
                    value: 'Android & iOS',
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Developer ──
              _tentangCard(
                label: 'Developer',
                accentColor: const Color(0xFF7B2FBE),
                rows: [
                  _tentangRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Dikembangkan oleh',
                    value: 'Hikmatyar A Leghari',
                  ),
                  _tentangRow(
                    icon: Icons.business_outlined,
                    label: 'Organisasi',
                    value: 'Bagian EBD',
                  ),
                  _tentangRow(
                    icon: Icons.email_outlined,
                    label: 'Kontak',
                    value: 'hickmatyarleghari@gmail.com',
                  ),
                  _tentangRow(
                    icon: Icons.phone_outlined,
                    label: 'WhatsApp',
                    value: '085799845031',
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Teknologi ──
              _tentangCard(
                label: 'Teknologi',
                accentColor: const Color(0xFF00897B),
                rows: [
                  _tentangRow(
                    icon: Icons.flutter_dash_rounded,
                    label: 'Frontend',
                    value: 'Flutter',
                  ),
                  _tentangRow(
                    icon: Icons.storage_outlined,
                    label: 'Backend',
                    value: 'Laravel',
                  ),
                  _tentangRow(
                    icon: Icons.face_retouching_natural,
                    label: 'Face Recognition',
                    value: 'DeepFace',
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Copyright ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.copyright_rounded,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateTime.now().year} MyAbsensi. All rights reserved.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      transition: Transition.rightToLeft,
    );
  }

  // ─── HELPER WIDGET TENTANG ────────────────────────────────────────────────

  Widget _tentangCard({
    required String label,
    required Color accentColor,
    required List<Widget> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A94A6),
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _tentangRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1565C0), size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A94A6),
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1F36),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 68,
            color: Color(0xFFF0F2F5),
          ),
      ],
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget subtitleWidget,
    required Widget trailingWidget,
    required VoidCallback onTap,
    required bool isLast,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      const SizedBox(height: 2),
                      subtitleWidget,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailingWidget,
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF8A94A6),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 68,
            color: Color(0xFFF0F2F5),
          ),
      ],
    );
  }

  // ─── LOGOUT ───────────────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE53935).withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFE53935),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Keluar dari Akun',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE53935),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFE53935),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Konfirmasi Logout',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apakah Anda yakin ingin keluar dari akun ini?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        _auth.logout();
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE53935).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final dt = value is DateTime ? value : DateTime.parse(value.toString());
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatJK(dynamic value) {
    if (value == null) return '-';
    switch (value.toString().toUpperCase()) {
      case 'L':
        return 'Laki-laki';
      case 'P':
        return 'Perempuan';
      default:
        return value.toString();
    }
  }
}

// ─── DATA HELPER CLASS ─────────────────────────────────────────────────────

class _RowData {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool multiline;
  final Widget? trailing;

  const _RowData({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.multiline = false,
    this.trailing,
  });
}
