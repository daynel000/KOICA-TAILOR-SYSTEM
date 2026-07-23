import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'add_order_screen.dart';
import '../widgets/ai_scan_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _activeFilter = 'All';

  final List<String> _filters = ['All', 'In Progress', 'New', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _apiService.fetchOrders();
      setState(() {
        _allOrders = orders;
        _applyFilter(_activeFilter);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      if (filter == 'All') {
        _filteredOrders = List.from(_allOrders);
      } else if (filter == 'In Progress') {
        _filteredOrders = _allOrders
            .where((o) => o['status'] == 'in_progress' || o['status'] == 'accepted')
            .toList();
      } else if (filter == 'New') {
        _filteredOrders =
            _allOrders.where((o) => o['status'] == 'new').toList();
      } else if (filter == 'Completed') {
        _filteredOrders =
            _allOrders.where((o) => o['status'] == 'completed').toList();
      }
    });
  }

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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => _applyFilter(f),
                            child: _buildFilterTab(f,
                                isSelected: _activeFilter == f),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // Orders list or state widgets
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'aiScanBtn',
            backgroundColor: AppTheme.primaryPurple,
            onPressed: () async {
              final measurements = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => const AiScanDialog(),
              );
              if (measurements != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('AI Sizing Captured: ${measurements['chest']} Chest, ${measurements['waist']} Waist'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('AI Scan Sizing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'addOrderBtn',
            backgroundColor: AppTheme.primaryGreen,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddOrderScreen()),
              );
              if (result == true) {
                _loadOrders();
              }
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusSheet(Map<String, dynamic> order) {
    final orderId = order['order_id'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              _buildStatusOption(orderId, 'new', 0, 'New'),
              _buildStatusOption(orderId, 'accepted', 10, 'Accepted'),
              _buildStatusOption(orderId, 'in_progress', 50, 'In Progress'),
              _buildStatusOption(orderId, 'ready_for_fitting', 80, 'Ready for Fitting'),
              _buildStatusOption(orderId, 'completed', 100, 'Completed'),
              _buildStatusOption(orderId, 'cancelled', 0, 'Cancelled', isDestructive: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(int orderId, String status, int progress, String label, {bool isDestructive = false}) {
    return ListTile(
      title: Text(label, style: TextStyle(color: isDestructive ? Colors.red : Colors.white)),
      onTap: () async {
        Navigator.pop(context);
        try {
          await _apiService.updateOrderStatus(orderId, status, progress);
          _loadOrders(); // Refresh
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red));
          }
        }
      },
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
            Text('Could not load orders',
                style: TextStyle(color: Colors.grey[400], fontSize: 16)),
            const SizedBox(height: 4),
            Text(_errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center),
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

    if (_filteredOrders.isEmpty) {
      return Center(
        child: Text(
          'No orders in "$_activeFilter"',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.primaryPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(_filteredOrders[index]);
        },
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final progress = (order['progress_percent'] ?? 0) as int;
    final status = order['status'] ?? 'unknown';
    final dueDate = order['due_date'] ?? '';
    final customerName = order['customer_name'] ?? 'Unknown';
    final clothingType = order['clothing_type'] ?? 'Unknown';

    Color statusColor = AppTheme.primaryPurple;
    if (status == 'new') statusColor = Colors.blue;
    if (status == 'completed') statusColor = AppTheme.primaryGreen;
    if (status == 'cancelled') statusColor = Colors.red;
    if (status == 'in_progress') statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryPurple.withOpacity(0.3),
                      child: Text(
                        customerName.isNotEmpty ? customerName[0] : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Clothing type & due date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checkroom,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(clothingType,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                if (dueDate.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Due: $dueDate',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            Row(
              children: [
                Text('$progress%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey[800],
                      color: statusColor,
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showUpdateStatusSheet(order),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryPurple, side: const BorderSide(color: AppTheme.primaryPurple)),
                child: const Text('Update Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
