import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:myabsensi_mobile/controllers/offline_absensi_controller.dart';
import 'package:myabsensi_mobile/pages/user/profilPage/daftar_wajah_page.dart';
import 'package:myabsensi_mobile/pages/user/absenPage/preview_absensi_page.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'app_config.dart';
import 'auth_controller.dart';
import 'package:myabsensi_mobile/pages/user/userPage/camera_page.dart';
import 'package:image/image.dart' as img; // tambah di pubspec juga

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

  var shiftHariIni = Rxn<Map<String, dynamic>>();

  var latitudeSekarang = 0.0.obs;
  var longitudeSekarang = 0.0.obs;
  var isGettingLocation = false.obs;
  var akurasiLokasi = 0.0.obs;

  var fotoWajah = Rxn<File>();
  var isTakingPhoto = false.obs;
  var isDetectingFace = false.obs;

  var lokasiTerpilih = Rxn<Map<String, dynamic>>();
  var jarakTerdekat = 0.0.obs;
  var isInRange = false.obs;

  var wajahTerdaftar = false.obs;
  var fotoReferensiUrl = ''.obs;

  String _baseUrl = '';
  String get baseUrl => _baseUrl;

  @override
  void onInit() {
    super.onInit();
    _initAndLoad();
    _checkPlatform();
  }

  Future<void> _initAndLoad() async {
    _baseUrl = await AppConfig.getBaseUrl();
    await Future.wait([
      cekStatusHariIni(),
      fetchUserLokasi(),
      _loadFotoReferensi(),
    ]);
  }

  Future<String> get _resolvedBaseUrl async {
    if (_baseUrl.isEmpty) _baseUrl = await AppConfig.getBaseUrl();
    return _baseUrl;
  }

  void _checkPlatform() {
    if (kIsWeb) {
      debugPrint('Aplikasi berjalan di WEB - fitur kamera tidak tersedia');
    } else {
      debugPrint('Aplikasi berjalan di MOBILE');
    }
  }

  // ── Shortcut token yang aman ──────────────────────────────────────────────
  // RxString harus diakses via .value agar interpolasi menghasilkan string token
  // asli, bukan "RxString<String>(...)"
  String get _token => auth.token.value;

  // ===========================================================================
  // CEK STATUS HARI INI
  // GET /user/absensi/cek-status
  // ===========================================================================

  Future<void> cekStatusHariIni() async {
    try {
      if (_token.isEmpty) return;

      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/absensi/cek-status'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $_token',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        sudahMasuk.value = data['sudah_masuk'] ?? false;
        sudahPulang.value = data['sudah_pulang'] ?? false;
        dataMasuk.value = data['data_masuk'] != null
            ? Map<String, dynamic>.from(data['data_masuk'])
            : null;
        dataPulang.value = data['data_pulang'] != null
            ? Map<String, dynamic>.from(data['data_pulang'])
            : null;

        // FIX: simpan shift dari level atas response
        // Backend mengembalikan: { "shift": { "nama", "jam_masuk", "jam_pulang" }, ... }
        // Ini BERBEDA dari data_masuk['shift'] yang hanya berisi { id, nama, kode }
        shiftHariIni.value = data['shift'] != null
            ? Map<String, dynamic>.from(data['shift'])
            : null;
      }
    } catch (e) {
      debugPrint('Error cek status: $e');
    }
  }

  // ===========================================================================
  // FETCH USER LOKASI
  // GET /user/lokasi
  //
  // Response per item:
  // {
  //   id, pusat_lokasi_id, nama_lokasi, titik_kordinat,
  //   latitude (double), longitude (double), radius_meter, is_active
  // }
  // ===========================================================================

  Future<void> fetchUserLokasi() async {
    if (_token.isEmpty) return; // ← FIX

    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/lokasi'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $_token', // ← FIX
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic rawData = jsonDecode(response.body);

        List<dynamic> rawList = [];
        if (rawData is Map && rawData['data'] is List) {
          rawList = rawData['data'];
        } else if (rawData is List) {
          rawList = rawData;
        }

        userLokasis.value = rawList
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        if (userLokasis.isEmpty) {
          errorMessage.value = 'Belum ada lokasi yang ditentukan untuk Anda';
        } else {
          errorMessage.value = '';
        }
      } else if (response.statusCode == 401) {
        errorMessage.value = 'Sesi habis, silahkan login ulang';
        // HAPUS baris ini:
        // Future.delayed(const Duration(seconds: 2), () => auth.logout());

        // Ganti dengan:
        auth.logout(); // biarkan AuthController yang handle
      } else if (response.statusCode == 403) {
        errorMessage.value = 'Profil karyawan tidak ditemukan. Hubungi admin.';
      }
    } catch (e) {
      debugPrint('Error fetchUserLokasi: $e');
    }
  }

  // ===========================================================================
  // FACE DETECTION (client-side)
  // ===========================================================================

  Future<bool> _detectFace(File imageFile) async {
    if (kIsWeb) {
      _showWebNotSupportedDialog();
      return false;
    }

    isDetectingFace.value = true;

    try {
      // Fix orientasi gambar dari kamera depan
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return false;

      // Fix EXIF rotation dan mirror kamera depan
      final fixed = img.bakeOrientation(decoded);
      final fixedFile = File(imageFile.path)
        ..writeAsBytesSync(img.encodeJpg(fixed));

      final inputImage = InputImage.fromFile(fixedFile);
      final options = FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: true,
        performanceMode: FaceDetectorMode.accurate, // ganti ke accurate
      );

      final faceDetector = FaceDetector(options: options);
      final List<Face> faces = await faceDetector.processImage(inputImage);
      faceDetector.close();

      if (faces.isEmpty) {
        Get.snackbar(
          'Gagal',
          'Tidak ada wajah terdeteksi',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
      if (faces.length > 1) {
        Get.snackbar(
          'Gagal',
          'Terlalu banyak wajah terdeteksi',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      final face = faces.first;
      if (face.boundingBox.width < 100 || face.boundingBox.height < 100) {
        Get.snackbar(
          'Kualitas Rendah',
          'Wajah terlalu kecil, dekatkan ke kamera',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error face detection: $e');
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
      final File? imageFile = await Get.to<File>(
        () => const CameraPage(),
        transition: Transition.downToUp,
        duration: const Duration(milliseconds: 250),
      );

      if (imageFile == null) return null;

      bool isFaceValid = await _detectFace(imageFile);

      if (!isFaceValid) {
        bool retry = await _showRetryDialog();
        if (retry) return await takePhotoWithFaceDetection();
        return null;
      }

      fotoWajah.value = imageFile;
      return fotoWajah.value;
    } catch (e) {
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

  // ===========================================================================
  // GET CURRENT LOCATION
  // ===========================================================================

  Future<LatLng?> getCurrentLocation() async {
    isGettingLocation.value = true;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Izin Ditolak',
            'Izin lokasi diperlukan untuk absensi',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Izin Ditolak Permanen',
          'Aktifkan izin lokasi di pengaturan',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      latitudeSekarang.value = position.latitude;
      longitudeSekarang.value = position.longitude;
      akurasiLokasi.value = position.accuracy;

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getCurrentLocation: $e');
      Get.snackbar(
        'Error',
        'Gagal mendapatkan lokasi. Pastikan GPS aktif.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isGettingLocation.value = false;
    }
  }

  // ===========================================================================
  // CARI LOKASI TERDEKAT
  //
  // Membaca field dari response /user/lokasi:
  //   latitude, longitude  ← double, sudah diparsing backend
  //   radius_meter         ← int, per relasi
  //   nama_lokasi          ← string
  //   pusat_lokasi_id      ← untuk referensi
  // ===========================================================================

  double _hitungJarakMeter(LatLng titik1, LatLng titik2) {
    const double R = 6371000;
    final lat1 = titik1.latitude * pi / 180;
    final lat2 = titik2.latitude * pi / 180;
    final dLat = (titik2.latitude - titik1.latitude) * pi / 180;
    final dLng = (titik2.longitude - titik1.longitude) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<Map<String, dynamic>?> cariLokasiTerdekat(LatLng userPos) async {
    if (userLokasis.isEmpty) await fetchUserLokasi();

    if (userLokasis.isEmpty) {
      Get.snackbar(
        'Error',
        'Belum ada lokasi absensi. Hubungi admin.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }

    try {
      final results = <Map<String, dynamic>>[];

      for (var lokasi in userLokasis) {
        if (lokasi['is_active'] == false) continue;

        // ── FIX: baca latitude & longitude langsung (sudah double dari backend) ──
        final lokasiLat = (lokasi['latitude'] as num?)?.toDouble();
        final lokasiLng = (lokasi['longitude'] as num?)?.toDouble();

        if (lokasiLat == null || lokasiLng == null) continue;

        final lokasiPos = LatLng(lokasiLat, lokasiLng);
        final jarak = _hitungJarakMeter(userPos, lokasiPos);
        final radius = (lokasi['radius_meter'] as num?)?.toDouble() ?? 100.0;

        results.add({
          'id': lokasi['id'],
          'pusat_lokasi_id': lokasi['pusat_lokasi_id'],
          'nama_lokasi': lokasi['nama_lokasi'] ?? '-', // ← FIX: field benar
          'jarak': jarak,
          'radius_meter': radius,
          'dalam_radius': jarak <= radius,
        });
      }

      if (results.isEmpty) return null;

      results.sort(
        (a, b) => (a['jarak'] as double).compareTo(b['jarak'] as double),
      );

      lokasiTerpilih.value = results.first;
      jarakTerdekat.value = results.first['jarak'];
      isInRange.value = results.first['dalam_radius'];

      return results.first;
    } catch (e) {
      debugPrint('Error cari lokasi terdekat: $e');
      return null;
    }
  }

  // ===========================================================================
  // PROSES ABSENSI
  // ===========================================================================

  Future<void> prosesAbsensi(String tipe) async {
    if (userLokasis.isEmpty) {
      await fetchUserLokasi();
    }

    if (!wajahTerdaftar.value) {
      await _showWajahBelumTerdaftarDialog();
      return;
    }

    if (tipe == 'masuk' && sudahMasuk.value) {
      Get.snackbar(
        'Info',
        'Anda sudah absen masuk hari ini',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (tipe == 'pulang' && sudahPulang.value) {
      Get.snackbar(
        'Info',
        'Anda sudah absen pulang hari ini',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (tipe == 'pulang' && !sudahMasuk.value) {
      Get.snackbar(
        'Info',
        'Anda harus absen masuk terlebih dahulu',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isSubmitting.value = true;

    try {
      // Cek koneksi
      final offline = Get.find<OfflineAbsensiController>();
      final isOffline = !offline.isOnline.value;

      // Ambil lokasi
      final userPos = await getCurrentLocation();
      if (userPos == null) return;

      // Ambil foto
      final foto = await takePhotoWithFaceDetection();
      if (foto == null) {
        Get.snackbar(
          'Info',
          'Absen dibatalkan',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      if (isOffline) {
        // ── MODE OFFLINE → ke PreviewAbsensiPage dengan flag isOffline ──
        Get.to(
          () => PreviewAbsensiPage(
            tipe: tipe,
            fotoAbsen: foto,
            fotoReferensiUrl: '',
            lokasiTerdekat: {},
            koordinatUser: '${userPos.latitude},${userPos.longitude}',
            confidenceScore: 0.0,
            wajahCocok: false,
            akurasi: akurasiLokasi.value,
            isOffline: true,
          ),
        );
      } else {
        // ── MODE ONLINE → flow normal dengan face recognition & lokasi ──
        final lokasiTerdekat = await cariLokasiTerdekat(userPos);
        if (lokasiTerdekat == null) return;

        final hasilFace = await _cekFaceRecognitionSaja(foto);
        final fotoRef = await _getFotoReferensiUrl();

        Get.to(
          () => PreviewAbsensiPage(
            tipe: tipe,
            fotoAbsen: foto,
            fotoReferensiUrl: fotoRef,
            lokasiTerdekat: lokasiTerdekat,
            koordinatUser: '${userPos.latitude},${userPos.longitude}',
            confidenceScore: hasilFace['confidence'] ?? 0.0,
            wajahCocok: hasilFace['verified'] ?? false,
            akurasi: akurasiLokasi.value,
            isOffline: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error prosesAbsensi: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===========================================================================
  // KIRIM ABSENSI KE BACKEND
  // POST /user/absensi/otomatis
  // ===========================================================================

  Future<bool> kirimAbsensiDariPreview({
    required Map<String, dynamic> lokasiTerpilih,
    required String koordinatUser,
    required File foto,
    required String tipe,
    String? catatan,
  }) async {
    isSubmitting.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;

      // FIX: parse koordinat dari parameter, bukan dari latitudeSekarang.value
      final coords = koordinatUser.split(',');
      final lat = coords[0].trim();
      final lng = coords[1].trim();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/absensi/otomatis'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      });

      request.fields['tipe_absen'] = tipe;
      request.fields['latitude'] = lat; // ← FIX
      request.fields['longitude'] = lng; // ← FIX
      if (catatan != null && catatan.isNotEmpty) {
        request.fields['catatan'] = catatan;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_wajah',
          foto.path,
          filename: '${tipe}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await cekStatusHariIni();
        return true;
      } else {
        try {
          final err = jsonDecode(response.body);
          Get.snackbar(
            'Gagal',
            err['message'] ?? 'Gagal menyimpan absensi',
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

  // ===========================================================================
  // FACE RECOGNITION — cek saja
  // POST /user/wajah/verifikasi
  // ===========================================================================

  Future<Map<String, dynamic>> _cekFaceRecognitionSaja(File foto) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/wajah/verifikasi'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token', // ← FIX
      });
      request.files.add(
        await http.MultipartFile.fromPath('foto_wajah', foto.path),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'verified': data['verified'] ?? false,
          'confidence': (data['confidence'] as num?)?.toDouble() ?? 0.0,
        };
      }
      return {'verified': false, 'confidence': 0.0};
    } catch (e) {
      debugPrint('Error cek face: $e');
      return {'verified': false, 'confidence': 0.0};
    }
  }

  // ===========================================================================
  // FOTO REFERENSI
  // ===========================================================================

  Future<void> _loadFotoReferensi() async {
    try {
      if (_token.isEmpty) return; // ← FIX

      if (auth.fotoWajahUrl.isNotEmpty) {
        fotoReferensiUrl.value = auth.fotoWajahUrl;
        wajahTerdaftar.value = auth.wajahTerdaftar;
        return;
      }

      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/profil'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $_token', // ← FIX
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final fotoUrl =
            data['foto_wajah_url']?.toString() ??
            data['employee']?['foto_wajah_url']?.toString() ??
            '';

        final terdaftar =
            data['employee']?['wajah_terdaftar'] == true ||
            data['employee']?['wajah_terdaftar'] == 1;

        fotoReferensiUrl.value = fotoUrl;
        wajahTerdaftar.value = terdaftar;

        if (auth.employee.value != null) {
          final empUpdated = Map<String, dynamic>.from(auth.employee.value!);
          empUpdated['foto_wajah_url'] = fotoUrl;
          empUpdated['wajah_terdaftar'] = terdaftar;
          auth.employee.value = empUpdated;
        }
      }
    } catch (e) {
      debugPrint('Error _loadFotoReferensi: $e');
    }
  }

  Future<String> _getFotoReferensiUrl() async {
    if (fotoReferensiUrl.value.isNotEmpty) return fotoReferensiUrl.value;
    await _loadFotoReferensi();
    return fotoReferensiUrl.value;
  }

  Future<void> cekStatusWajah() async => _loadFotoReferensi();

  // ===========================================================================
  // DAFTARKAN WAJAH
  // POST /user/wajah/daftarkan
  // ===========================================================================

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
        'Authorization': 'Bearer $_token', // ← FIX
      });
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_wajah',
          foto.path,
          filename:
              'wajah_${auth.employeeCode.isNotEmpty ? auth.employeeCode : auth.employeeId ?? 'emp'}.jpg',
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        wajahTerdaftar.value = true;
        fotoReferensiUrl.value = data['foto_wajah_url']?.toString() ?? '';
        fotoWajah.value = null;

        if (auth.employee.value != null) {
          final empUpdated = Map<String, dynamic>.from(auth.employee.value!);
          empUpdated['wajah_terdaftar'] = true;
          empUpdated['foto_wajah_url'] = fotoReferensiUrl.value;
          auth.employee.value = empUpdated;
        }

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

  // ===========================================================================
  // RIWAYAT ABSENSI
  // GET /user/absensi/riwayat
  // ===========================================================================

  Future<void> fetchRiwayatAbsensi() async {
    if (_token.isEmpty) return; // ← FIX

    isLoadingRiwayat.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/absensi/riwayat'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $_token', // ← FIX
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] is List) {
          riwayatAbsensi.value = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          riwayatAbsensi.value = List<Map<String, dynamic>>.from(data);
        } else {
          riwayatAbsensi.value = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetchRiwayat: $e');
    } finally {
      isLoadingRiwayat.value = false;
    }
  }

  String getNamaLokasiDariRiwayat(Map<String, dynamic> absensi) {
    try {
      return absensi['pusat_lokasi']?['nama_lokasi']?.toString() ?? '-';
    } catch (_) {
      return '-';
    }
  }

  String getNamaShiftDariRiwayat(Map<String, dynamic> absensi) {
    try {
      return absensi['shift']?['nama']?.toString() ?? '-';
    } catch (_) {
      return '-';
    }
  }

  // ===========================================================================
  // DIALOGS
  // ===========================================================================

  void _showWebNotSupportedDialog() {
    Get.dialog(
      AlertDialog(
        title: const Icon(Icons.info_outline, color: Colors.orange, size: 48),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Akses Kamera Tidak Tersedia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Fitur kamera hanya tersedia di aplikasi mobile.',
              textAlign: TextAlign.center,
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
      AlertDialog(
        title: Icon(Icons.camera_alt, color: Colors.orange[700], size: 48),
        content: const Text(
          'Wajah tidak terdeteksi.\nPastikan pencahayaan cukup dan hadap kamera langsung.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Foto Ulang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
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
              Icon(
                Icons.face_retouching_natural,
                color: Colors.orange[700],
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Wajah Belum Terdaftar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda perlu mendaftarkan wajah terlebih dahulu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
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
                  label: const Text('Daftarkan Wajah Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
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

  Future<bool> kirimAbsensiOffline({
    required String tipe,
    required File foto,
    required double latitude,
    required double longitude,
    required DateTime waktuAbsen,
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
        'Authorization': 'Bearer $_token',
      });

      request.fields['tipe_absen'] = tipe;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['waktu_absen'] = waktuAbsen
          .toIso8601String(); // ← tambah ini
      request.fields['is_offline'] = 'true'; // ← flag untuk backend

      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_wajah',
          foto.path,
          filename: '${tipe}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await cekStatusHariIni();
        return true;
      } else {
        try {
          final err = jsonDecode(response.body);
          Get.snackbar(
            'Gagal',
            err['message'] ?? 'Gagal menyimpan absensi',
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

  // ===========================================================================
  // RESET
  // ===========================================================================

  void reset() {
    userLokasis.clear();
    riwayatAbsensi.clear();
    errorMessage.value = '';
    isLoading.value = false;
    isLoadingRiwayat.value = false;
    latitudeSekarang.value = 0.0;
    longitudeSekarang.value = 0.0;
    akurasiLokasi.value = 0.0;
    fotoWajah.value = null;
    sudahMasuk.value = false;
    sudahPulang.value = false;
    dataMasuk.value = null;
    dataPulang.value = null;
    lokasiTerpilih.value = null;
    jarakTerdekat.value = 0.0;
    isInRange.value = false;
    wajahTerdaftar.value = false;
    fotoReferensiUrl.value = '';
  }

  void printDebugInfo() {
    debugPrint('=' * 50);
    debugPrint('USER LOKASI CONTROLLER');
    debugPrint('Token: ${_token.isNotEmpty ? "Ada" : "Kosong"}');
    debugPrint('Employee ID: ${auth.employeeId}');
    debugPrint('Lokasi: ${userLokasis.length}');
    debugPrint('Status Masuk: ${sudahMasuk.value}');
    debugPrint('Status Pulang: ${sudahPulang.value}');
    debugPrint(
      'Lat/Lng: ${latitudeSekarang.value}, ${longitudeSekarang.value}',
    );
    debugPrint('Jarak Terdekat: ${jarakTerdekat.value.toStringAsFixed(2)} m');
    debugPrint('Wajah Terdaftar: ${wajahTerdaftar.value}');
    debugPrint('=' * 50);
  }
}
