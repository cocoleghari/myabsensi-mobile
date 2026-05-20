import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

// Asset: assets/images/login_bg.png

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  final _obscurePassword = true.obs;
  final _emailError = ''.obs;
  final _passwordError = ''.obs;
  final _rememberMe = true.obs;

  AuthController get _auth => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Obx(
          () => _auth.isLoading.value ? _buildLoading() : _buildBody(context),
        ),
      ),
    );
  }

  // ── LOADING ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: Color(0xFF1B4FD8),
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Memproses login...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── BODY ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.52;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // Gambar atas
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Form sheet overlap ke gambar
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: _buildFormContent(),
            ),
          ),
        ],
      ),
    );
  }

  // ── FORM CONTENT ──────────────────────────────────────────────────────────

  Widget _buildFormContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Judul — 2 baris, font ketat & bold
          const Text(
            'Selamat Datang!',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: 0.40,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masuk ke akunmu untuk melanjutkan',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFADB5C7),
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 28),

          // Email — flat underline style
          _buildFlatLabel('Username / Email'),
          const SizedBox(height: 8),
          _buildEmailField(),

          const SizedBox(height: 20),

          // Password — flat underline style
          _buildFlatLabel('Password'),
          const SizedBox(height: 8),
          _buildPasswordField(),

          const SizedBox(height: 16),

          // Ingat saya + Lupa password
          _buildRememberForgotRow(),

          const SizedBox(height: 32),

          // Tombol masuk — full gradient modern
          _buildLoginButton(),

          const SizedBox(height: 20),

          // Info
          _buildInfoRow(),
        ],
      ),
    );
  }

  // ── FLAT LABEL ────────────────────────────────────────────────────────────

  Widget _buildFlatLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.0,
      ),
    );
  }

  // ── EMAIL FIELD — flat underline ──────────────────────────────────────────

  Widget _buildEmailField() {
    return Obx(
      () => TextField(
        controller: _emailController,
        keyboardType: TextInputType.text,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'contoh@email.com atau username',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w400,
          ),
          errorText: _emailError.value.isEmpty ? null : _emailError.value,
          prefixIcon: Icon(
            Icons.alternate_email_rounded,
            size: 18,
            color: _emailError.value.isEmpty
                ? const Color(0xFF1B4FD8)
                : Colors.red.shade400,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          isDense: true,
          filled: false,
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1B4FD8), width: 2),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (_) => _emailError.value = '',
      ),
    );
  }

  // ── PASSWORD FIELD — flat underline ───────────────────────────────────────

  Widget _buildPasswordField() {
    return Obx(
      () => TextField(
        controller: _passwordController,
        obscureText: _obscurePassword.value,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Minimal 6 karakter',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w400,
          ),
          errorText: _passwordError.value.isEmpty ? null : _passwordError.value,
          // prefix & suffix pakai icon biasa — Flutter handle alignment otomatis
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: _passwordError.value.isEmpty
                ? const Color(0xFF1B4FD8)
                : Colors.red.shade400,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: GestureDetector(
            onTap: () => _obscurePassword.toggle(),
            child: Icon(
              _obscurePassword.value
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFFCBD5E1),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          isDense: true,
          filled: false,
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1B4FD8), width: 2),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (_) => _passwordError.value = '',
      ),
    );
  }

  // ── REMEMBER + LUPA PASSWORD ──────────────────────────────────────────────

  Widget _buildRememberForgotRow() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _rememberMe.toggle(),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _rememberMe.value
                        ? const Color(0xFF1B4FD8)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _rememberMe.value
                          ? const Color(0xFF1B4FD8)
                          : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: _rememberMe.value
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ingat saya',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: lupa password
            },
            child: const Text(
              'Lupa password?',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1B4FD8),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOGIN BUTTON — gradient modern ────────────────────────────────────────

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _login,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B4FD8), Color(0xFF3B6FF0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4FD8).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Teks tombol
            const Text(
              'MASUK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
            // Arrow di kanan
            Positioned(
              right: 20,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── INFO ROW ──────────────────────────────────────────────────────────────

  Widget _buildInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFFCBD5E1)),
        SizedBox(width: 5),
        Text(
          'Hubungi admin jika ada kendala login',
          style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
        ),
      ],
    );
  }

  // ── VALIDATION ────────────────────────────────────────────────────────────

  void _login() {
    _emailError.value = '';
    _passwordError.value = '';

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    bool isValid = true;

    if (email.isEmpty) {
      _emailError.value = 'Email atau username wajib diisi';
      isValid = false;
    } else if (email.contains('@') && !GetUtils.isEmail(email)) {
      _emailError.value = 'Format email tidak valid';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError.value = 'Password wajib diisi';
      isValid = false;
    } else if (password.length < 6) {
      _passwordError.value = 'Password minimal 6 karakter';
      isValid = false;
    }

    if (!isValid) return;
    _auth.login(email, password);
  }
}
