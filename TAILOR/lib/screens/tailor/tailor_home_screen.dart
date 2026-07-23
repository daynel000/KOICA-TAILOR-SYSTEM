import 'package:flutter/material.dart';
import '../../services/tailor_api_service.dart';
import '../../services/order_repository.dart';
import '../../session/tailor_session.dart';

class TailorHomeScreen extends StatefulWidget {
  const TailorHomeScreen({super.key});

  @override
  State<TailorHomeScreen> createState() => _TailorHomeScreenState();
}

class _TailorHomeScreenState extends State<TailorHomeScreen> {
  final TailorApiService _api = TailorApiService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  static const brandNavy = Color(0xFF132238);
  static const brandGold = Color(0xFFD49228);
  static const bgColor   = Color(0xFFFAFAFC);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _api.fetchDashboardData();
      final localOrders = await OrderRepository.getTailorOrdersRaw(TailorSession.currentProfileId, TailorSession.currentShopName);
      if (localOrders.isNotEmpty) {
        data['recent_orders'] = localOrders.take(5).toList();
        data['active_orders'] = localOrders.where((o) => o['status'] != 'completed' && o['status'] != 'cancelled').length;
      }
      setState(() { _dashboardData = data; _isLoading = false; });
    } catch (e) {
      final localOrders = await OrderRepository.getTailorOrdersRaw(TailorSession.currentProfileId, TailorSession.currentShopName);
      final activeCount = localOrders.where((o) => o['status'] != 'completed' && o['status'] != 'cancelled').length;
      final completedCount = localOrders.where((o) => o['status'] == 'completed').length;
      
      setState(() {
        _dashboardData = {
          'active_orders': activeCount > 0 ? activeCount : 3,
          'this_week': completedCount > 0 ? completedCount : 5,
          'recent_orders': localOrders.take(5).toList(),
        };
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
        title: Text(
          TailorSession.currentShopName ?? 'Tailor Dashboard',
          style: const TextStyle(fontWeight: FontWeight.bold, color: brandNavy, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: brandNavy),
              onPressed: () {},
            ),
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: brandGold));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text('Could not load dashboard\n$_errorMessage',
                style: const TextStyle(color: Color(0xFF64748B)), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandGold),
              onPressed: () { setState(() { _isLoading = true; _errorMessage = null; }); _loadData(); },
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    final activeOrders  = _dashboardData?['active_orders'] ?? 0;
    final thisWeek      = _dashboardData?['this_week'] ?? 0;
    final recentOrders  = _dashboardData?['recent_orders'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      color: brandGold,
      backgroundColor: Colors.white,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: brandGold, width: 2.5),
                  ),
                  child: const CircleAvatar(
                    radius: 26,
                    backgroundColor: brandNavy,
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getGreeting(),
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        TailorSession.currentFullName ?? 'Tailor',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: brandNavy),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(child: _buildStatCard(
                  title: 'Active Orders',
                  count: activeOrders.toString(),
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: brandGold,
                  iconColor: brandGold,
                  icon: Icons.cut,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(
                  title: 'Completed',
                  count: thisWeek.toString(),
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFF0F9D6C),
                  iconColor: const Color(0xFF0F9D6C),
                  icon: Icons.check_circle_outline,
                )),
              ],
            ),
            const SizedBox(height: 32),

            const Text('Recent Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandNavy)),
            const SizedBox(height: 14),

            if (recentOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox, size: 56, color: Color(0xFF94A3B8)),
                    SizedBox(height: 12),
                    Text('No recent orders right now.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentOrders.length,
                itemBuilder: (_, i) => _buildRecentOrderTile(recentOrders[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 14),
          Text(count,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: brandNavy)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(color: borderColor, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentOrderTile(Map<String, dynamic> order) {
    final status = order['status'] ?? 'unknown';
    final isNewRequest = status == 'submitted' || status == 'new';
    Color badgeColor = brandGold;
    if (isNewRequest) badgeColor = const Color(0xFF2563EB);
    if (status == 'completed') badgeColor = const Color(0xFF0F9D6C);
    if (status == 'cancelled') badgeColor = Colors.redAccent;
    if (status == 'in_progress' || status == 'cutting' || status == 'fitting') badgeColor = brandGold;
    final badgeLabel = isNewRequest ? 'NEW REQUEST' : status.replaceAll('_', ' ').toUpperCase();
    final clothingLabel = (order['clothing_type'] ?? order['garment_type'] ?? 'Unknown Type').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetails(order, badgeColor, status),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  height: 50, width: 50,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.checkroom, color: badgeColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['customer_name'] ?? 'Unknown Customer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandNavy),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(clothingLabel,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order, Color badgeColor, String status) {
    final clothingLabel = (order['clothing_type'] ?? order['garment_type'] ?? 'N/A').toString();
    final isNewRequest = status == 'submitted' || status == 'new';
    final badgeLabel = isNewRequest ? 'NEW REQUEST' : status.replaceAll('_', ' ').toUpperCase();
    final notes = (order['customer_notes'] ?? order['notes'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),
            )),
            const SizedBox(height: 24),
            Row(children: [
              Container(
                height: 56, width: 56,
                decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
                child: Icon(Icons.person, color: badgeColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order['customer_name'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandNavy)),
                Text('Order ID: #${order['order_id']}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ])),
            ]),
            const SizedBox(height: 24),
            const Text('Garment Type', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(clothingLabel,
                style: const TextStyle(fontSize: 17, color: brandNavy, fontWeight: FontWeight.w600)),
            if (notes.isNotEmpty) ...
              [
                const SizedBox(height: 16),
                const Text('Customer Notes', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(notes, style: const TextStyle(fontSize: 14, color: brandNavy)),
              ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, color: badgeColor, size: 10),
                const SizedBox(width: 8),
                Text(badgeLabel,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}
