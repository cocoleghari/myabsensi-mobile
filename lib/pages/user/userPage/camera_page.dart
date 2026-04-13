import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  String? _errorMessage;

  // Foto yang sudah diambil — null berarti masih mode kamera
  File? _capturedPhoto;

  // Mode flash: off, auto, always on
  FlashMode _flashMode = FlashMode.off;

  // Index kamera aktif
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initCamera([int cameraIndex = -1]) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMessage = 'Tidak ada kamera tersedia');
        return;
      }

      // Pertama kali → cari kamera depan
      if (cameraIndex == -1) {
        int frontIndex = 0;
        for (int i = 0; i < _cameras.length; i++) {
          if (_cameras[i].lensDirection == CameraLensDirection.front) {
            frontIndex = i;
            break;
          }
        }
        _selectedCameraIndex = frontIndex;
      } else {
        _selectedCameraIndex = cameraIndex;
      }

      // Dispose controller lama sebelum buat baru
      await _controller?.dispose();
      if (mounted) setState(() => _isInitialized = false);

      _controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Gagal membuka kamera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCamera(nextIndex);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final XFile photo = await _controller!.takePicture();

      if (mounted) {
        setState(() {
          _capturedPhoto = File(photo.path);
          _isTakingPicture = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Gagal mengambil foto: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() => _isTakingPicture = false);
      }
    }
  }

  // Siklus flash: off → auto → always → off
  Future<void> _cycleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    FlashMode next;
    switch (_flashMode) {
      case FlashMode.off:
        next = FlashMode.auto;
        break;
      case FlashMode.auto:
        next = FlashMode.always;
        break;
      case FlashMode.always:
      default:
        next = FlashMode.off;
        break;
    }

    await _controller!.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  // Icon dan label sesuai mode flash aktif
  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
      default:
        return Icons.flash_off;
    }
  }

  String get _flashLabel {
    switch (_flashMode) {
      case FlashMode.auto:
        return 'Auto';
      case FlashMode.always:
        return 'On';
      case FlashMode.off:
      default:
        return 'Off';
    }
  }

  // Apakah kamera aktif adalah kamera depan
  bool get _isFrontCamera {
    if (_cameras.isEmpty || _selectedCameraIndex >= _cameras.length) {
      return false;
    }
    return _cameras[_selectedCameraIndex].lensDirection ==
        CameraLensDirection.front;
  }

  // User konfirmasi pakai foto ini
  void _confirmPhoto() {
    if (_capturedPhoto != null) {
      Get.back(result: _capturedPhoto);
    }
  }

  // User mau foto ulang
  void _retakePhoto() {
    setState(() => _capturedPhoto = null);
  }

  @override
  Widget build(BuildContext context) {
    // Jika sudah ada foto → tampilkan preview
    if (_capturedPhoto != null) {
      return _buildPreviewScreen();
    }
    // Belum ada foto → tampilkan kamera
    return _buildCameraScreen();
  }

  // ── LAYAR KAMERA ─────────────────────────────────────────────────────
  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(result: null),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),

                  // ── Tombol Flash ──────────────────────────────
                  GestureDetector(
                    onTap: _isInitialized ? _cycleFlash : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _flashMode == FlashMode.off
                            ? Colors.white12
                            : Colors.amber.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: _flashMode != FlashMode.off
                            ? Border.all(
                                color: Colors.amber.withOpacity(0.6),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _flashIcon,
                            color: _flashMode == FlashMode.off
                                ? Colors.white
                                : Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _flashLabel,
                            style: TextStyle(
                              color: _flashMode == FlashMode.off
                                  ? Colors.white
                                  : Colors.amber,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ── Badge Kamera (dinamis) ────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFrontCamera ? Icons.face : Icons.camera_rear,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isFrontCamera ? 'Kamera Depan' : 'Kamera Belakang',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Area kamera
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: _isInitialized && _controller != null
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final rawRatio = _controller!.value.aspectRatio;
                        // Normalisasi ke portrait: jika landscape (> 1), balik jadi 1/ratio
                        final camRatio = rawRatio > 1
                            ? 1 / rawRatio
                            : rawRatio; // rasio asli sensor
                        const targetRatio =
                            2 / 3; // rasio frame yang diinginkan

                        return Center(
                          child: ClipRect(
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxWidth / targetRatio,
                              child: OverflowBox(
                                maxWidth: double.infinity,
                                maxHeight: double.infinity,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxWidth / camRatio,
                                  child: CameraPreview(_controller!),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ),

          // Bottom bar — shutter + switch camera
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Tombol switch kamera (kiri) ──────────────
                      SizedBox(
                        width: 68,
                        child: _cameras.length >= 2
                            ? Center(
                                child: GestureDetector(
                                  onTap: _isInitialized ? _switchCamera : null,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white12,
                                    ),
                                    child: const Icon(
                                      Icons.flip_camera_ios,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ),

                      const SizedBox(width: 24),

                      // ── Tombol shutter (tengah) ───────────────────
                      GestureDetector(
                        onTap: _isTakingPicture ? null : _takePicture,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Center(
                            child: _isTakingPicture
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Container(
                                    width: 54,
                                    height: 54,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // ── Placeholder kanan (biar shutter tetap tengah) ──
                      const SizedBox(width: 68),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap untuk foto',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LAYAR PREVIEW FOTO ───────────────────────────────────────────────
  Widget _buildPreviewScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _retakePhoto,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Preview Foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),

          // Preview foto
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ClipRect(
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxWidth / (2 / 3),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(3.14159265),
                          child: Image.file(_capturedPhoto!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom bar — tombol aksi
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Tombol foto ulang
                  Expanded(
                    child: GestureDetector(
                      onTap: _retakePhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Foto Ulang',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Tombol gunakan foto
                  Expanded(
                    child: GestureDetector(
                      onTap: _confirmPhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Gunakan Foto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
