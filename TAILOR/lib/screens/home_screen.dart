// ============================================================
// screens/home_screen.dart
// Tab 1 - Home: Shows welcome banner, stats, nearby tailors list/map
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/app_provider.dart';
import '../models/tailor_model.dart';
import '../widgets/tailor_card.dart';
import 'tailor_details_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tabIndex) onNavigateToTab;
  final void Function(String message) onShowToast;

  const HomeScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onShowToast,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final customer = provider.currentCustomer;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ---- Welcome Banner ----
                  _buildWelcomeBanner(
                    context,
                    customer?.fullName ?? 'Guest',
                    customer?.avatarImageUrl ?? '',
                  ),
                  const SizedBox(height: 20),

                  // ---- Quick Stats Row ----
                  _buildStatsRow(context, provider),
                  const SizedBox(height: 16),

                  // ---- AI Scan Promo Banner ----
                  _buildAIScanPromoBanner(context),
                  const SizedBox(height: 16),

                  // ---- Quick Actions ----
                  _buildQuickActions(context),
                  const SizedBox(height: 20),

                  // ---- Nearby Tailors Header ----
                  Text(
                    'NEARBY TAILORS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- Tailor List ----
                  ...provider.tailorList.map(
                    (tailor) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TailorCard(
                        tailor: tailor,
                        onTap: () => _openTailorDetails(context, tailor),
                        onViewMap: () {
                          context.read<AppProvider>().focusTailorOnMap(tailor);
                          onNavigateToTab(1); // Map tab
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Bottom nav clearance
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, String fullName, String avatarUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good day,',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            Row(
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF132238),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('👋', style: TextStyle(fontSize: 22)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: AppColors.surface,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
              tooltip: 'Log Out',
              onPressed: () async {
                await context.read<AppProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, AppProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Active Orders',
            value: '${provider.activeOrders.length}',
            subtitle: 'pending',
            accentColor: AppColors.indigo,
            onTap: () => onNavigateToTab(2), // Orders tab
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'My Scan Size',
            value: provider.savedScanResult?.recommendedSize ?? '--',
            subtitle: provider.savedScanResult != null ? 'calculated' : 'unscanned',
            accentColor: AppColors.emerald,
            onTap: () => onNavigateToTab(
              provider.savedScanResult != null ? 5 : 3, // Profile or AI Scan
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIScanPromoBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => onNavigateToTab(3), // AI Scan tab
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.6),
              AppColors.indigo.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '✨ ADVANCED AI INTEGRATION',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandNavy,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'AI Body Measurement Scan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan your silhouette to get accurate chest, waist & hip measurements.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: const Icon(
                Icons.straighten_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.add_rounded,
                label: 'New Request',
                subtitle: 'Order custom garment',
                iconColor: AppColors.primaryLight,
                iconBgColor: AppColors.primary.withOpacity(0.1),
                onTap: () => onNavigateToTab(2), // Orders tab
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat Room',
                subtitle: 'Message my tailors',
                iconColor: AppColors.indigo,
                iconBgColor: AppColors.indigo.withOpacity(0.1),
                onTap: () => onNavigateToTab(4), // Chat tab
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openTailorDetails(BuildContext context, TailorModel tailor) {
    context.read<AppProvider>().selectTailorForDetails(tailor);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TailorDetailsScreen(
          tailor: tailor,
          onBookTailor: (tailorId) {
            Navigator.of(context).pop();
            onNavigateToTab(2); // Orders tab
            onShowToast('Opening request wizard. Tailor locked: ${tailor.shopName}');
          },
          onViewOnMap: (t) {
            Navigator.of(context).pop();
            context.read<AppProvider>().focusTailorOnMap(t);
            onNavigateToTab(1); // Map tab
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor.withOpacity(0.1), AppColors.surface],
            begin: Alignment.topLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF132238),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF132238),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
