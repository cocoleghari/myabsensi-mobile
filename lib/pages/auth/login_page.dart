import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final obscurePassword = true.obs;
    final emailError = ''.obs;
    final passwordError = ''.obs;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Obx(
          () => controller.isLoading.value
              ? _buildLoadingScreen()
              : _buildLoginScreen(
                  context,
                  emailController,
                  passwordController,
                  obscurePassword,
                  emailError,
                  passwordError,
                ),
        ),
      ),
    );
  }

  // ── LOADING ──────────────────────────────────────────────────────────────

  Widget _buildLoadingScreen() {
    return Container(
      color: const Color(0xFF1565C0),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text(
              'Memproses login...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MAIN SCREEN ──────────────────────────────────────────────────────────

  Widget _buildLoginScreen(
    BuildContext context,
    TextEditingController emailController,
    TextEditingController passwordController,
    RxBool obscurePassword,
    RxString emailError,
    RxString passwordError,
  ) {
    return Container(
      color: const Color(0xFF1565C0),
      child: SafeArea(
        child: Column(
          children: [
            // ── TOP: Logo area dengan blob ──
            Expanded(flex: 5, child: _buildBlobHeader()),

            // ── BOTTOM: Form sheet ──
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Masuk ke Akun',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F36),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Silahkan masuk untuk melanjutkan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildLabel('Email'),
                      const SizedBox(height: 8),
                      _buildEmailField(emailController, emailError),
                      const SizedBox(height: 16),
                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        passwordController,
                        obscurePassword,
                        passwordError,
                      ),
                      const SizedBox(height: 24),
                      _buildLoginButton(
                        emailController,
                        passwordController,
                        emailError,
                        passwordError,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BLOB HEADER ──────────────────────────────────────────────────────────

  Widget _buildBlobHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Blob 1 — kanan atas, besar
        Positioned(
          top: -50,
          right: -50,
          child: _Blob(
            width: 200,
            height: 200,
            color: Colors.white.withOpacity(0.08),
            borderRadiusCSS: '60% 40% 70% 30% / 50% 60% 40% 50%',
          ),
        ),
        // Blob 2 — kiri bawah
        Positioned(
          bottom: 20,
          left: -30,
          child: _Blob(
            width: 150,
            height: 150,
            color: Colors.white.withOpacity(0.06),
            borderRadiusCSS: '30% 70% 50% 50% / 60% 40% 60% 40%',
          ),
        ),
        // Blob 3 — tengah kiri, kecil aksen
        Positioned(
          top: 40,
          left: 60,
          child: _Blob(
            width: 80,
            height: 80,
            color: Colors.white.withOpacity(0.05),
            borderRadiusCSS: '50% 50% 30% 70% / 40% 60% 40% 60%',
          ),
        ),
        // Blob 4 — kanan tengah, medium
        Positioned(
          bottom: 50,
          right: 30,
          child: _Blob(
            width: 110,
            height: 100,
            color: Colors.white.withOpacity(0.06),
            borderRadiusCSS: '40% 60% 60% 40% / 50% 40% 60% 50%',
          ),
        ),

        // Konten (logo + teks)
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon box
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.28),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Absensi App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Absensi berbasis lokasi & wajah',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── LABEL ─────────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1F36),
      ),
    );
  }

  // ── EMAIL FIELD ───────────────────────────────────────────────────────────

  Widget _buildEmailField(
    TextEditingController emailController,
    RxString emailError,
  ) {
    return Obx(
      () => TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1F36)),
        decoration: InputDecoration(
          hintText: 'contoh@email.com',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          errorText: emailError.value.isEmpty ? null : emailError.value,
          prefixIcon: Icon(
            Icons.email_outlined,
            size: 18,
            color: emailError.value.isEmpty
                ? const Color(0xFF8A94A6)
                : Colors.red.shade400,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
        onChanged: (_) => emailError.value = '',
      ),
    );
  }

  // ── PASSWORD FIELD ────────────────────────────────────────────────────────

  Widget _buildPasswordField(
    TextEditingController passwordController,
    RxBool obscurePassword,
    RxString passwordError,
  ) {
    return Obx(
      () => TextField(
        controller: passwordController,
        obscureText: obscurePassword.value,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1F36)),
        decoration: InputDecoration(
          hintText: 'Minimal 6 karakter',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          errorText: passwordError.value.isEmpty ? null : passwordError.value,
          prefixIcon: Icon(
            Icons.lock_outline,
            size: 18,
            color: passwordError.value.isEmpty
                ? const Color(0xFF8A94A6)
                : Colors.red.shade400,
          ),
          suffixIcon: GestureDetector(
            onTap: () => obscurePassword.toggle(),
            child: Icon(
              obscurePassword.value
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF8A94A6),
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
        onChanged: (_) => passwordError.value = '',
      ),
    );
  }

  // ── LOGIN BUTTON ──────────────────────────────────────────────────────────

  Widget _buildLoginButton(
    TextEditingController emailController,
    TextEditingController passwordController,
    RxString emailError,
    RxString passwordError,
  ) {
    return GestureDetector(
      onTap: () => _login(
        emailController,
        passwordController,
        emailError,
        passwordError,
      ),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Masuk',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ── INFO ROW ──────────────────────────────────────────────────────────────

  Widget _buildInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(
          'Hubungi admin jika ada kendala login',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // ── VALIDATION ────────────────────────────────────────────────────────────

  void _login(
    TextEditingController emailController,
    TextEditingController passwordController,
    RxString emailError,
    RxString passwordError,
  ) {
    emailError.value = '';
    passwordError.value = '';

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    bool isValid = true;

    if (email.isEmpty) {
      emailError.value = 'Email wajib diisi';
      isValid = false;
    } else if (!GetUtils.isEmail(email)) {
      emailError.value = 'Format email tidak valid';
      isValid = false;
    }

    if (password.isEmpty) {
      passwordError.value = 'Password wajib diisi';
      isValid = false;
    } else if (password.length < 6) {
      passwordError.value = 'Password minimal 6 karakter';
      isValid = false;
    }

    if (!isValid) return;
    Get.find<AuthController>().login(email, password);
  }
}

// ── BLOB WIDGET ───────────────────────────────────────────────────────────────
// Flutter tidak support CSS border-radius 8-value,
// jadi kita pakai CustomPainter dengan cubic bezier untuk bentuk organik

class _Blob extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  // parameter ini tidak dipakai di Flutter, hanya untuk dokumentasi
  final String borderRadiusCSS;

  const _Blob({
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadiusCSS,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BlobPainter(color: color, seed: borderRadiusCSS.hashCode),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;
  final int seed;

  const _BlobPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = _generateBlobPath(size, seed);
    canvas.drawPath(path, paint);
  }

  Path _generateBlobPath(Size size, int seed) {
    final rng = math.Random(seed);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width / 2;
    final ry = size.height / 2;

    // 8 titik dengan variasi organik
    const points = 8;
    final angleStep = (math.pi * 2) / points;
    final anchors = <Offset>[];

    for (int i = 0; i < points; i++) {
      final angle = i * angleStep - math.pi / 2;
      // variasi radius 70%–100%
      final rVariation = 0.7 + rng.nextDouble() * 0.3;
      final x = cx + math.cos(angle) * rx * rVariation;
      final y = cy + math.sin(angle) * ry * rVariation;
      anchors.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(
      (anchors.last.dx + anchors.first.dx) / 2,
      (anchors.last.dy + anchors.first.dy) / 2,
    );

    for (int i = 0; i < points; i++) {
      final curr = anchors[i];
      final next = anchors[(i + 1) % points];
      final midX = (curr.dx + next.dx) / 2;
      final midY = (curr.dy + next.dy) / 2;
      path.quadraticBezierTo(curr.dx, curr.dy, midX, midY);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => old.seed != seed;
}
