import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Tailors'),
      ),
      body: Stack(
        children: [
          // Mock Map Background
          Container(
            color: Colors.grey[900],
            child: const Center(
              child: Text(
                'OpenStreetMap View Here',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            ),
          ),
          
          // Mock Map Pins
          Positioned(
            top: 150,
            left: 100,
            child: _buildMapPin(isMe: true),
          ),
          Positioned(
            top: 250,
            right: 80,
            child: _buildMapPin(),
          ),
          
          // Bottom Info Card (when a pin is tapped)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tailor B Shop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('1.2 km away • ★ 4.8', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                        onPressed: () {
                          // TODO: Send collaboration request
                        },
                        child: const Text('Request Collaboration'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin({bool isMe = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryPurple : AppTheme.primaryGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          isMe ? 'You' : 'Tailor B',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
