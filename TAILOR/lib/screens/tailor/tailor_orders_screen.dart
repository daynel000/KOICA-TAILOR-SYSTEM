import 'package:flutter/material.dart';
import '../../services/tailor_api_service.dart';
import '../../services/order_repository.dart';
import '../../session/tailor_session.dart';
import 'tailor_add_order_screen.dart';

class TailorOrdersScreen extends StatefulWidget {
  const TailorOrdersScreen({super.key});

  @override
  State<TailorOrdersScreen> createState() => _TailorOrdersScreenState();
}

class _TailorOrdersScreenState extends State<TailorOrdersScreen> {
  final TailorApiService _api = TailorApiService();
  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'New Requests', 'In Progress', 'Completed'];

  static const brandNavy = Color(0xFF132238);
  static const brandGold = Color(0xFFD49228);
  static const bgColor   = Color(0xFFFAFAFC);

  @override
  void initState() { super.initState(); _loadOrders(); }

  Future<void> _loadOrders() async {
    // Always load from the shared OrderRepository first (includes customer requests)
    final localOrders = await OrderRepository.getTailorOrdersRaw(
      TailorSession.currentProfileId,
      TailorSession.currentShopName,
    );
    try {
      final apiOrders = await _api.fetchOrders();
      // Merge: prefer API orders but also include any local ones not in API list
      final apiIds = apiOrders.map((o) => o['order_id'].toString()).toSet();
      final localOnly = localOrders.where((o) => !apiIds.contains(o['order_id'].toString())).toList();
      final merged = [...apiOrders, ...localOnly];
      setState(() { _allOrders = merged; _applyFilter(_activeFilter); _isLoading = false; });
    } catch (e) {
      setState(() {
        _allOrders = localOrders;
        _applyFilter(_activeFilter);
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      if (filter == 'All') {
        _filteredOrders = List.from(_allOrders);
      } else if (filter == 'New Requests') {
        _filteredOrders = _allOrders.where((o) => o['status'] == 'new' || o['status'] == 'submitted').toList();
      } else if (filter == 'In Progress') {
        _filteredOrders = _allOrders.where((o) => o['status'] == 'in_progress' || o['status'] == 'accepted' || o['status'] == 'cutting' || o['status'] == 'fitting').toList();
      } else if (filter == 'Completed') {
        _filteredOrders = _allOrders.where((o) => o['status'] == 'completed').toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Manage Orders', style: TextStyle(color: brandNavy, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: brandGold,
        elevation: 2,
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const TailorAddOrderScreen()));
          if (res == true) _loadOrders();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _applyFilter(f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: _activeFilter == f ? brandNavy : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _activeFilter == f ? brandNavy : const Color(0xFFCBD5E1)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
                      ],
                    ),
                    child: Text(f, style: TextStyle(
                      color: _activeFilter == f ? Colors.white : brandNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    )),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
        Expanded(child: _buildList()),
      ]),
    );
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: brandGold));

    if (_errorMessage != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 12),
        const Text('Could not load orders', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: brandNavy),
          onPressed: () { setState(() { _isLoading = true; _errorMessage = null; }); _loadOrders(); },
          icon: const Icon(Icons.refresh), label: const Text('Retry'),
        ),
      ]));
    }

    if (_filteredOrders.isEmpty) {
      return const Center(child: Text('No orders found in this category.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)));
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: brandGold,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredOrders.length,
        itemBuilder: (_, i) => _buildCard(_filteredOrders[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'new';
    final customer = order['customer_name'] ?? 'Unknown Customer';
    final clothing = (order['clothing_type'] ?? order['garment_type'] ?? 'Tailoring Job').toString();
    final progress = ((order['progress_percent'] ?? 0) as num).toInt();
    final orderId = order['order_id'];
    final isNewRequest = status == 'submitted' || status == 'new';

    Color badgeColor = brandGold;
    if (isNewRequest)            badgeColor = const Color(0xFF2563EB);
    if (status == 'completed')   badgeColor = const Color(0xFF0F9D6C);
    if (status == 'cancelled')   badgeColor = Colors.redAccent;
    if (status == 'in_progress' || status == 'cutting' || status == 'fitting') badgeColor = brandGold;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(customer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: brandNavy)),
              const SizedBox(height: 2),
              Text(clothing, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: badgeColor.withOpacity(0.3)),
              ),
              child: Text(status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Progress', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            Text('$progress%', style: const TextStyle(color: brandNavy, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              backgroundColor: const Color(0xFFF1F5F9),
              color: badgeColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandNavy,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openUpdateModal(order),
                child: const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showSizingData(order),
                child: const Text('View Sizing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _openUpdateModal(Map<String, dynamic> order) {
    String selectedStatus = order['status'] ?? 'new';
    double selectedProgress = ((order['progress_percent'] ?? 0) as num).toDouble();
    final orderId = order['order_id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            const Text('Update Order Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandNavy)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'submitted', child: Text('New Request')),
                DropdownMenuItem(value: 'new', child: Text('Accepted')),
                DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (val) => setModalState(() => selectedStatus = val!),
            ),
            const SizedBox(height: 16),
            Text('Progress: ${selectedProgress.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: brandNavy)),
            Slider(
              value: selectedProgress,
              min: 0, max: 100, divisions: 20,
              activeColor: brandGold,
              inactiveColor: const Color(0xFFF1F5F9),
              onChanged: (val) => setModalState(() => selectedProgress = val),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: brandGold, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  // Persist to shared OrderRepository so the Customer app sees the update
                  await OrderRepository.updateOrderStatus(orderId, selectedStatus, selectedProgress.toInt());
                  try {
                    if (orderId is int) {
                      await _api.updateOrderStatus(orderId, selectedStatus, selectedProgress.toInt());
                    }
                  } catch (_) {}
                  if (context.mounted) Navigator.pop(context);
                  _loadOrders();
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showSizingData(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 16),
          Text('${order['customer_name']} — Sizing Data', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandNavy)),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _measureChip('Chest / Bust', order['chest']),
            _measureChip('Waist', order['waist']),
            _measureChip('Hip', order['hip']),
            _measureChip('Inseam', order['inseam']),
            _measureChip('Shoulder', order['shoulder']),
            _measureChip('Sleeve', order['sleeve']),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandNavy, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _measureChip(String label, dynamic val) {
    if (val == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        const SizedBox(height: 2),
        Text('$val in', style: const TextStyle(color: brandNavy, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }
}
