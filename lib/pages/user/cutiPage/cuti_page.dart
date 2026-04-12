import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class CutiPage extends StatefulWidget {
  const CutiPage({super.key});

  @override
  State<CutiPage> createState() => _CutiPageState();
}

class _CutiPageState extends State<CutiPage> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _floatController;
  late AnimationController _entryController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    _entryController.dispose();
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated Gradient Background ──
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.cos(_bgController.value * 2 * math.pi) * 0.5,
                      math.sin(_bgController.value * 2 * math.pi) * 0.5,
                    ),
                    end: Alignment(
                      math.cos(_bgController.value * 2 * math.pi + math.pi) *
                          0.5,
                      math.sin(_bgController.value * 2 * math.pi + math.pi) *
                          0.5,
                    ),
                    colors: const [
                      Color(0xFF0A1628),
                      Color(0xFF0D2137),
                      Color(0xFF112D4E),
                      Color(0xFF0A1628),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Mesh orbs ──
          _buildOrb(
            controller: _bgController,
            size: size.width * 0.9,
            color: const Color(0xFF1565C0).withOpacity(0.25),
            xFn: (t) => size.width * (0.7 + 0.2 * math.cos(t * 2 * math.pi)),
            yFn: (t) => size.height * (0.15 + 0.1 * math.sin(t * 2 * math.pi)),
          ),
          _buildOrb(
            controller: _bgController,
            size: size.width * 0.7,
            color: const Color(0xFF0288D1).withOpacity(0.2),
            xFn: (t) =>
                size.width * (0.1 + 0.15 * math.sin(t * 2 * math.pi + 1.5)),
            yFn: (t) =>
                size.height * (0.55 + 0.1 * math.cos(t * 2 * math.pi + 1)),
          ),
          _buildOrb(
            controller: _bgController,
            size: size.width * 0.5,
            color: const Color(0xFFFF7A30).withOpacity(0.12),
            xFn: (t) =>
                size.width * (0.5 + 0.25 * math.cos(t * 2 * math.pi + 3)),
            yFn: (t) =>
                size.height * (0.8 + 0.08 * math.sin(t * 2 * math.pi + 2)),
          ),

          // ── Grid lines overlay ──
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _GridPainter(),
          ),

          // ── Floating particles ──
          ...List.generate(6, (i) => _buildParticle(i, size)),

          // ── Main Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(flex: 2),

                      // ── Hero Illustration ──
                      Center(
                        child: ScaleTransition(
                          scale: _scaleAnim,
                          child: AnimatedBuilder(
                            animation: _floatController,
                            builder: (_, __) {
                              final float = _floatController.value;
                              return Transform.translate(
                                offset: Offset(
                                  0,
                                  -10 * math.sin(float * math.pi),
                                ),
                                child: _buildHeroIllustration(size),
                              );
                            },
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),

                      // ── Tag chip ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A30).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFFF7A30).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF7A30),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Dalam Pengembangan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF7A30),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Headline ──
                      const Text(
                        'Fitur Cuti\nSegera Hadir',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Subtext ──
                      Text(
                        'Kami sedang membangun sistem pengajuan cuti yang lebih cerdas, mudah, dan efisien untuk mendukung produktivitas Anda.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.55),
                          height: 1.7,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Feature pills row ──
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _FeaturePill(
                            icon: Icons.send_rounded,
                            label: 'Pengajuan Online',
                          ),
                          _FeaturePill(
                            icon: Icons.notifications_rounded,
                            label: 'Notifikasi Instan',
                          ),
                          _FeaturePill(
                            icon: Icons.history_rounded,
                            label: 'Riwayat Lengkap',
                          ),
                          _FeaturePill(
                            icon: Icons.approval_rounded,
                            label: 'Approval Digital',
                          ),
                        ],
                      ),

                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb({
    required AnimationController controller,
    required double size,
    required Color color,
    required double Function(double) xFn,
    required double Function(double) yFn,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Positioned(
          left: xFn(t) - size / 2,
          top: yFn(t) - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, Colors.transparent],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticle(int index, Size size) {
    final positions = [
      Offset(0.15, 0.2),
      Offset(0.82, 0.15),
      Offset(0.65, 0.42),
      Offset(0.1, 0.68),
      Offset(0.9, 0.6),
      Offset(0.45, 0.88),
    ];
    final pos = positions[index];
    final delay = index * 0.18;
    final icons = [
      Icons.star_rounded,
      Icons.circle,
      Icons.star_rounded,
      Icons.circle,
      Icons.star_rounded,
      Icons.circle,
    ];

    return AnimatedBuilder(
      animation: _floatController,
      builder: (_, __) {
        final t = (_floatController.value + delay) % 1.0;
        final yOffset = -8 * math.sin(t * math.pi * 2);
        final opacity = 0.15 + 0.25 * math.sin(t * math.pi * 2).abs();

        return Positioned(
          left: size.width * pos.dx,
          top: size.height * pos.dy + yOffset,
          child: Icon(
            icons[index],
            size: index.isEven ? 8 : 5,
            color: Colors.white.withOpacity(opacity),
          ),
        );
      },
    );
  }

  Widget _buildHeroIllustration(Size size) {
    final double w = math.min(size.width * 0.75, 280);

    return SizedBox(
      width: w,
      height: w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring
          AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) {
              final pulse = 0.92 + 0.08 * _floatController.value;
              return Transform.scale(
                scale: pulse,
                child: Container(
                  width: w,
                  height: w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1E88E5).withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),

          // Mid ring
          Container(
            width: w * 0.75,
            height: w * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF1E88E5).withOpacity(0.2),
                width: 1,
              ),
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1565C0).withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Inner main circle
          Container(
            width: w * 0.52,
            height: w * 0.52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1565C0),
                  Color(0xFF1E88E5),
                  Color(0xFF29B6F6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.beach_access_rounded,
              size: w * 0.22,
              color: Colors.white.withOpacity(0.95),
            ),
          ),

          // Orbiting dot top-right
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              final angle = _bgController.value * 2 * math.pi;
              final r = w * 0.38;
              return Positioned(
                left: w / 2 + r * math.cos(angle) - 7,
                top: w / 2 + r * math.sin(angle) - 7,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF7A30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7A30).withOpacity(0.6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Orbiting dot bottom-left (counter)
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              final angle = -_bgController.value * 2 * math.pi + math.pi * 0.6;
              final r = w * 0.35;
              return Positioned(
                left: w / 2 + r * math.cos(angle) - 5,
                top: w / 2 + r * math.sin(angle) - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF29B6F6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF29B6F6).withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating card — top left
          Positioned(
            top: w * 0.04,
            left: w * 0.0,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    -6 * math.sin(_floatController.value * math.pi + 1),
                  ),
                  child: _buildFloatingCard(
                    icon: Icons.calendar_today_rounded,
                    label: '12 Hari',
                    sub: 'Sisa Cuti',
                    color: const Color(0xFF29B6F6),
                  ),
                );
              },
            ),
          ),

          // Floating card — bottom right
          Positioned(
            bottom: w * 0.04,
            right: w * 0.0,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    -6 * math.sin(_floatController.value * math.pi),
                  ),
                  child: _buildFloatingCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Disetujui',
                    sub: 'Status',
                    color: const Color(0xFF43A047),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCard({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137).withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Grid Painter ──
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

// ── Feature Pill ──
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
