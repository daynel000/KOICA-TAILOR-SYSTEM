import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor Connect Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning, Gievey Reinz 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Active Orders',
                    count: '5',
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'This Week',
                    count: '12',
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            const Text(
              'Recent Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // List of recent orders
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Mock data count
                itemBuilder: (context, index) {
                  return _buildRecentOrderTile();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display a colored stat box
  Widget _buildStatCard({required String title, required String count, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // Widget to display a single recent order row
  Widget _buildRecentOrderTile() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPurple.withOpacity(0.5),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: const Text('Maria Santos'),
        subtitle: const Text('Evening Gown'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('In Progress', style: TextStyle(color: AppTheme.primaryPurple)),
        ),
      ),
    );
  }
}
