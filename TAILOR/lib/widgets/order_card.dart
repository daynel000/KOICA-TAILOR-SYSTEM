// widgets/order_card.dart
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  const OrderCard({super.key, required this.order, required this.onTap});

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.submitted:  return AppColors.statusSubmitted;
      case OrderStatus.accepted:   return AppColors.statusAccepted;
      case OrderStatus.cutting:    return AppColors.statusCutting;
      case OrderStatus.fitting:    return AppColors.statusFitting;
      case OrderStatus.completed:  return AppColors.statusCompleted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48, height: 62,
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: order.inspirationImageUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(order.inspirationImageUrl!, fit: BoxFit.cover))
                : Center(child: Icon(Icons.auto_awesome_rounded, size: 20, color: AppColors.primaryLight)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(order.garmentType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF132238)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))),
                  child: Text(order.status.name.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: statusColor)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(order.tailorShopName, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Due: ${order.estimatedCompletionDate}', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontFamily: 'monospace')),
              ]),
            ])),
          ]),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: order.progressPercentage / 100,
              backgroundColor: AppColors.background,
              color: statusColor,
              minHeight: 6,
            ),
          ),
        ]),
      ),
    );
  }
}
