// widgets/tailor_card.dart
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/tailor_model.dart';

class TailorCard extends StatelessWidget {
  final TailorModel tailor;
  final VoidCallback onTap;
  final VoidCallback? onViewMap;
  const TailorCard({
    super.key,
    required this.tailor,
    required this.onTap,
    this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(tailor.avatarImageUrl, width: 56, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 56, height: 72, color: AppColors.background)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(tailor.shopName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF132238)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Row(children: [
                const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                const SizedBox(width: 2),
                Text('${tailor.rating}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B), fontFamily: 'monospace')),
              ]),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Expanded(child: Text(tailor.location, style: TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Wrap(spacing: 4, runSpacing: 4, children: [
                    ...tailor.specialties.take(2).map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)),
                      child: Text(s, style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                    )),
                    if (tailor.specialties.length > 2)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)), child: Text('+${tailor.specialties.length - 2}', style: TextStyle(fontSize: 8, color: AppColors.textMuted))),
                  ]),
                ),
                if (onViewMap != null) ...
                  [
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onViewMap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                        ),
                        child: Icon(Icons.location_on_rounded, size: 14, color: AppColors.primaryLight),
                      ),
                    ),
                  ],
              ],
            ),
          ])),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        ]),
      ),
    );
  }
}
