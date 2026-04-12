import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/app_config.dart';

// ══════════════════════════════════════════════════════
//  Controller untuk RekamAktivitasPage (list & kalender)
// ══════════════════════════════════════════════════════
class RekamAktivitasController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var currentMonth = DateTime.now().obs;
  var isGridView = true.obs;
  var activities = <Map<String, dynamic>>[].obs;
  var isLoadingAktivitas = false.obs;
  var baseUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initBaseUrl();
  }

  Future<void> _initBaseUrl() async {
    final url = await AppConfig.getBaseUrl();
    baseUrl.value = url.replaceAll('/api', '');
    fetchAktivitas();
  }

  // ✅ Helper build foto URL
  String getFotoUrl(String fotoPath) {
    if (fotoPath.isEmpty) return '';
    if (fotoPath.startsWith('http')) return fotoPath;
    return '${baseUrl.value}/storage/$fotoPath';
  }

  Future<void> fetchAktivitas() async {
    isLoadingAktivitas.value = true;
    try {
      final authController = Get.find<AuthController>();
      final baseUrl = await AppConfig.getBaseUrl();
      final token = authController.token.value;
      final localDate = selectedDate.value.toLocal();
      final tanggal = DateFormat('yyyy-MM-dd').format(localDate);

      final response = await http
          .get(
            Uri.parse('$baseUrl/user/aktivitas?tanggal=$tanggal'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        activities.value = List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      debugPrint('fetchAktivitas error: $e');
    } finally {
      isLoadingAktivitas.value = false;
    }
  }

  List<DateTime> getWeekDays() => _getWeekDaysFrom(currentMonth.value);

  List<DateTime> _getWeekDaysFrom(DateTime ref) {
    final startOfWeek = ref.subtract(Duration(days: ref.weekday % 7));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  void previousWeek() {
    currentMonth.value = currentMonth.value.subtract(const Duration(days: 7));
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 7));
    fetchAktivitas();
  }

  void nextWeek() {
    currentMonth.value = currentMonth.value.add(const Duration(days: 7));
    selectedDate.value = selectedDate.value.add(const Duration(days: 7));
    fetchAktivitas();
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    fetchAktivitas();
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isSelected(DateTime date) => isSameDay(date, selectedDate.value);

  bool isSunday(DateTime date) => date.weekday == DateTime.sunday;
}

// ══════════════════════════════════════════════════════
//  Controller untuk RekamAktivitasFormPage
// ══════════════════════════════════════════════════════
class RekamAktivitasFormController extends GetxController {
  var photos = <File>[].obs;
  var isLoadingLocation = true.obs;
  var isLoading = false.obs;
  var isLoadingTipe = false.obs;
  var currentPosition = const LatLng(-7.4, 109.23).obs;
  var accuracyMeters = 0.0.obs;
  var startTime = DateTime.now().obs;
  var endTime = DateTime.now().obs;
  var tipeAktivitasList = <Map<String, dynamic>>[].obs;
  var selectedTipeAktivitas = Rxn<Map<String, dynamic>>();

  final tugasController = TextEditingController();
  final tujuanController = TextEditingController();
  final kendaraanNopolController = TextEditingController();
  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
    fetchTipeAktivitas();
  }

  @override
  void onClose() {
    tugasController.dispose();
    tujuanController.dispose();
    kendaraanNopolController.dispose();
    mapController?.dispose();
    super.onClose();
  }

  // ── FETCH TIPE AKTIVITAS ─────────────────────────────────────────────
  Future<void> fetchTipeAktivitas() async {
    isLoadingTipe.value = true;
    try {
      final authController = Get.find<AuthController>();
      final baseUrl = await AppConfig.getBaseUrl();
      final token = authController.token.value;

      final response = await http
          .get(
            Uri.parse('$baseUrl/user/tipe-aktivitas'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      debugPrint('fetchTipeAktivitas status: ${response.statusCode}');
      debugPrint('fetchTipeAktivitas body: ${response.body}');

      if (response.statusCode == 200) {
        tipeAktivitasList.value = List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      debugPrint('fetchTipeAktivitas error: $e');
    } finally {
      isLoadingTipe.value = false;
    }
  }

  // ── HELPER FLAGS ─────────────────────────────────────────────────────
  bool get needsTujuan => selectedTipeAktivitas.value?['has_tujuan'] == true;

  bool get needsTujuanDanKendaraan =>
      selectedTipeAktivitas.value?['has_tujuan'] == true &&
      selectedTipeAktivitas.value?['has_kendaraan'] == true;

  // ── LOCATION ─────────────────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    isLoadingLocation.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isLoadingLocation.value = false;
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        isLoadingLocation.value = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition.value = LatLng(position.latitude, position.longitude);
      accuracyMeters.value = position.accuracy;

      mapController?.animateCamera(
        CameraUpdate.newLatLng(currentPosition.value),
      );
    } catch (e) {
      debugPrint('Error get location: $e');
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void refreshLocation() => _getCurrentLocation();

  // ── PHOTO ─────────────────────────────────────────────────────────────
  void addPhoto(File photo) {
    if (photos.length < 5) photos.add(photo);
  }

  void removePhoto(int index) => photos.removeAt(index);

  // ── TIME ─────────────────────────────────────────────────────────────
  void setStartTime(DateTime dt) => startTime.value = dt;
  void setEndTime(DateTime dt) => endTime.value = dt;

  // ── VALIDATE ─────────────────────────────────────────────────────────
  bool validate() {
    if (tugasController.text.trim().isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Tugas tidak boleh kosong',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
    if (selectedTipeAktivitas.value == null) {
      Get.snackbar(
        'Peringatan',
        'Pilih tipe aktivitas terlebih dahulu',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
    if (needsTujuan && tujuanController.text.trim().isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Tujuan tidak boleh kosong',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
    if (needsTujuanDanKendaraan &&
        kendaraanNopolController.text.trim().isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Kendaraan & Nopol tidak boleh kosong',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
    // ✅ Validasi foto wajib
    if (photos.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Foto wajib diisi minimal 1',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
    return true;
  }

  // ── SIMPAN ────────────────────────────────────────────────────────────
  Future<void> simpan() async {
    if (!validate()) return;

    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final baseUrl = await AppConfig.getBaseUrl();
      final token = authController.token.value;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/aktivitas'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['tugas'] = tugasController.text.trim();
      request.fields['mulai'] = startTime.value.toIso8601String();
      request.fields['berakhir'] = endTime.value.toIso8601String();
      request.fields['tipe_aktivitas_id'] =
          selectedTipeAktivitas.value?['id']?.toString() ?? '';
      request.fields['tujuan'] = tujuanController.text.trim();
      request.fields['kendaraan_nopol'] = kendaraanNopolController.text.trim();
      request.fields['latitude'] = currentPosition.value.latitude.toString();
      request.fields['longitude'] = currentPosition.value.longitude.toString();
      request.fields['akurasi_meter'] = accuracyMeters.value.toString();

      for (int i = 0; i < photos.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'fotos[]',
            photos[i].path,
            filename: 'foto_aktivitas_$i.jpg',
          ),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      debugPrint('=== SIMPAN AKTIVITAS ===');
      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RESPONSE BODY: ${response.body}');

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (jsonError) {
        debugPrint('JSON PARSE ERROR: $jsonError');
        Get.snackbar(
          'Error',
          'Response tidak valid dari server',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (Get.isRegistered<RekamAktivitasController>()) {
          await Get.find<RekamAktivitasController>().fetchAktivitas();
        }

        Get.back();

        await Future.delayed(const Duration(milliseconds: 300));

        Get.snackbar(
          'Berhasil',
          data['message'] ?? 'Aktivitas berhasil disimpan',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        String errorMessage = data['message'] ?? 'Gagal menyimpan aktivitas';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first;
          }
        }
        Get.snackbar(
          'Gagal',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
