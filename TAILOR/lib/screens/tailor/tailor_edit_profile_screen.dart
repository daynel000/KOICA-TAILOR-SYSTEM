import 'package:flutter/material.dart';
import '../../theme/tailor_theme.dart';
import '../../services/tailor_api_service.dart';

class TailorEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentProfile;
  const TailorEditProfileScreen({super.key, required this.currentProfile});

  @override
  State<TailorEditProfileScreen> createState() => _TailorEditProfileScreenState();
}

class _TailorEditProfileScreenState extends State<TailorEditProfileScreen> {
  final TailorApiService _api = TailorApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _shopNameController;
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _yearsExpController;
  late TextEditingController _skillsController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    _shopNameController = TextEditingController(text: p['shop_name'] ?? '');
    _fullNameController = TextEditingController(text: p['full_name'] ?? '');
    _bioController = TextEditingController(text: p['bio'] ?? '');
    _phoneController = TextEditingController(text: p['phone_number'] ?? '');
    _addressController = TextEditingController(text: p['address'] ?? '');
    _yearsExpController = TextEditingController(text: (p['years_experience'] ?? 0).toString());

    List<String> skills = [];
    final rawSkills = p['skills'];
    if (rawSkills is List) {
      skills = rawSkills.map((s) => s.toString()).toList();
    }
    _skillsController = TextEditingController(text: skills.join(', '));
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _yearsExpController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final List<String> skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final data = {
        'shop_name': _shopNameController.text,
        'full_name': _fullNameController.text,
        'bio': _bioController.text,
        'phone_number': _phoneController.text,
        'address': _addressController.text,
        'years_experience': int.tryParse(_yearsExpController.text) ?? 0,
        'skills': skillsList,
      };

      await _api.updateProfile(data);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: TailorTheme.primaryGreen),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(
                  labelText: 'Shop Name',
                  hintText: 'Enter your tailor shop name',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Shop name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell clients about your work, style, etc.',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter shop phone number',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter shop physical address',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearsExpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  hintText: 'Enter number of years',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  if (int.tryParse(val) == null) return 'Must be a valid integer';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                  hintText: 'Suits, Alterations, Wedding Dress',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TailorTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Profile Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
