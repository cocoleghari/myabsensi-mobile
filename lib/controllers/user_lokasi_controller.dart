import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:myabsensi_mobile/pages/user/userPage/daftar_wajah_page.dart';
import 'package:myabsensi_mobile/pages/user/userPage/preview_absensi_page.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'app_config.dart';
import 'auth_controller.dart';
import 'package:myabsensi_mobile/pages/user/userPage/camera_page.dart';

class UserLokasiController extends GetxController {
  final auth = Get.find<AuthController>();

  var userLokasis = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var errorMessage = ''.obs;

  var riwayatAbsensi = <Map<String, dynamic>>[].obs;
  var isLoadingRiwayat = false.obs;

  var sudahMasuk = false.obs;
  var sudahPulang = false.obs;
  var dataMasuk = Rxn<Map<String, dynamic>>();
  var dataPulang = Rxn<Map<String, dynamic>>();

  var lokasiSaatIni = ''.obs;
  var isGettingLocation = false.obs;

  var fotoWajah = Rxn<File>();
  var isTakingPhoto = false.obs;
  var isDetectingFace = false.obs;

  var lokasiTerpilih = Rxn<Map<String, dynamic>>();
  var jarakTerdekat = 0.0.obs;
  var isInRange = false.obs;

  var wajahTerdaftar = false.obs;
  var fotoReferensiUrl = ''.obs;

