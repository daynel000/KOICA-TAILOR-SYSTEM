// screens/orders_screen.dart - Tab 2: My Orders + Create Request Wizard
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/app_provider.dart';
import '../models/order_model.dart';
import '../widgets/order_card.dart';
import '../widgets/order_detail_sheet.dart';
import '../widgets/create_order_wizard.dart';

class OrdersScreen extends StatefulWidget {
  final void Function(int) onNavigateToTab;
  final void Function(String) onShowToast;
  const OrdersScreen({super.key, required this.onNavigateToTab, required this.onShowToast});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _activeFilter = 'all'; // 'all' | 'progress' | 'completed'
  bool _showWizard = false;

  List<OrderModel> _getFilteredOrders(AppProvider provider) {
    switch (_activeFilter) {
      case 'progress':  return provider.activeOrders;
      case 'completed': return provider.completedOrders;
      default:          return provider.orderList;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (_showWizard) {
      return CreateOrderWizard(
        tailors: provider.tailorList,
        savedScanResult: provider.savedScanResult,
        onNavigateToTab: widget.onNavigateToTab,
        onCancel: () => setState(() => _showWizard = false),
        onSubmit: (formData) async {
          await provider.createNewOrder(formData);
          setState(() => _showWizard = false);
          widget.onShowToast('Request submitted! Estimated completion date set.');
        },
      );
    }

    final orders = _getFilteredOrders(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Requests', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF132238))),
                  ElevatedButton(
                    onPressed: () => setState(() => _showWizard = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Create Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  for (final f in [('all', 'All'), ('progress', 'In Progress'), ('completed', 'Completed')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeFilter = f.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _activeFilter == f.$1 ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(f.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _activeFilter == f.$1 ? Colors.white : AppColors.textSecondary)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Orders list
            Expanded(
              child: orders.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('No requests yet', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _showWizard = true),
                        child: Text('Start your first order', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ]))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => provider.refreshOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                        itemCount: orders.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OrderCard(
                            order: orders[i],
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => OrderDetailSheet(
                                order: orders[i],
                                onOpenChat: () {
                                  Navigator.pop(context);
                                  provider.selectOrderForChat(orders[i]);
                                  widget.onNavigateToTab(4);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
