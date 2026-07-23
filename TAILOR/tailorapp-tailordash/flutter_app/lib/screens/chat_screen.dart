import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: ListView.builder(
        itemCount: 5, // Mock number of chats
        itemBuilder: (context, index) {
          return _buildChatTile(index);
        },
      ),
    );
  }

  Widget _buildChatTile(int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[800],
        child: const Icon(Icons.person, color: Colors.white),
      ),
      title: const Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Is my order ready?'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('10:30 AM', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          if (index == 0) // Mock unread badge
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Text('1', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      onTap: () {
        // TODO: Open chat conversation screen
      },
    );
  }
}
