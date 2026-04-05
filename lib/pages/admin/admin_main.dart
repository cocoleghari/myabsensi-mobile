import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/user_controller.dart';
import 'package:myabsensi_mobile/pages/admin/listAkun/list_akun.dart';
import 'package:get/get.dart';

void main() {
  Get.put(AuthController());
  Get.put(UserController());

  runApp(const AdminMainApp());
}

class AdminMainApp extends StatelessWidget {
  const AdminMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ListAkunPage(),
    );
  }
}
