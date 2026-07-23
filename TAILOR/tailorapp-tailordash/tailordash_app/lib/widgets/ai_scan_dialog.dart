import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AiScanDialog extends StatefulWidget {
  const AiScanDialog({Key? key}) : super(key: key);

  @override
  State<AiScanDialog> createState() => _AiScanDialogState();
}

class _AiScanDialogState extends State<AiScanDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isScanning = true;
  bool _scanComplete = false;

  final TextEditingController _chestCtrl = TextEditingController(text: '38');
  final TextEditingController _waistCtrl = TextEditingController(text: '32');
  final TextEditingController _hipsCtrl = TextEditingController(text: '40');
  final TextEditingController _shoulderCtrl = TextEditingController(text: '18');
  final TextEditingController _sleeveCtrl = TextEditingController(text: '25');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Simulate AI detection sequence
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanComplete = true;
        });
        _animController.stop();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipsCtrl.dispose();
    _shoulderCtrl.dispose();
    _sleeveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: 600,
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.3),
              blurRadius: 25,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppTheme.primaryPurple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Body Scanner', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Precision Sizing Capture', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),

            // Viewfinder / Results View
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Stack(
                  children: [
                    // Camera / Silhouette background
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.accessibility_new_rounded,
                          size: 180,
                          color: _scanComplete ? AppTheme.primaryGreen.withOpacity(0.8) : Colors.white24,
                        ),
                      ),
                    ),

                    // Laser Scanner Animation
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Positioned(
                            top: 20 + (_animController.value * 300),
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withOpacity(0.8),
                                    blurRadius: 12,
                                    spreadRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Status Overlay
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isScanning ? Icons.center_focus_strong : Icons.check_circle,
                              color: _isScanning ? AppTheme.primaryPurple : AppTheme.primaryGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isScanning ? 'AI Keypoints Detecting...' : 'Measurements Extracted!',
                              style: TextStyle(
                                color: _isScanning ? Colors.white : AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Detected Measurement Input Form (Appears when scan finishes)
                    if (_scanComplete)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.darkBackground.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Captured Sizing (Inches)',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text('Verify or adjust detected keypoints before sending:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                const SizedBox(height: 16),
                                _buildMeasureField('Chest / Bust', _chestCtrl, Icons.straighten),
                                _buildMeasureField('Waist', _waistCtrl, Icons.straighten),
                                _buildMeasureField('Hips', _hipsCtrl, Icons.straighten),
                                _buildMeasureField('Shoulder Width', _shoulderCtrl, Icons.straighten),
                                _buildMeasureField('Sleeve Length', _sleeveCtrl, Icons.straighten),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Action Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _scanComplete ? AppTheme.primaryGreen : AppTheme.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isScanning
                      ? null
                      : () {
                          final measurements = {
                            'chest': '${_chestCtrl.text} in',
                            'waist': '${_waistCtrl.text} in',
                            'hips': '${_hipsCtrl.text} in',
                            'shoulder': '${_shoulderCtrl.text} in',
                            'sleeve': '${_sleeveCtrl.text} in',
                          };
                          Navigator.pop(context, measurements);
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_scanComplete ? Icons.check : Icons.sync, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _isScanning ? 'Scanning Sizing...' : 'Attach AI Measurements',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMeasureField(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 1,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
