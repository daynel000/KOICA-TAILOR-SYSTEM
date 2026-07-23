import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const CustomerDashboardScreen({super.key, required this.user});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _currentIndex = 0;

  static const brandNavy = Color(0xFF132238);
  static const brandGold = Color(0xFFD49228);
  static const bgColor   = Color(0xFFFAFAFC);
  static const hintColor = Color(0xFF9AA5B5);

  void _handleLogout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user['username'] ?? 'Customer';
    final fullName = widget.user['full_name'] ?? username;
    final email = widget.user['email'] ?? '$username@tailorconnect.com';

    final pages = [
      _buildHomeTab(fullName, username),
      _buildTailorsTab(),
      _buildOrdersTab(),
      _buildMeasurementsTab(),
      _buildProfileTab(username, fullName, email),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: brandNavy,
        unselectedItemColor: hintColor,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.content_cut_rounded), label: 'Tailors'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.straighten_rounded), label: 'Sizing'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  // ─── 1. HOME TAB ─────────────────────────────────────────────────────────────
  Widget _buildHomeTab(String fullName, String username) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back 👋', style: GoogleFonts.inter(fontSize: 13, color: hintColor)),
                  Text(fullName, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: brandNavy)),
                ],
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: brandNavy,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'C',
                      style: GoogleFonts.inter(color: brandGold, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                    tooltip: 'Log Out',
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search suit tailors, alterations...',
              hintStyle: GoogleFonts.inter(color: hintColor, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: hintColor),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDFE4EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: brandNavy),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [brandNavy, Color(0xFF1E3A8A)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: brandGold, borderRadius: BorderRadius.circular(6)),
                  child: Text('PROMO', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                Text('20% Off Custom Suits', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('Book your measurement fitting session today.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Active Order Progress
          Text('Active Order Progress', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: brandNavy)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDFE4EA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Two-Piece Navy Tuxedo', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: brandNavy)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(10)),
                      child: Text('IN SEWING', style: GoogleFonts.inter(color: const Color(0xFF1E40AF), fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(value: 0.75, color: brandGold, backgroundColor: Color(0xFFE2E8F0), minHeight: 8),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tailor: Royal Bespoke', style: GoogleFonts.inter(fontSize: 11, color: hintColor)),
                    Text('75% Done', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: brandNavy)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Featured Tailors Section
          Text('Featured Tailors', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: brandNavy)),
          const SizedBox(height: 12),

          const _TailorTile(name: 'Royal Bespoke Tailors', spec: 'Suits, Blazers & Tuxedos', rating: '★ 4.9 (128 reviews)', distance: '1.2 km'),
          const SizedBox(height: 10),
          const _TailorTile(name: 'Stitch & Cut Atelier', spec: 'Alterations & Custom Gowns', rating: '★ 4.8 (95 reviews)', distance: '2.4 km'),
        ],
      ),
    );
  }

  // ─── 2. TAILORS TAB ──────────────────────────────────────────────────────────
  Widget _buildTailorsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Tailor Shops Near You', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: brandNavy)),
        const SizedBox(height: 16),
        const _TailorTile(name: 'Executive Menswear', spec: 'Bespoke Italian Suits', rating: '★ 5.0', distance: '0.8 km'),
        const SizedBox(height: 12),
        const _TailorTile(name: 'Elegant Threads Studio', spec: 'Gowns & Designer Wear', rating: '★ 4.7', distance: '3.1 km'),
        const SizedBox(height: 12),
        const _TailorTile(name: 'Master Stitch Tailoring', spec: 'Quick Alterations', rating: '★ 4.6', distance: '1.5 km'),
      ],
    );
  }

  // ─── 3. ORDERS TAB ───────────────────────────────────────────────────────────
  Widget _buildOrdersTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('My Tailoring Orders', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: brandNavy)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDFE4EA))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #TC-8891', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: brandNavy)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(10)),
                    child: Text('IN SEWING', style: GoogleFonts.inter(color: const Color(0xFF1E40AF), fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Custom Navy Business Suit', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: brandNavy)),
              Text('Estimated Pickup: July 28, 2026', style: GoogleFonts.inter(fontSize: 12, color: hintColor)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 4. MEASUREMENTS TAB ─────────────────────────────────────────────────────
  Widget _buildMeasurementsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('My Body Measurements', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: brandNavy)),
        Text('Saved profiles for custom tailoring', style: GoogleFonts.inter(fontSize: 12, color: hintColor)),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: const [
            _MeasureTile(label: 'CHEST', val: '38.5 in'),
            _MeasureTile(label: 'WAIST', val: '32.0 in'),
            _MeasureTile(label: 'SHOULDER', val: '18.2 in'),
            _MeasureTile(label: 'SLEEVE', val: '25.0 in'),
            _MeasureTile(label: 'HIPS', val: '39.5 in'),
            _MeasureTile(label: 'INSEAM', val: '31.0 in'),
          ],
        ),
      ],
    );
  }

  // ─── 5. PROFILE TAB ──────────────────────────────────────────────────────────
  Widget _buildProfileTab(String username, String fullName, String email) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: brandNavy)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDFE4EA))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('USERNAME', style: GoogleFonts.inter(fontSize: 11, color: hintColor)),
                Text(username, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: brandNavy)),
                const Divider(height: 24),
                Text('EMAIL ADDRESS', style: GoogleFonts.inter(fontSize: 11, color: hintColor)),
                Text(email, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: brandNavy)),
                const Divider(height: 24),
                Text('ACCOUNT TYPE', style: GoogleFonts.inter(fontSize: 11, color: hintColor)),
                Text('Customer Account', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: brandGold)),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: Text('Log Out', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TailorTile extends StatelessWidget {
  final String name;
  final String spec;
  final String rating;
  final String distance;

  const _TailorTile({required this.name, required this.spec, required this.rating, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDFE4EA))),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('✂️', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF132238))),
                Text(spec, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9AA5B5))),
                const SizedBox(height: 4),
                Text('$rating • $distance', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFD97706))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEF3C7),
              foregroundColor: const Color(0xFFB45309),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Book', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _MeasureTile extends StatelessWidget {
  final String label;
  final String val;

  const _MeasureTile({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDFE4EA))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9AA5B5), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(val, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF132238))),
        ],
      ),
    );
  }
}
