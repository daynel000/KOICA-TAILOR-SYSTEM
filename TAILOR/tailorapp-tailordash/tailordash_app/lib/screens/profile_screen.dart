import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../session.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.fetchProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Open settings
            },
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryPurple));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load profile',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadProfile();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final p = _profile!;

    // Parse skills list (could be JSON list or already a List)
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Header
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppTheme.primaryPurple, width: 3),
                    color: AppTheme.cardBackground,
                  ),
                  child: const Icon(Icons.person,
                      size: 60, color: AppTheme.primaryPurple),
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
                          builder: (_) => EditProfileScreen(currentProfile: _profile!),
                        ),
                      );
                      if (result == true) {
                        _loadProfile();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          color: Colors.white, size: 20),
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
                fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (fullName.isNotEmpty)
            Text(
              fullName,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
          const SizedBox(height: 24),

          // Profile Stats from DB
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProfileStat('Clients', totalClients),
              _buildProfileStat('Rating', '$rating ★'),
              _buildProfileStat('Experience', '$yearsExp Yrs'),
            ],
          ),
          const SizedBox(height: 30),

          // Profile Details
          _buildProfileListTile(
              Icons.location_on, 'Location', address),
          _buildProfileListTile(
              Icons.phone, 'Phone Number', phone),
          if (skills.isNotEmpty)
            _buildProfileListTile(
                Icons.design_services, 'Skills', skills.join(', ')),

          const SizedBox(height: 20),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () async {
                await AppSession.clearSession();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Log Out', style: TextStyle(fontSize: 16)),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileListTile(
      IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryPurple),
      ),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle:
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
    );
  }
}