  var akurasiLokasi = 0.0.obs;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    print('UserLokasiController diinisialisasi');
    _initAndLoad();
    _checkPlatform();
  }

  Future<void> _initAndLoad() async {
    _baseUrl = await AppConfig.getBaseUrl();
    cekStatusHariIni();
    fetchUserLokasi();
    cekStatusWajah();
    _loadFotoReferensi();
  }

  Future<String> get _resolvedBaseUrl async {
    if (_baseUrl.isEmpty) _baseUrl = await AppConfig.getBaseUrl();
    return _baseUrl;
  }

  void _checkPlatform() {
    if (kIsWeb) {
      print('Aplikasi berjalan di WEB - fitur kamera tidak tersedia');
    } else {
      print('Aplikasi berjalan di MOBILE');
    }
  }

  Future<void> cekStatusHariIni() async {
    try {
      print('Cek status absen hari ini...');

      if (auth.token.isEmpty) {
        print('Token kosong');
        return;
      }

      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/absensi/cek-status'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        sudahMasuk.value = data['sudah_masuk'] ?? false;
        sudahPulang.value = data['sudah_pulang'] ?? false;
        dataMasuk.value = data['data_masuk'];
        dataPulang.value = data['data_pulang'];

        print('Status Absen: Masuk=$sudahMasuk, Pulang=$sudahPulang');
      }
    } catch (e) {
      print('Error cek status: $e');
    }
  }

  Future<void> fetchUserLokasi() async {
    if (auth.token.isEmpty) {
      return;
    }

    try {
      print('FETCH USER LOKASI - BACKGROUND');

      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/lokasi'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is List) {
          userLokasis.value = List<Map<String, dynamic>>.from(data);
          print('Lokasi ditemukan: ${userLokasis.length} data');

          if (userLokasis.isEmpty) {
            errorMessage.value = 'Belum ada lokasi yang ditentukan untuk Anda';
          }
        } else {
          userLokasis.value = [];
        }
      } else if (response.statusCode == 401) {
        errorMessage.value = 'Sesi habis, silahkan login ulang';
        Future.delayed(const Duration(seconds: 2), () => auth.logout());
      }
    } catch (e) {
      print('Error fetchUserLokasi: $e');
    }
  }

  Future<bool> _detectFace(File imageFile) async {
    if (kIsWeb) {
      _showWebNotSupportedDialog();
      return false;
    }

    isDetectingFace.value = true;

    try {
      final inputImage = InputImage.fromFile(imageFile);

      final options = FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: true,
        performanceMode: FaceDetectorMode.fast,
      );

      final faceDetector = FaceDetector(options: options);
      final List<Face> faces = await faceDetector.processImage(inputImage);
      faceDetector.close();

      print('Jumlah wajah terdeteksi: ${faces.length}');

      if (faces.isEmpty) {
        Get.snackbar(
          'Gagal',
          'Tidak ada wajah terdeteksi',
          backgroundColor: Colors.red,
        );
        return false;
      }

      if (faces.length > 1) {
        Get.snackbar(
          'Gagal',
          'Terlalu banyak wajah',
          backgroundColor: Colors.orange,
        );
        return false;
      }

      Face face = faces.first;

      if (face.boundingBox.width < 100 || face.boundingBox.height < 100) {
        Get.snackbar(
          'Kualitas Rendah',
          'Wajah terlalu kecil',
          backgroundColor: Colors.orange,
        );
        return false;
      }

      return true;
    } catch (e) {
      print('Error face detection: $e');
      return false;
    } finally {
      isDetectingFace.value = false;
    }
  }

  Future<File?> takePhotoWithFaceDetection() async {
    if (kIsWeb) {
      _showWebNotSupportedDialog();
      return null;
    }

    isTakingPhoto.value = true;

    try {
      // Buka custom camera screen — langsung kamera depan
      final File? imageFile = await Get.to<File>(
        () => const CameraPage(),
        transition: Transition.downToUp,
        duration: const Duration(milliseconds: 250),
      );

      // User menutup kamera tanpa foto
      if (imageFile == null) {
        return null;
      }

      // Deteksi wajah
      bool isFaceValid = await _detectFace(imageFile);

      if (!isFaceValid) {
        bool retry = await _showRetryDialog();
        if (retry) {
          return await takePhotoWithFaceDetection();
        } else {
          return null;
        }
      }

      fotoWajah.value = imageFile;
      return fotoWajah.value;
    } catch (e) {
      print('Error take photo: $e');
      Get.snackbar(
        'Error',
        'Gagal membuka kamera: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isTakingPhoto.value = false;
    }
  }

  void _showWebNotSupportedDialog() {
    Get.dialog(
      AlertDialog(
        title: const Icon(Icons.info_outline, color: Colors.orange, size: 48),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Akses Kamera Tidak Tersedia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aplikasi ini diakses melalui browser.\n\n'
              'Fitur kamera hanya tersedia di aplikasi mobile.\n\n'
              'Silakan gunakan aplikasi Android untuk melakukan absensi dengan foto.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Anda masih dapat melihat riwayat dan status absensi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('MENGERTI'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showRetryDialog() async {
    final result = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header berwarna ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              color: Colors.orange[50],
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 30,
                          color: Colors.orange[700],
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Foto tidak valid',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Wajah tidak terdeteksi dengan jelas.\nPastikan pencahayaan cukup dan\nhadap kamera langsung.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  // Tips box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          size: 15,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Foto di tempat terang  ·  Hadap kamera langsung  ·  Lepas kacamata  ·  Satu wajah saja',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tombol Foto Ulang
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.back(result: true),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text(
                        'Foto Ulang',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tombol Batal
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Get.back(result: false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  Future<String> getCurrentLocation() async {
    isGettingLocation.value = true;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Izin Ditolak',
            'Izin lokasi diperlukan',
            backgroundColor: Colors.orange,
          );
          return '';
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Simpan akurasi
      akurasiLokasi.value = position.accuracy;

      String koordinat = '${position.latitude}, ${position.longitude}';
      lokasiSaatIni.value = koordinat;
      return koordinat;
    } catch (e) {
      print('Error getCurrentLocation: $e');
      Get.snackbar(
        'Error',
        'Gagal mendapatkan lokasi. Pastikan GPS aktif.',
        backgroundColor: Colors.red,
      );
      return '';
    } finally {
      isGettingLocation.value = false;
    }
  }

  double _hitungJarakDalamMeter(LatLng titik1, LatLng titik2) {
    const double R = 6371;

    double lat1 = titik1.latitude * pi / 180;
    double lat2 = titik2.latitude * pi / 180;
    double deltaLat = (titik2.latitude - titik1.latitude) * pi / 180;
    double deltaLng = (titik2.longitude - titik1.longitude) * pi / 180;

    double a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distanceKm = R * c;

    return distanceKm * 1000;
  }

  Future<Map<String, dynamic>?> cariLokasiTerdekat(String koordinatUser) async {
    if (userLokasis.isEmpty) {
      await fetchUserLokasi();
    }

    if (userLokasis.isEmpty) {
      Get.snackbar(
        'Error',
        'Anda belum memiliki lokasi absensi. Hubungi admin.',
        backgroundColor: Colors.red,
      );
      return null;
    }

    try {
      final userParts = koordinatUser.split(',');
      if (userParts.length != 2) return null;

      final userLat = double.tryParse(userParts[0].trim());
      final userLng = double.tryParse(userParts[1].trim());

      if (userLat == null || userLng == null) return null;

      final userLatLng = LatLng(userLat, userLng);

      List<Map<String, dynamic>> lokasiDenganJarak = [];

      for (var lokasi in userLokasis) {
        final lokasiParts = lokasi['koordinat'].split(',');
        if (lokasiParts.length != 2) continue;

        final lokasiLat = double.tryParse(lokasiParts[0].trim());
        final lokasiLng = double.tryParse(lokasiParts[1].trim());

        if (lokasiLat == null || lokasiLng == null) continue;

        final lokasiLatLng = LatLng(lokasiLat, lokasiLng);
        final jarak = _hitungJarakDalamMeter(userLatLng, lokasiLatLng);

        lokasiDenganJarak.add({
          'id': lokasi['id'],
          'lokasi': lokasi['lokasi'],
          'koordinat': lokasi['koordinat'],
          'jarak': jarak,
          'dalam_radius': jarak <= 100,
        });
      }

      lokasiDenganJarak.sort((a, b) => a['jarak'].compareTo(b['jarak']));

      if (lokasiDenganJarak.isNotEmpty) {
        lokasiTerpilih.value = lokasiDenganJarak.first;
        jarakTerdekat.value = lokasiDenganJarak.first['jarak'];
        isInRange.value = lokasiDenganJarak.first['dalam_radius'];

        print('Lokasi terdekat: ${lokasiTerpilih.value!['lokasi']}');
        print('Jarak: ${jarakTerdekat.value.toStringAsFixed(2)} meter');
        print('Dalam radius: $isInRange');
      }

      return lokasiDenganJarak.first;
    } catch (e) {
      print('Error cari lokasi terdekat: $e');
      return null;
    }
  }

  Future<void> prosesAbsensi(String tipe) async {
    if (userLokasis.isEmpty) {
      await fetchUserLokasi();
      if (userLokasis.isEmpty) {
        Get.snackbar(
          'Error',
          'Belum ada lokasi absensi. Hubungi admin.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    // ── CEK WAJAH TERDAFTAR ──────────────────────────────────────────
    if (!wajahTerdaftar.value) {
      await _showWajahBelumTerdaftarDialog();
      return;
    }

    if (tipe == 'masuk' && sudahMasuk.value) {
      Get.snackbar(
        'Info',
        'Anda sudah absen masuk hari ini',
        backgroundColor: Colors.orange,
      );
      return;
    }
    if (tipe == 'pulang' && sudahPulang.value) {
      Get.snackbar(
        'Info',
        'Anda sudah absen pulang hari ini',
        backgroundColor: Colors.orange,
      );
      return;
    }
    if (tipe == 'pulang' && !sudahMasuk.value) {
      Get.snackbar(
        'Info',
        'Anda harus absen masuk terlebih dahulu',
        backgroundColor: Colors.orange,
      );
      return;
    }

    isSubmitting.value = true;

    try {
      // 1. Ambil koordinat
      String koordinat = await getCurrentLocation();
      if (koordinat.isEmpty) return;

      // 2. Cari lokasi terdekat
      final lokasiTerdekat = await cariLokasiTerdekat(koordinat);
      if (lokasiTerdekat == null) return;

      // 3. Ambil foto wajah
      File? foto = await takePhotoWithFaceDetection();
      if (foto == null) {
        Get.snackbar(
          'Info',
          'Absen dibatalkan',
          backgroundColor: Colors.orange,
        );
        return;
      }

      // 4. Cek face recognition via backend (preview saja, belum simpan)
      final hasilFace = await _cekFaceRecognitionSaja(foto);

      // 5. Ambil URL foto referensi user
      final fotoReferensiUrl = await _getFotoReferensiUrl();

      // 6. Navigasi ke halaman preview
      Get.to(
        () => PreviewAbsensiPage(
          tipe: tipe,
          fotoAbsen: foto,
          fotoReferensiUrl: fotoReferensiUrl,
          lokasiTerdekat: lokasiTerdekat,
          koordinatUser: koordinat,
          confidenceScore: hasilFace['confidence'] ?? 0.0,
          wajahCocok: hasilFace['verified'] ?? false,
          akurasi: akurasiLokasi.value, // ← tambahkan ini
        ),
      );
    } catch (e) {
      print('Error prosesAbsensi: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // Load & cache foto referensi sekali saja
  Future<void> _loadFotoReferensi() async {
    try {
      if (auth.token.isEmpty) return;
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/profil'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        fotoReferensiUrl.value = data['foto_wajah_url']?.toString() ?? '';
        wajahTerdaftar.value =
            data['wajah_terdaftar'] == true || data['wajah_terdaftar'] == 1;
        print('Foto referensi URL: ${fotoReferensiUrl.value}');
      }
    } catch (e) {
      print('Error _loadFotoReferensi: $e');
    }
  }

  // Cek face recognition tanpa simpan absensi
  Future<Map<String, dynamic>> _cekFaceRecognitionSaja(File foto) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/wajah/verifikasi'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer ${auth.token}',
      });
      request.files.add(
        await http.MultipartFile.fromPath('foto_wajah', foto.path),
      );

      var streamed = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'verified': false, 'confidence': 0.0};
    } catch (e) {
      print('Error cek face: $e');
      return {'verified': false, 'confidence': 0.0};
    }
  }

  // Update _getFotoReferensiUrl — cukup return cache
  Future<String> _getFotoReferensiUrl() async {
    if (fotoReferensiUrl.value.isNotEmpty) return fotoReferensiUrl.value;
    await _loadFotoReferensi();
    return fotoReferensiUrl.value;
  }

  // Dipanggil dari PreviewAbsensiPage saat tap "Save Attendance"
  Future<bool> kirimAbsensiDariPreview({
    required Map<String, dynamic> lokasiTerpilih,
    required String titikKoordinatKamu,
    required File foto,
    required String tipe,
  }) async {
    isSubmitting.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/absensi/otomatis'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer ${auth.token}',
      });

      request.fields['tipe_absen'] = tipe;
      request.fields['titik_koordinat_kamu'] = titikKoordinatKamu;

      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_wajah',
          foto.path,
          filename: '${tipe}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      var streamed = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamed);

      print('Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Hanya update status, JANGAN fetch riwayat di sini
        await cekStatusHariIni();
        return true;
      } else {
        try {
          final err = jsonDecode(response.body);
          Get.snackbar(
            'Gagal',
            err['message'] ?? 'Gagal menyimpan',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } catch (_) {
          Get.snackbar(
            'Gagal',
            'Error ${response.statusCode}',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
        return false;
      }
    } catch (e) {
      print('Error: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> _kirimAbsensiOtomatis(
    Map<String, dynamic> lokasiTerpilih,
    String titikKoordinatKamu,
    File foto,
    String tipe,
  ) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/absensi/otomatis'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer ${auth.token}',
      });

      request.fields['tipe_absen'] = tipe;
      request.fields['titik_koordinat_kamu'] = titikKoordinatKamu;

      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_wajah',
          foto.path,
          filename: '${tipe}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      print('Mengirim request absensi otomatis $tipe...');
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        Get.snackbar(
          'Gagal',
          errorData['message'] ?? 'Anda berada di luar jangkauan absen',
          backgroundColor: Colors.red,
        );
        return false;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          Get.snackbar(
            'Gagal',
            errorData['message'] ?? 'Gagal absen',
            backgroundColor: Colors.red,
          );
        } catch (e) {
          Get.snackbar(
            'Gagal',
            'Error ${response.statusCode}',
            backgroundColor: Colors.red,
          );
        }
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      return false;
    }
  }

  void _showSuccessDialog(String tipe, Map<String, dynamic> lokasiTerpilih) {
    Get.dialog(
      AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Absen $tipe Berhasil!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Anda telah absen $tipe di:'),
            const SizedBox(height: 4),
            Text(
              lokasiTerpilih['lokasi'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Jarak: ${lokasiTerpilih['jarak'].toStringAsFixed(1)} meter',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Waktu: ${DateTime.now().toString().substring(0, 16)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              cekStatusHariIni();
              fetchUserLokasi();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJarakTerlaluJauhDialog(
    double jarak,
    String lokasiTerdekat,
  ) async {
    String jarakFormat = jarak < 1000
        ? '${jarak.toStringAsFixed(1)} meter'
        : '${(jarak / 1000).toStringAsFixed(2)} km';

    return Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Anda tidak bisa absen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anda di luar jangkauan absen',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Batas maksimal 100 meter',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Lokasi terdekat: $lokasiTerdekat',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jarak Anda $jarakFormat',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'MENGERTI',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchRiwayatAbsensi() async {
    if (auth.token.isEmpty) return;

    isLoadingRiwayat.value = true;

    try {
      print('Fetching riwayat absensi...');

      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/absensi/riwayat'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          riwayatAbsensi.value = List<Map<String, dynamic>>.from(data);
        } else {
          riwayatAbsensi.value = [];
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      isLoadingRiwayat.value = false;
    }
  }

  void reset() {
    userLokasis.clear();
    riwayatAbsensi.clear();
    errorMessage.value = '';
    isLoading.value = false;
    isLoadingRiwayat.value = false;
    lokasiSaatIni.value = '';
    fotoWajah.value = null;
    sudahMasuk.value = false;
    sudahPulang.value = false;
    dataMasuk.value = null;
    dataPulang.value = null;
    lokasiTerpilih.value = null;
    jarakTerdekat.value = 0.0;
    isInRange.value = false;
  }

  void printDebugInfo() {
    print('=' * 50);
    print('USER LOKASI CONTROLLER');
    print('Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
    print('BaseUrl: $_baseUrl');
    print('Token: ${auth.token.isNotEmpty ? "Ada" : "Kosong"}');
    print('Role: ${auth.user['role']}');
    print('Lokasi: ${userLokasis.length}');
    print('Riwayat: ${riwayatAbsensi.length}');
    print('Status Masuk: $sudahMasuk');
    print('Status Pulang: $sudahPulang');
    print('Lokasi Saat Ini: ${lokasiSaatIni.value}');
    print('Lokasi Terdekat: ${lokasiTerpilih.value?['lokasi'] ?? '-'}');
    print('Jarak Terdekat: ${jarakTerdekat.value.toStringAsFixed(2)} meter');
    print('Dalam Radius: $isInRange');
    print('Loading: $isLoading');
    print('Submitting: $isSubmitting');
    print('=' * 50);
  }

  // Update daftarkanWajah — simpan URL setelah berhasil daftar
  Future<void> daftarkanWajah() async {
    final foto = fotoWajah.value;
    if (foto == null) {
      Get.snackbar(
        'Error',
        'Ambil foto terlebih dahulu',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/wajah/daftarkan'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer ${auth.token}',
      });
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_wajah',
          foto.path,
          filename: 'wajah_${auth.user['id']}.jpg',
        ),
      );

      var streamed = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        wajahTerdaftar.value = true;
        fotoReferensiUrl.value = data['foto_wajah_url']?.toString() ?? '';
        fotoWajah.value = null;

        Get.dialog(
          AlertDialog(
            title: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Wajah Berhasil Didaftarkan!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Anda sekarang dapat melakukan absensi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.back();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar(
          'Gagal',
          err['message'] ?? 'Gagal mendaftarkan wajah',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal: $e', backgroundColor: Colors.red);
    } finally {
      isSubmitting.value = false;
    }
  }

  // Update cekStatusWajah — gunakan _loadFotoReferensi
  Future<void> cekStatusWajah() async {
    await _loadFotoReferensi();
  }

  Future<void> _showWajahBelumTerdaftarDialog() async {
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.face_retouching_natural,
                  color: Colors.orange[700],
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Wajah Belum Terdaftar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Anda perlu mendaftarkan wajah terlebih dahulu sebelum melakukan absensi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.to(() => const DaftarWajahPage());
                  },
                  icon: const Icon(Icons.face_retouching_natural),
                  label: const Text(
                    'Daftarkan Wajah Sekarang',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Nanti Saja'),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
