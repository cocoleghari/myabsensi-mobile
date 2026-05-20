import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/app_config.dart';
import 'package:http/http.dart' as http;

class NotificationController extends GetxController {
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final token = Get.find<AuthController>().token.value;
      if (token.isEmpty) return;

      final baseUrl = await AppConfig.getBaseUrl();

      // ← TAMBAH INI untuk debug
      debugPrint('=== FETCH NOTIF ===');
      debugPrint('Token: ${token.substring(0, 20)}...');
      debugPrint('URL: $baseUrl/user/notifications');

      final response = await http
          .get(
            Uri.parse('$baseUrl/user/notifications'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      // ← TAMBAH INI
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? [];
        notifications.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        unreadCount.value = notifications
            .where((n) => n['is_read'] == false)
            .length;
      }
    } catch (e) {
      debugPrint('fetchNotifications error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> getByCategory(String category) {
    if (category == 'all') return notifications;
    return notifications.where((n) => n['category'] == category).toList();
  }

  int unreadByCategory(String category) {
    return getByCategory(category).where((n) => n['is_read'] == false).length;
  }

  Future<void> markAsRead(int id) async {
    final idx = notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      notifications[idx] = {...notifications[idx], 'is_read': true};
      notifications.refresh();
      unreadCount.value = notifications
          .where((n) => n['is_read'] == false)
          .length;
      // TODO: PATCH /api/notifications/{id}/read
    }
  }

  Future<void> markAllAsRead() async {
    for (var i = 0; i < notifications.length; i++) {
      notifications[i] = {...notifications[i], 'is_read': true};
    }
    notifications.refresh();
    unreadCount.value = 0;
    // TODO: POST /api/notifications/read-all
  }
}
