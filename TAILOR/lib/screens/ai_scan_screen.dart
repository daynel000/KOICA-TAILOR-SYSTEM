import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../main.dart';
import '../providers/app_provider.dart';
import '../models/scan_result_model.dart';

class AIScanScreen extends StatefulWidget {
  final void Function(int) onNavigateToTab;
  final void Function(String) onShowToast;
  final bool isActive;
  const AIScanScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onShowToast,
    required this.isActive,
  });

  @override
  State<AIScanScreen> createState() => _AIScanScreenState();
}

class _AIScanScreenState extends State<AIScanScreen> with TickerProviderStateMixin {
  String _selectedGender = 'female'; // 'female' | 'male' | 'unisex'
  int _heightCm = 165;
  String _scanState = 'idle';        // 'idle' | 'scanning' | 'completed' | 'error'
  double _scanProgress = 0;
  ScanResultModel? _scanResult;
  late AnimationController _pulseController;

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = true;
  Uint8List? _capturedBytes;
  String? _cameraInitializationError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    final saved = context.read<AppProvider>().savedScanResult;
    if (saved != null) {
      setState(() {
        _scanResult = saved;
        _scanState = 'completed';
      });
    }
    if (widget.isActive) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(AIScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _deinitializeCamera();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _deinitializeCamera();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_cameraController != null) return;
    setState(() {
      _isCameraInitializing = true;
      _cameraInitializationError = null;
    });
    try {
      try {
        _cameras = await availableCameras();
      } catch (e) {
        debugPrint('availableCameras failed: $e');
      }

      CameraDescription selectedCamera;
      if (_cameras.isNotEmpty) {
        try {
          selectedCamera = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
          );
        } catch (_) {
          try {
            selectedCamera = _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
            );
          } catch (_) {
            selectedCamera = _cameras.first;
          }
        }
      } else {
        selectedCamera = const CameraDescription(
          name: 'default',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        );
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _cameraInitializationError = e.toString();
          _isCameraInitialized = false;
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _deinitializeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      widget.onShowToast('Camera is not ready');
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      final Uint8List bytes = await photo.readAsBytes();
      
      setState(() {
        _capturedBytes = bytes;
      });

      await _runScanWithImage(bytes);
    } catch (e) {
      widget.onShowToast('Failed to capture photo: $e');
    }
  }

  Future<void> _uploadAndScan() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1350,
      );

      if (photo == null) return;

      final Uint8List bytes = await photo.readAsBytes();
      setState(() {
        _capturedBytes = bytes;
      });

      await _runScanWithImage(bytes);
    } catch (e) {
      widget.onShowToast('Failed to load image: $e');
    }
  }

  Future<void> _runScanWithImage(Uint8List bytes) async {
    setState(() {
      _scanState = 'scanning';
      _scanProgress = 0;
      _scanResult = null;
    });

    final String base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    final progressFuture = Future(() async {
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _scanProgress = i.toDouble());
      }
    });

    try {
      final result = await context.read<AppProvider>().runAIBodyScan(
        imageUrl: base64Image,
        gender: _selectedGender,
        heightCm: _heightCm,
      );

      await progressFuture;

      if (mounted) {
        setState(() {
          _scanResult = result;
          _scanState = 'completed';
        });
      }
    } catch (e) {
      debugPrint('Scan API error: $e');
      if (mounted) {
        setState(() => _scanState = 'error');
        widget.onShowToast('Scan failed. Please try again.');
      }
    }
  }

  Future<void> _retryScan() async {
    if (_capturedBytes != null) {
      await _runScanWithImage(_capturedBytes!);
    } else {
      setState(() => _scanState = 'idle');
    }
  }

  Future<void> _saveScanResult() async {
    if (_scanResult == null) return;
    await context.read<AppProvider>().saveScanResult(_scanResult!);
    widget.onShowToast('AI Body Dimensions saved! Recommended size: ${_scanResult!.recommendedSize}');
    widget.onNavigateToTab(4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Body Scan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF132238))),
              const SizedBox(height: 4),
              Text('Position in frame for automatic measurements', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              // Gender selector
              if (_scanState == 'idle') ...[
                _buildCalibrationCard(),
                const SizedBox(height: 16),
              ],

              // Scan viewport
              _buildScanViewport(),
              const SizedBox(height: 20),

              // Action buttons
              if (_scanState == 'idle') ...[
                Row(
                  children: [
                    if (_isCameraInitialized) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _captureAndScan,
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                          label: const Text('Capture & Scan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploadAndScan,
                        icon: const Icon(Icons.photo_library_rounded, size: 20),
                        label: const Text('Upload Photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_scanState == 'scanning')
                _buildDisabledButton('Scanning Body Silhouettes...'),
              if (_scanState == 'error')
                _buildActionButton('Retry AI Scan', Icons.refresh_rounded, _retryScan),
              if (_scanState == 'completed' && _scanResult != null) ...[
                _buildResultsCard(_scanResult!),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => setState(() {
                      _capturedBytes = null;
                      _scanState = 'idle';
                    }),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Scan Again'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: _saveScanResult,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save to Profile'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  )),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalibrationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CALIBRATION SETUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          for (final g in ['female', 'male', 'unisex'])
            Expanded(child: Padding(
              padding: EdgeInsets.only(right: g != 'unisex' ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = g),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedGender == g ? AppColors.primary.withOpacity(0.2) : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedGender == g ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(g[0].toUpperCase() + g.substring(1), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _selectedGender == g ? AppColors.primaryLight : AppColors.textMuted)),
                ),
              ),
            )),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Height', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('$_heightCm cm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
        ]),
        Slider(
          value: _heightCm.toDouble(), min: 140, max: 210,
          activeColor: AppColors.primary, inactiveColor: AppColors.border,
          onChanged: (v) => setState(() => _heightCm = v.round()),
        ),
      ]),
    );
  }

  Widget _buildScanViewport() {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera preview or Captured Image or Silhouette
            if (_capturedBytes != null)
              Image.memory(_capturedBytes!, fit: BoxFit.cover)
            else if (_isCameraInitialized && _cameraController != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 720,
                  height: _cameraController!.value.previewSize?.width ?? 1280,
                  child: CameraPreview(_cameraController!),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0F1E),
                ),
              ),

            // 2. Loading state for camera initialization
            if (_capturedBytes == null && !_isCameraInitialized && _isCameraInitializing)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryLight,
                ),
              ),

            // 3. Body silhouette icon + guidance if camera is NOT running/initialized, or if there is no captured image
            if (_capturedBytes == null && !_isCameraInitialized && !_isCameraInitializing)
              Center(
                child: _cameraInitializationError != null
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppColors.red,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Camera Access Unavailable',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _cameraInitializationError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _initializeCamera,
                              icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primaryLight),
                              label: const Text(
                                'Retry Camera Access',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.accessibility_new_rounded,
                            size: 96,
                            color: AppColors.primary.withOpacity(0.25),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Stand in frame',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Keep 1.5–2 m from camera\nArms slightly away from body',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
              ),

            // 4. Alignment guide silhouette overlay when camera is live
            if (_scanState == 'idle' && _capturedBytes == null && _isCameraInitialized)
              IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: const Icon(
                      Icons.accessibility_new_rounded,
                      size: 220,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Corner guides
            for (final pos in ['tl', 'tr', 'bl', 'br']) _buildCornerGuide(pos),

            // Scan laser line
            if (_scanState == 'scanning')
              Align(
                alignment: Alignment(0, (_scanProgress / 50) - 1.0),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        AppColors.primaryLight.withOpacity(0.8 + _pulseController.value * 0.2),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),

            // Measurement lines (shown while scanning / completed)
            if (_scanState == 'scanning' || _scanState == 'completed')
              ..._buildMeasurementLines(),

            // Scanning progress badge
            if (_scanState == 'scanning')
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                    ),
                    child: Text(
                      'AI ANALYZING ${_scanProgress.round()}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryLight,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMeasurementLines() {
    final lines = [
      (0.30, 'Chest', _scanResult?.chestInches, AppColors.primaryLight),
      (0.48, 'Waist', _scanResult?.waistInches, AppColors.emerald),
      (0.65, 'Hips', _scanResult?.hipsInches, AppColors.amber),
    ];
    return lines.map((l) => Positioned(
      top: null, bottom: null, left: 0, right: 0,
      child: Align(
        alignment: Alignment(0, l.$1 * 2 - 1),
        child: Row(children: [
          Expanded(child: Divider(color: l.$4.withOpacity(0.5), thickness: 1, indent: 20)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l.$3 != null ? '${l.$3!.toStringAsFixed(1)}"' : '--', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: l.$4, fontFamily: 'monospace')),
            Text(l.$2, style: TextStyle(fontSize: 8, color: AppColors.textMuted, letterSpacing: 1)),
          ])),
          Expanded(child: Divider(color: l.$4.withOpacity(0.5), thickness: 1, endIndent: 20)),
        ]),
      ),
    )).toList();
  }

  Widget _buildCornerGuide(String position) {
    const size = 24.0;
    return Positioned(
      top: position.startsWith('t') ? 16 : null,
      bottom: position.startsWith('b') ? 16 : null,
      left: position.endsWith('l') ? 16 : null,
      right: position.endsWith('r') ? 16 : null,
      child: SizedBox(width: size, height: size, child: CustomPaint(painter: _CornerPainter(position))),
    );
  }

  Widget _buildResultsCard(ScanResultModel result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SCANNED SPECS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('Size: ${result.recommendedSize}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryLight))),
        ]),
        const SizedBox(height: 12),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 3,
          children: [
            _MeasCell('Chest', '${result.chestInches}"', AppColors.primaryLight),
            _MeasCell('Waist', '${result.waistInches}"', AppColors.emerald),
            _MeasCell('Hips', '${result.hipsInches}"', AppColors.amber),
            _MeasCell('Shoulders', '${result.shouldersInches}"', AppColors.textSecondary),
            _MeasCell('Inseam', '${result.inseamInches.toStringAsFixed(1)}"', AppColors.textSecondary),
            _MeasCell('Accuracy', result.confidencePercent, AppColors.emerald),
          ],
        ),
      ]),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(width: double.infinity, child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    ));
  }

  Widget _buildDisabledButton(String label) {
    return SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, disabledForegroundColor: AppColors.textMuted, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight)),
        const SizedBox(width: 10),
        Text(label),
      ]),
    ));
  }
}

class _MeasCell extends StatelessWidget {
  final String label; final String value; final Color color;
  const _MeasCell(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
    ]),
  );
}

class _CornerPainter extends CustomPainter {
  final String position;
  _CornerPainter(this.position);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white54..strokeWidth = 2..style = PaintingStyle.stroke;
    final bool isTop = position.startsWith('t');
    final bool isLeft = position.endsWith('l');
    if (isTop && isLeft) { canvas.drawLine(Offset.zero, Offset(size.width, 0), paint); canvas.drawLine(Offset.zero, Offset(0, size.height), paint); }
    else if (isTop && !isLeft) { canvas.drawLine(Offset.zero, Offset(size.width, 0), paint); canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint); }
    else if (!isTop && isLeft) { canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint); canvas.drawLine(Offset.zero, Offset(0, size.height), paint); }
    else { canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint); canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint); }
  }
  @override
  bool shouldRepaint(_) => false;
}
