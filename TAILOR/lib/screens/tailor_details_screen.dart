// screens/tailor_details_screen.dart - Full tailor profile overlay
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/tailor_model.dart';

class TailorDetailsScreen extends StatelessWidget {
  final TailorModel tailor;
  final void Function(String tailorId) onBookTailor;
  final void Function(TailorModel tailor)? onViewOnMap;

  const TailorDetailsScreen({
    super.key,
    required this.tailor,
    required this.onBookTailor,
    this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF132238)), onPressed: () => Navigator.pop(context)),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  Image.network(tailor.avatarImageUrl, fit: BoxFit.cover, color: Colors.black.withOpacity(0.45), colorBlendMode: BlendMode.darken),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.background]))),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(delegate: SliverChildListDelegate([
                // Name + rating
                Text(tailor.shopName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF132238))),
                const SizedBox(height: 8),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Row(children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text('${tailor.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                  ])),
                  const SizedBox(width: 8),
                  Text('${tailor.reviewsCount} reviews', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Text('${tailor.priceRange} price', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 16),

                // Location + hours
                Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF132238))),
                      const SizedBox(height: 2),
                      Text(tailor.location, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text(tailor.distanceFromCustomer, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryLight))),
                  ]),
                  Divider(color: AppColors.border, height: 20),
                  Row(children: [
                    Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Working Hours', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF132238))),
                      const SizedBox(height: 2),
                      Text(tailor.workingHours, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ])),
                  ]),
                ])),
                const SizedBox(height: 16),

                // Specialties
                const Text('SERVICES & SPECIALTIES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF3D4F63), letterSpacing: 1)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: tailor.specialties.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                  child: Text(s, style: TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.w500)),
                )).toList()),
                const SizedBox(height: 16),

                // About
                const Text('ABOUT SHOP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF3D4F63), letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Text(tailor.about, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5))),
                const SizedBox(height: 16),

                // Reviews
                Text('CUSTOMER REVIEWS (${tailor.reviews.length})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF3D4F63), letterSpacing: 1)),
                const SizedBox(height: 8),
                ...tailor.reviews.map((rev) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(rev.authorName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF132238))),
                      Row(children: List.generate(rev.starRating, (_) => const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)))),
                    ]),
                    const SizedBox(height: 6),
                    Text('"${rev.reviewText}"', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4, fontStyle: FontStyle.italic)),
                  ]),
                )),
              ])),
            ),
          ],
        ),
        // Bottom action bar
        Positioned(bottom: 0, left: 0, right: 0, child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(
            children: [
              // "View on Map" secondary button
              if (onViewOnMap != null) ...
                [
                  GestureDetector(
                    onTap: () => onViewOnMap!(tailor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 18, color: AppColors.primaryLight),
                          const SizedBox(width: 6),
                          Text('Map', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              // Main booking CTA
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onBookTailor(tailor.tailorId),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text('Create Request with ${tailor.shopName.split(' ').first}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ],
          ),
        )),
      ]),
    );
  }
}
