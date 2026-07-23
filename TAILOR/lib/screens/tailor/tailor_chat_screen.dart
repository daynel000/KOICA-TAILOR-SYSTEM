import 'package:flutter/material.dart';
import '../../services/tailor_api_service.dart';
import 'tailor_chat_conversation_screen.dart';

class TailorChatScreen extends StatefulWidget {
  const TailorChatScreen({super.key});

  @override
  State<TailorChatScreen> createState() => _TailorChatScreenState();
}

class _TailorChatScreenState extends State<TailorChatScreen> {
  final TailorApiService _api = TailorApiService();
  List<dynamic> _orders = [];
  bool   _isLoading    = true;
  String? _errorMessage;

  static const brandNavy = Color(0xFF132238);
  static const brandGold = Color(0xFFD49228);
  static const bgColor   = Color(0xFFFAFAFC);

  @override
  void initState() { super.initState(); _loadOrders(); }

  Future<void> _loadOrders() async {
    try {
      final orders = await _api.fetchOrders();
      setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      // Fallback demo chats for offline mode
      setState(() {
        _orders = [
          {
            'order_id': 101,
            'customer_name': 'Sarah Jenkins',
            'clothing_type': 'Custom Silk Dress',
            'status': 'in_progress',
          },
          {
            'order_id': 102,
            'customer_name': 'Michael Tan',
            'clothing_type': '3-Piece Tuxedo Fit',
            'status': 'new',
          },
          {
            'order_id': 103,
            'customer_name': 'Maria Santos',
            'clothing_type': 'Evening Gown Alteration',
            'status': 'completed',
          },
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Messages', style: TextStyle(color: brandNavy, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: brandGold));

    if (_errorMessage != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 12),
        const Text('Could not load chats', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: brandNavy),
          onPressed: () { setState(() { _isLoading = true; _errorMessage = null; }); _loadOrders(); },
          icon: const Icon(Icons.refresh), label: const Text('Retry'),
        ),
      ]));
    }

    if (_orders.isEmpty) {
      return const Center(child: Text('No active orders or messages.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 16)));
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: brandGold,
      child: ListView.separated(
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
        itemBuilder: (_, i) => _buildChatTile(_orders[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> order) {
    final customerName = order['customer_name'] ?? 'Unknown';
    final clothingType = order['clothing_type'] ?? '';
    final status       = order['status'] ?? '';
    final orderId      = order['order_id'] as int;

    Color statusColor = brandNavy;
    if (status == 'new')         statusColor = const Color(0xFF2563EB);
    if (status == 'completed')   statusColor = const Color(0xFF0F9D6C);
    if (status == 'cancelled')   statusColor = Colors.redAccent;
    if (status == 'in_progress') statusColor = brandGold;

    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: brandNavy,
          radius: 24,
          child: Text(
            customerName.isNotEmpty ? customerName[0] : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        title: Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandNavy)),
        subtitle: Row(children: [
          const Icon(Icons.checkroom, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(clothingType, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ]),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Text(status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => TailorChatConversationScreen(
            orderId: orderId,
            customerName: customerName,
            clothingType: clothingType,
          ),
        )),
      ),
    );
  }
}
