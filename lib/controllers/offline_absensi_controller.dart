import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/offline_absensi_model.dart';
import 'auth_controller.dart';
import 'user_lokasi_controller.dart';

class OfflineAbsensiController extends GetxController {
  static OfflineAbsensiController get to => Get.find();

  final _box = GetStorage();
  String get _storageKey {
    final auth = Get.find<AuthController>();
    final userId = auth.user['id']?.toString() ?? 'guest';
    return 'offline_absensi_queue_$userId';
  }

  var queue = <OfflineAbsensiModel>[].obs;
  var isSyncing = false.obs;
  var isOnline = true.obs;

  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void onInit() {
    super.onInit();
    _loadQueue();
    _initConnectivity();
  }

  // ── Connectivity ────────────────────────────────────────────────────────────

  Future<void> _initConnectivity() async {
    _connectivity = Connectivity();

    // Cek status awal
    final result = await _connectivity.checkConnectivity();
    _updateOnlineStatus(result);

    // Listen perubahan
    _connectivity.onConnectivityChanged.listen((results) {
      _updateOnlineStatus(results);
    });
  }

  void reloadQueue() {
    queue.clear();
    _loadQueue();
  }

  void clearMemory() {
    queue.clear();
    // Tidak hapus dari storage — data offline tetap tersimpan untuk user ini
  }

  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final wasOffline = !isOnline.value;
    isOnline.value = results.any((r) => r != ConnectivityResult.none);

    // Baru saja online kembali & ada queue → auto sync
    if (wasOffline && isOnline.value && pendingQueue.isNotEmpty) {
      _showBackOnlineSnackbar();
      syncQueue();
    }
  }

  void _showBackOnlineSnackbar() {
    Get.snackbar(
      'Kembali Online 🌐',
      '${pendingQueue.length} absensi offline akan disinkronkan...',
      backgroundColor: const Color(0xFF1E88E5),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
    );
  }

  // ── Queue Management ────────────────────────────────────────────────────────

  void _loadQueue() {
    final raw = _box.read<List>(_storageKey);
    if (raw != null) {
      queue.value = raw
          .map(
            (e) => OfflineAbsensiModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
  }

  Future<void> _saveQueue() async {
    await _box.write(_storageKey, queue.map((e) => e.toJson()).toList());
  }

  Future<void> addToQueue({
    required String tipe,
    required File foto,
    required double latitude,
    required double longitude,
  }) async {
    final item = OfflineAbsensiModel(
      id: const Uuid().v4(),
      tipe: tipe,
      fotoPath: foto.path,
      latitude: latitude,
      longitude: longitude,
      waktuAbsen: DateTime.now(),
    );

    queue.add(item);
    await _saveQueue();
  }

  Future<void> removeFromQueue(String id) async {
    queue.removeWhere((e) => e.id == id);
    await _saveQueue();
  }

  Future<void> _updateStatus(String id, String status, {String? error}) async {
    final idx = queue.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    queue[idx] = queue[idx].copyWith(status: status, errorMessage: error);
    queue.refresh();
    await _saveQueue();
  }

  List<OfflineAbsensiModel> get pendingQueue => queue
      .where((e) => e.status == 'pending' || e.status == 'failed')
      .toList();

  int get pendingCount => pendingQueue.length;

  // ── Sync ────────────────────────────────────────────────────────────────────

  Future<void> syncQueue() async {
    if (isSyncing.value || pendingQueue.isEmpty) return;
    if (!isOnline.value) {
      Get.snackbar(
        'Tidak Ada Koneksi',
        'Pastikan internet aktif untuk sinkronisasi',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
      return;
    }

    isSyncing.value = true;

    int berhasil = 0;
    int gagal = 0;

    final toSync = List<OfflineAbsensiModel>.from(pendingQueue);

    for (final item in toSync) {
      await _updateStatus(item.id, 'syncing');

      try {
        final foto = File(item.fotoPath);
        if (!foto.existsSync()) {
          await _updateStatus(
            item.id,
            'failed',
            error: 'File foto tidak ditemukan',
          );
          gagal++;
          continue;
        }

        final lokasi = Get.find<UserLokasiController>();

        final success = await lokasi.kirimAbsensiOffline(
          tipe: item.tipe,
          foto: foto,
          latitude: item.latitude,
          longitude: item.longitude,
          waktuAbsen: item.waktuAbsen, // ← waktu asli offline
        );

        if (success) {
          await removeFromQueue(item.id);
          berhasil++;
        } else {
          await _updateStatus(item.id, 'failed', error: 'Ditolak server');
          gagal++;
        }
      } catch (e) {
        await _updateStatus(item.id, 'failed', error: e.toString());
        gagal++;
      }
    }

    isSyncing.value = false;
    _showSyncResultSnackbar(berhasil, gagal);
  }

  void _showSyncResultSnackbar(int berhasil, int gagal) {
    if (berhasil > 0 && gagal == 0) {
      Get.snackbar(
        'Sinkronisasi Berhasil ✅',
        '$berhasil absensi offline berhasil dikirim',
        backgroundColor: const Color(0xFF22C55E),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    } else if (berhasil > 0 && gagal > 0) {
      Get.snackbar(
        'Sinkronisasi Sebagian ⚠️',
        '$berhasil berhasil, $gagal gagal',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    } else if (gagal > 0) {
      Get.snackbar(
        'Sinkronisasi Gagal ❌',
        '$gagal absensi gagal dikirim. Cek detail di antrian.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
