import 'package:flutter/material.dart';
import '../../services/tailor_api_service.dart';
import '../../session/tailor_session.dart';
import 'tailor_edit_profile_screen.dart';
import '../login_screen.dart';

class TailorProfileScreen extends StatefulWidget {
  const TailorProfileScreen({super.key});

  @override
  State<TailorProfileScreen> createState() => _TailorProfileScreenState();
}

class _TailorProfileScreenState extends State<TailorProfileScreen> {
  final TailorApiService _api = TailorApiService();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  static const brandNavy = Color(0xFF132238);
  static const brandGold = Color(0xFFD49228);
  static const bgColor   = Color(0xFFFAFAFC);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _api.fetchProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _profile = {
          'profile_id': 1,
          'shop_name': TailorSession.currentShopName ?? 'Elite Tailoring Studio',
          'full_name': TailorSession.currentFullName ?? 'Master Tailor',
          'address': 'Metro Manila, Philippines',
          'phone_number': '+63 917 123 4567',
          'rating': 4.9,
          'total_clients': 142,
          'years_experience': 8,
          'bio': 'Specialized in bespoke suits, wedding gowns, and precision alterations.',
          'skills': ['Bespoke Suits', 'Gown Alterations', '3D AI Fitting'],
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
        title: const Text('My Profile', style: TextStyle(color: brandNavy, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: brandGold));
    }

    final p = _profile!;

    List<String> skills = [];
    final rawSkills = p['skills'];
    if (rawSkills is List) {
      skills = rawSkills.map((s) => s.toString()).toList();
    }

    final shopName = p['shop_name'] ?? 'Tailor Shop';
    final fullName = p['full_name'] ?? '';
    final address = p['address'] ?? 'Not specified';
    final phone = p['phone_number'] ?? 'Not specified';
    final rating = (p['rating'] ?? 0.0).toStringAsFixed(1);
    final totalClients = (p['total_clients'] ?? 0).toString();
    final yearsExp = (p['years_experience'] ?? 0).toString();
    final bio = p['bio'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: brandGold, width: 3),
                    color: brandNavy,
                  ),
                  child: const Icon(Icons.person,
                      size: 55, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      if (_profile == null) return;
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TailorEditProfileScreen(currentProfile: _profile!),
                        ),
                      );
                      if (result == true) {
                        _loadProfile();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: brandGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            shopName,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: brandNavy),
          ),
          if (fullName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              fullName,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileStat('Clients', totalClients),
                Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                _buildProfileStat('Rating', '$rating ★'),
                Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                _buildProfileStat('Experience', '$yearsExp Yrs'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
              ],
            ),
            child: Column(
              children: [
                _buildProfileListTile(Icons.location_on_outlined, 'Location', address),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildProfileListTile(Icons.phone_outlined, 'Phone Number', phone),
                if (skills.isNotEmpty) ...[
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _buildProfileListTile(Icons.design_services_outlined, 'Specializations', skills.join(' • ')),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await TailorSession.clearSession();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: brandNavy),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      ],
    );
  }

  Widget _buildProfileListTile(
      IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: brandNavy, size: 20),
      ),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandNavy)),
      subtitle:
          Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
    );
  }
}
