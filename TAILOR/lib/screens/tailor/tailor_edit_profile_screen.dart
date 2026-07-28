import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
  bool _isUploadingImage = false;
  
  String? _storePictureUrl;
  double? _lat;
  double? _lng;
  List<String> _portfolioPhotos = [];
  final ImagePicker _picker = ImagePicker();

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

    _storePictureUrl = p['store_picture'];
    
    if (p['location_lat'] != null) {
      _lat = double.tryParse(p['location_lat'].toString());
    }
    if (p['location_lng'] != null) {
      _lng = double.tryParse(p['location_lng'].toString());
    }
    
    if (p['portfolio_photos'] is List) {
      _portfolioPhotos = (p['portfolio_photos'] as List).map((e) => e.toString()).toList();
    }

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
          
      // Auto-geocode the address into coordinates silently
      double? finalLat = _lat;
      double? finalLng = _lng;
      if (_addressController.text.isNotEmpty) {
        try {
          final query = Uri.encodeComponent(_addressController.text);
          final response = await http.get(
            Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1'),
            headers: {'User-Agent': 'TailorConnectApp/1.0'},
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body) as List;
            if (data.isNotEmpty) {
              finalLat = double.tryParse(data[0]['lat'].toString());
              finalLng = double.tryParse(data[0]['lon'].toString());
            }
          }
        } catch (_) {
          // Ignore geocoding errors, just save without new coordinates
        }
      }

      final data = {
        'shop_name': _shopNameController.text,
        'full_name': _fullNameController.text,
        'bio': _bioController.text,
        'phone_number': _phoneController.text,
        'address': _addressController.text,
        'years_experience': int.tryParse(_yearsExpController.text) ?? 0,
        'skills': skillsList,
        if (finalLat != null) 'location_lat': finalLat,
        if (finalLng != null) 'location_lng': finalLng,
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

  Future<void> _pickAndUploadStorePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    setState(() => _isUploadingImage = true);
    try {
      final bytes = await image.readAsBytes();
      final newUrl = await _api.uploadStorePicture(bytes, image.name);
      setState(() {
        _storePictureUrl = newUrl;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store picture updated!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickAndUploadPortfolioPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    setState(() => _isUploadingImage = true);
    try {
      final bytes = await image.readAsBytes();
      final newPhotos = await _api.uploadPortfolioPhoto(bytes, image.name);
      setState(() {
        _portfolioPhotos = newPhotos.map((e) => e.toString()).toList();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Portfolio photo added!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }
  
  Future<void> _deletePortfolioPhoto(String url) async {
    setState(() => _isUploadingImage = true);
    try {
      final newPhotos = await _api.deletePortfolioPhoto(url);
      setState(() {
        _portfolioPhotos = newPhotos.map((e) => e.toString()).toList();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
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
              // Store Picture Section
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _storePictureUrl != null && _storePictureUrl!.isNotEmpty
                          ? NetworkImage(_storePictureUrl!)
                          : null,
                      child: _storePictureUrl == null || _storePictureUrl!.isEmpty
                          ? const Icon(Icons.store, size: 50, color: Colors.grey)
                          : null,
                    ),
                    if (_isUploadingImage)
                      const Positioned.fill(child: CircularProgressIndicator())
                    else
                      CircleAvatar(
                        backgroundColor: TailorTheme.primaryGreen,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: _pickAndUploadStorePicture,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                  labelText: 'Physical Address',
                  hintText: 'e.g. 123 Main St, Manila, Philippines (will be mapped automatically)',
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
              
              // Portfolio Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Portfolio Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _isUploadingImage ? null : _pickAndUploadPortfolioPhoto,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Photo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_portfolioPhotos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('No portfolio photos yet. Add some to show off your work!')),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _portfolioPhotos.length,
                  itemBuilder: (context, index) {
                    final photoUrl = _portfolioPhotos[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(photoUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _deletePortfolioPhoto(photoUrl),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
