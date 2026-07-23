// widgets/order_detail_sheet.dart - Bottom sheet showing full order details + timeline
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/order_model.dart';

class OrderDetailSheet extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onOpenChat;
  const OrderDetailSheet({super.key, required this.order, required this.onOpenChat});

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
    final steps = [
      (OrderStatus.submitted, 'Request Submitted', 'Design draft and fabric requirements catalogued.'),
      (OrderStatus.accepted, 'Measurements Verified', 'Tailor confirmed the body measurement dimensions.'),
      (OrderStatus.cutting, 'Fabric Cutting', 'Base silhouette fabrics cut per specifications.'),
      (OrderStatus.fitting, 'Intermediate Fitting', 'Trial fitting session ready for adjustments.'),
      (OrderStatus.completed, 'Finished & Ready', 'Final quality check done. Ready for pickup.'),
    ];
    final currentStepIndex = steps.indexWhere((s) => s.$1 == order.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 10, bottom: 4), width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Order Tracking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF132238), letterSpacing: 0.5)),
              IconButton(icon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryLight, size: 22), onPressed: onOpenChat),
            ]),
          ),
          Expanded(child: ListView(controller: controller, padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), children: [
            // Main info
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order.garmentType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF132238))),
                  Text(order.tailorShopName, style: TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))), child: Text(order.status.name.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _InfoChip(Icons.calendar_today_outlined, 'Due Date', order.estimatedCompletionDate)),
                const SizedBox(width: 8),
                Expanded(child: _InfoChip(Icons.straighten_rounded, 'Fabric', order.fabricMaterial)),
              ]),
              const SizedBox(height: 10),
              Text('Progress: ${order.progressPercentage}%', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: order.progressPercentage / 100, backgroundColor: AppColors.border, color: statusColor, minHeight: 8)),
            ])),
            const SizedBox(height: 14),

            // Timeline
            Text('PRODUCTION TIMELINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Column(children: List.generate(steps.length, (i) {
                final isDone = i <= currentStepIndex;
                final isActive = i == currentStepIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      Container(width: 14, height: 14, decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : isDone ? AppColors.emerald : AppColors.border,
                        shape: BoxShape.circle,
                        border: Border.all(color: isActive ? AppColors.primaryLight : isDone ? AppColors.emerald : AppColors.border, width: 2),
                      ), child: isDone && !isActive ? const Icon(Icons.check_rounded, size: 8, color: Colors.white) : null),
                      if (i < steps.length - 1) Container(width: 1, height: 36, color: isDone ? AppColors.emerald.withOpacity(0.4) : AppColors.border),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(steps[i].$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? AppColors.primaryLight : isDone ? Colors.white : AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(steps[i].$3, style: TextStyle(fontSize: 10, color: isActive ? AppColors.textSecondary : AppColors.textMuted, height: 1.4)),
                    ])),
                  ]),
                );
              })),
            ),
            const SizedBox(height: 14),

            // Measurements
            Text('GARMENT MEASUREMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.2,
                children: [
                  _MeasCell('Chest', '${order.chestMeasurementInches}"'),
                  _MeasCell('Waist', '${order.waistMeasurementInches}"'),
                  _MeasCell('Hips', '${order.hipsMeasurementInches}"'),
                  _MeasCell('Shoulders', '${order.shouldersMeasurementInches}"'),
                  _MeasCell('Inseam', '${order.inseamMeasurementInches}"'),
                ],
              ),
            ),
            if (order.customerNotes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('CUSTOMER NOTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Text(order.customerNotes, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4))),
            ],
          ])),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoChip(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Icon(icon, size: 14, color: AppColors.primaryLight),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 8, color: AppColors.textMuted, letterSpacing: 0.5)),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF132238)), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}

class _MeasCell extends StatelessWidget {
  final String label; final String value;
  const _MeasCell(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF132238), fontFamily: 'monospace')),
    ]),
  );
}
