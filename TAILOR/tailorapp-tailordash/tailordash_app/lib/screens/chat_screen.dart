import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'chat_conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      // Each order is a "chat thread" between tailor and customer
      final orders = await _apiService.fetchOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryPurple));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load chats',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadOrders();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Text('No active orders or messages.',
            style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.primaryPurple,
      child: ListView.separated(
        itemCount: _orders.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
        itemBuilder: (context, index) {
          return _buildChatTile(_orders[index] as Map<String, dynamic>);
        },
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> order) {
    final customerName = order['customer_name'] ?? 'Unknown Customer';
    final clothingType = order['clothing_type'] ?? '';
    final status = order['status'] ?? '';
    final orderId = order['order_id'] as int;

    Color statusColor = AppTheme.primaryPurple;
    if (status == 'new') statusColor = Colors.blue;
    if (status == 'completed') statusColor = AppTheme.primaryGreen;
    if (status == 'cancelled') statusColor = Colors.red;
    if (status == 'in_progress') statusColor = Colors.orange;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryPurple.withOpacity(0.3),
        radius: 26,
        child: Text(
          customerName.isNotEmpty ? customerName[0] : '?',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      title: Text(customerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Row(
        children: [
          const Icon(Icons.checkroom, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(clothingType, style: const TextStyle(color: Colors.grey)),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status.replaceAll('_', ' '),
          style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              orderId: orderId,
              customerName: customerName,
              clothingType: clothingType,
            ),
          ),
        );
      },
    );
  }
}
