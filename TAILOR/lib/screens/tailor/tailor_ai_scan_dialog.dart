import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme/tailor_theme.dart';

class TailorAiScanDialog extends StatefulWidget {
  const TailorAiScanDialog({super.key});

  @override
  State<TailorAiScanDialog> createState() => _TailorAiScanDialogState();
}

class _TailorAiScanDialogState extends State<TailorAiScanDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _status = 'idle'; // 'idle' | 'scanning' | 'completed'
  double _progress = 0.0;

  String _selectedGender = 'female';
  double _heightCm = 170.0;

  double _chest = 34.0;
  double _waist = 28.0;
  double _hips = 38.0;
  double _shoulders = 15.5;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _status = 'scanning';
      _progress = 0.0;
    });

    _animationController.reset();
    _animationController.addListener(() {
      setState(() {
        _progress = _animationController.value;
      });
    });

    _animationController.forward().then((_) {
      final random = Random();
      final double baseChest = _selectedGender == 'male' ? 38.0 : 34.0;
      final double baseWaist = _selectedGender == 'male' ? 32.0 : 27.0;
      final double heightFactor = (_heightCm - 170.0) * 0.1;

      setState(() {
        _status = 'completed';
        _chest = double.parse((baseChest + heightFactor + (random.nextDouble() * 3) - 1.5).toStringAsFixed(1));
        _waist = double.parse((baseWaist + heightFactor + (random.nextDouble() * 3) - 1.5).toStringAsFixed(1));
        _hips = double.parse((_chest + 3.0 + random.nextDouble() * 2).toStringAsFixed(1));
        _shoulders = double.parse(((_selectedGender == 'male' ? 17.5 : 15.0) + heightFactor + random.nextDouble()).toStringAsFixed(1));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TailorTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: TailorTheme.primaryPurple, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'AI Scan Sizing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_status == 'idle') ...[
              Text(
                'Calibrate parameters to generate mock AI body scanning measurements.',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 20),
              // Gender selection
              Text(
                'Gender',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['female', 'male'].map((gender) {
                  final isSelected = _selectedGender == gender;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: gender == 'female' ? 8.0 : 0.0),
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedGender = gender),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected ? TailorTheme.primaryPurple.withOpacity(0.2) : Colors.transparent,
                          side: BorderSide(
                            color: isSelected ? TailorTheme.primaryPurple : Colors.grey[700]!,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          gender[0].toUpperCase() + gender.substring(1),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Height selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Height', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  Text('${_heightCm.toInt()} cm', style: const TextStyle(color: TailorTheme.primaryPurple, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _heightCm,
                min: 140,
                max: 210,
                activeColor: TailorTheme.primaryPurple,
                inactiveColor: Colors.grey[800],
                onChanged: (val) => setState(() => _heightCm = val),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startScanning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TailorTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start AI Scan Simulation', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else if (_status == 'scanning') ...[
              const SizedBox(height: 24),
              const Center(
                child: SizedBox(
                  height: 80,
                  width: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(TailorTheme.primaryPurple),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Extracting body dimensions from camera stream...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toInt()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: TailorTheme.primaryPurple,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    _buildResultRow('Chest', '$_chest in'),
                    const Divider(height: 20, color: Colors.grey),
                    _buildResultRow('Waist', '$_waist in'),
                    const Divider(height: 20, color: Colors.grey),
                    _buildResultRow('Hips', '$_hips in'),
                    const Divider(height: 20, color: Colors.grey),
                    _buildResultRow('Shoulders', '$_shoulders in'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _status = 'idle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                        side: BorderSide(color: Colors.grey[700]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Scan Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'chest': _chest,
                          'waist': _waist,
                          'hips': _hips,
                          'shoulders': _shoulders,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TailorTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Use Results', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
