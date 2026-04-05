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
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMessage = 'Tidak ada kamera tersedia');
        return;
      }

      CameraDescription? frontCamera;
      for (final cam in _cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          frontCamera = cam;
          break;
        }
      }
      final selectedCamera = frontCamera ?? _cameras.first;

      _controller = CameraController(
        selectedCamera,
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

                  // ── Badge Kamera Depan ────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.face, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Kamera Depan',
                          style: TextStyle(color: Colors.white, fontSize: 12),
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
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: CameraPreview(_controller!),
                      ),
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

          // Bottom bar — shutter
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
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
              child: Center(
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14159265),
                    child: Image.file(_capturedPhoto!, fit: BoxFit.cover),
                  ),
                ),
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
