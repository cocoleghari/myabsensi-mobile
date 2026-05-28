import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final auth = Get.find<AuthController>();

    debugPrint('=== SPLASH DEBUG ===');
    debugPrint('token: "${auth.token.value}"');
    debugPrint('role: "${auth.userRole}"');
    debugPrint('isLoggedIn: ${auth.isLoggedIn}');
    debugPrint('isAdmin: ${auth.isAdmin}');
    debugPrint('isSuperAdmin: ${auth.isSuperAdmin}');
    debugPrint('isHrd: ${auth.isHrd}');
    debugPrint('isEmployee: ${auth.isEmployee}');

    if (auth.isLoggedIn && auth.token.isNotEmpty) {
      if (auth.isAdmin || auth.isSuperAdmin || auth.isHrd) {
        debugPrint('>>> REDIRECT KE /admin');
        Get.offAllNamed('/admin');
      } else {
        debugPrint('>>> REDIRECT KE /user');
        Get.offAllNamed('/user');
      }
    } else {
      debugPrint('>>> REDIRECT KE /login');
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(
          child: Image.asset(
            'assets/images/splash_screen.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
