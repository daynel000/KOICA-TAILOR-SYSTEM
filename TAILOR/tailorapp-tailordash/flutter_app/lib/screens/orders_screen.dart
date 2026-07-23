import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterTab('All', isSelected: true),
                _buildFilterTab('In Progress'),
                _buildFilterTab('Completed'),
              ],
            ),
          ),
          
          // Orders List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: 4, // Mock data count
              itemBuilder: (context, index) {
                return _buildOrderCard();
              },
            ),
          ),
        ],
      ),
      // AI Scan Floating Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open Camera for AI Scan
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Start AI Scan'),
      ),
    );
  }

  Widget _buildFilterTab(String title, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryPurple),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.primaryPurple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrderCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Maria Santos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Due: July 20', style: TextStyle(color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Evening Gown', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            
            // Progress Bar
            Row(
              children: [
                const Text('Progress: 65%', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 10),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: Colors.grey[800],
                    color: AppTheme.primaryPurple,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
