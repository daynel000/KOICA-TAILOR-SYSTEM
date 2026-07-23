import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final void Function(int) onNavigateToTab;
  const ProfileScreen({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final customer = provider.currentCustomer;
    final scan = provider.savedScanResult;

    // ── Guest / loading state ──────────────────────────────────
    if (customer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('Not logged in', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Log in to view your profile', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(children: [
          // Avatar + name
          Column(children: [
            Stack(children: [
              CircleAvatar(radius: 48, backgroundImage: NetworkImage(customer.avatarImageUrl), backgroundColor: AppColors.surface),
              Positioned(bottom: 0, right: 0, child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2)),
                child: const Text('⭐', style: TextStyle(fontSize: 10)),
              )),
            ]),
            const SizedBox(height: 12),
            Text(customer.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF132238))),
            const SizedBox(height: 4),
            Text('${customer.isPremium ? 'Premium' : 'Standard'} Client • ${customer.cityLocation}', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),

          // Stats row
          Row(children: [
            _StatBox('${provider.orderList.length}', 'Orders'),
            const SizedBox(width: 8),
            _StatBox('5.0', 'Rating', valueColor: AppColors.emerald),
            const SizedBox(width: 8),
            _StatBox(scan?.recommendedSize ?? '--', 'Scan Size', valueColor: AppColors.primaryLight),
          ]),
          const SizedBox(height: 16),

          // AI Measurements card
          _SectionCard(
            title: 'AI Body Dimensions',
            trailing: TextButton(
              onPressed: () => onNavigateToTab(3),
              child: Text(scan != null ? 'Recalibrate' : 'Scan Now', style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            child: scan != null
              ? Column(children: [
                  GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.2,
                    children: [
                      _MeasTile('Chest', '${scan.chestInches}"'),
                      _MeasTile('Waist', '${scan.waistInches}"'),
                      _MeasTile('Hips', '${scan.hipsInches}"'),
                      _MeasTile('Shoulders', '${scan.shouldersInches}"'),
                      _MeasTile('Inseam', '${scan.inseamInches.toStringAsFixed(1)}"'),
                      _MeasTile('Size', scan.recommendedSize, valueColor: AppColors.primaryLight),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Confidence: ${scan.confidencePercent} — Scanned on ${scan.scannedAt}', style: TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
                ])
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(children: [
                    Text('No body scan saved yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    GestureDetector(onTap: () => onNavigateToTab(3), child: Text('Start Body Calibration', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w700))),
                  ]),
                ),
          ),
          const SizedBox(height: 12),

          // Contact info
          _SectionCard(
            title: 'Contact Specifications',
            child: Column(children: [
              _InfoRow(Icons.location_on_outlined, customer.cityLocation),
              const Divider(color: Color(0xFF1E293B), height: 20),
              _InfoRow(Icons.phone_outlined, customer.phoneNumber),
              const Divider(color: Color(0xFF1E293B), height: 20),
              _InfoRow(Icons.email_outlined, customer.emailAddress),
            ]),
          ),
          const SizedBox(height: 12),

          // App settings
          _SectionCard(
            title: 'App Options',
            child: Column(children: [
              for (final item in [
                (Icons.settings_outlined, 'Account Settings'),
                (Icons.shield_outlined, 'Measurement Privacy Mode'),
                (Icons.help_outline_rounded, 'Tailor Support Center'),
              ]) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(item.$1, color: AppColors.primaryLight, size: 20),
                  title: Text(item.$2, style: const TextStyle(fontSize: 13, color: Color(0xFF132238))),
                  trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                  onTap: () {},
                ),
                if (item.$2 != 'Tailor Support Center') Divider(color: AppColors.border, height: 1),
              ],
            ]),
          ),
          const SizedBox(height: 12),

          // Logout
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface, title: const Text('Log Out', style: TextStyle(color: Colors.white)),
              content: Text('Are you sure?', style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await context.read<AppProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  child: Text('Log Out', style: TextStyle(color: AppColors.red)),
                ),
              ],
            )),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Log Out'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.3)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
        ]),
      )),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value; final String label; final Color? valueColor;
  const _StatBox(this.value, this.label, {this.valueColor});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor ?? Colors.white)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5)),
    ]),
  ));
}

class _SectionCard extends StatelessWidget {
  final String title; final Widget child; final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
        if (trailing != null) trailing!,
      ]),
      const SizedBox(height: 12),
      child,
    ]),
  );
}

class _MeasTile extends StatelessWidget {
  final String label; final String value; final Color? valueColor;
  const _MeasTile(this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: TextStyle(fontSize: 8, color: AppColors.textMuted, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: valueColor ?? Colors.white)),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: AppColors.textMuted),
    const SizedBox(width: 12),
    Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
  ]);
}
