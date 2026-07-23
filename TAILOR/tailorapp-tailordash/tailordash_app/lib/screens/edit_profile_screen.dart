import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentProfile;

  const EditProfileScreen({Key? key, required this.currentProfile}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  late String _shopName;
  late String _bio;
  late String _address;
  late String _phone;
  late String _skillsStr;

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    _shopName = p['shop_name'] ?? '';
    _bio = p['bio'] ?? '';
    _address = p['address'] ?? '';
    _phone = p['phone_number'] ?? '';
    
    final rawSkills = p['skills'];
    if (rawSkills is List) {
      _skillsStr = rawSkills.join(', ');
    } else {
      _skillsStr = '';
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final skillsList = _skillsStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      
      await _apiService.updateProfile({
        'shop_name': _shopName,
        'bio': _bio,
        'address': _address,
        'phone_number': _phone,
        'skills': skillsList,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppTheme.primaryGreen),
        );
        Navigator.pop(context, true); // Return true to signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _shopName,
                decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _shopName = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _bio,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio / Description', border: OutlineInputBorder()),
                onSaved: (v) => _bio = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _address,
                decoration: const InputDecoration(labelText: 'Shop Address', border: OutlineInputBorder()),
                onSaved: (v) => _address = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                onSaved: (v) => _phone = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _skillsStr,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)', 
                  hintText: 'e.g., Suits, Barong, Dresses',
                  border: OutlineInputBorder()
                ),
                onSaved: (v) => _skillsStr = v ?? '',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
