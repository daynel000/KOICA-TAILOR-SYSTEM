import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/ai_scan_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  List<dynamic> _tailors = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _selectedTailor;

  // Fallback center: Metro Manila
  static const LatLng _fallbackCenter = LatLng(14.5995, 120.9842);
  LatLng _userLocation = _fallbackCenter;
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    _initLocationAndTailors();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndTailors() async {
    await _getUserLocation();
    await _loadTailors();
  }

  Future<void> _getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Services disabled – use fallback
        return;
      }

      // Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Permission denied – use fallback
        return;
      }

      // Get the current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _locationLoaded = true;
        });
      }
    } catch (_) {
      // Any error – silently fall back to Metro Manila
    }
  }

  Future<void> _loadTailors() async {
    try {
      final tailors = await _apiService.fetchNearbyTailors();
      if (mounted) {
        setState(() {
          _tailors = tailors;
          final others = tailors.where((t) => t['profile_id'] != 1).toList();
          _selectedTailor = others.isNotEmpty ? others[0] : null;
          _isLoading = false;
        });
        // Move map to user's actual location after data loads
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_userLocation, 13.5);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Place "Your Shop" at GPS location, spread partners nearby
  LatLng _getTailorLocation(int index, bool isMe) {
    if (isMe) return _userLocation;
    // Spread partner shops around user's real location
    final lat = _userLocation.latitude;
    final lng = _userLocation.longitude;
    final offsets = [
      LatLng(lat + 0.012, lng + 0.015),
      LatLng(lat - 0.011, lng - 0.013),
      LatLng(lat + 0.018, lng - 0.010),
      LatLng(lat - 0.015, lng + 0.018),
    ];
    return offsets[index % offsets.length];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Nearby Partner Tailors',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadTailors();
              },
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
          : _errorMessage != null
              ? _buildErrorView()
              : _buildMapView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 56),
            const SizedBox(height: 16),
            Text('Could not load tailors: $_errorMessage',
                style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
              onPressed: () {
                setState(() { _isLoading = true; _errorMessage = null; });
                _loadTailors();
              },
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    // Build markers list
    final markers = <Marker>[];
    int partnerIndex = 0;
    for (int i = 0; i < _tailors.length; i++) {
      final tailor = _tailors[i] as Map<String, dynamic>;
      final isMe = tailor['profile_id'] == 1;
      final isSelected = _selectedTailor != null &&
          _selectedTailor!['profile_id'] == tailor['profile_id'];
      final location = _getTailorLocation(isMe ? 0 : partnerIndex++, isMe);
      final shopName = tailor['shop_name'] ?? tailor['full_name'] ?? 'Tailor';
      final rating = (tailor['rating'] ?? 5.0).toStringAsFixed(1);

      markers.add(
        Marker(
          point: location,
          width: 160,
          height: 70,
          child: GestureDetector(
            onTap: () {
              if (!isMe) {
                setState(() => _selectedTailor = tailor);
                _mapController.move(location, 14.5);
              }
            },
            child: Column(
              children: [
                // Badge Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppTheme.primaryPurple
                        : isSelected
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMe
                          ? AppTheme.primaryPurple
                          : isSelected
                              ? Colors.white
                              : Colors.white30,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMe ? Icons.person_pin_circle : Icons.store,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isMe ? 'Your Shop' : shopName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (!isMe) ...[
                        const SizedBox(width: 5),
                        Text(
                          '★ $rating',
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 22),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // ─── Real OpenStreetMap ───────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation,
            initialZoom: 13.5,
            minZoom: 6,
            maxZoom: 18,
          ),
          children: [
            // OpenStreetMap tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tailorconnect.tailordash',
            ),
            // Tailor shop markers
            MarkerLayer(markers: markers),
          ],
        ),

        // ─── Partner Selector Chips at bottom ────────────────────
        Positioned(
          bottom: _selectedTailor != null ? 200 : 20,
          left: 16,
          right: 16,
          child: _buildTailorListChips(),
        ),

        // ─── Selected Tailor Card ─────────────────────────────────
        if (_selectedTailor != null)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildTailorCard(_selectedTailor!),
          ),

        // ─── "You are here" legend badge ─────────────────────────
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: AppTheme.primaryPurple, size: 10),
                const SizedBox(width: 5),
                const Text('Your Shop', style: TextStyle(color: Colors.white, fontSize: 11)),
                const SizedBox(width: 10),
                const Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
                const SizedBox(width: 5),
                const Text('Partner', style: TextStyle(color: Colors.white, fontSize: 11)),
                if (_locationLoaded) ...[  
                  const SizedBox(width: 10),
                  const Icon(Icons.my_location, color: Colors.cyanAccent, size: 10),
                  const SizedBox(width: 4),
                  const Text('GPS Active', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                ],
              ],
            ),
          ),
        ),

        // ─── My Location FAB ──────────────────────────────────────
        Positioned(
          top: 52,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'myLocationBtn',
            backgroundColor: Colors.white,
            tooltip: 'My Location',
            onPressed: () async {
              await _getUserLocation();
              _mapController.move(_userLocation, 14.5);
            },
            child: const Icon(Icons.my_location, color: AppTheme.primaryPurple),
          ),
        ),
      ],
    );
  }

  Widget _buildTailorListChips() {
    final others = _tailors.where((t) => t['profile_id'] != 1).toList();
    if (others.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: others.map((t) {
          final tailor = t as Map<String, dynamic>;
          final isSelected = _selectedTailor != null &&
              _selectedTailor!['profile_id'] == tailor['profile_id'];
          int idx = others.indexOf(t);
          final loc = _getTailorLocation(idx, false);
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTailor = tailor);
              _mapController.move(loc, 14.5);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white30,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.store,
                      color: isSelected ? Colors.white : AppTheme.primaryGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    tailor['shop_name'] ?? tailor['full_name'] ?? 'Tailor',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTailorCard(Map<String, dynamic> tailor) {
    final name = tailor['shop_name'] ?? tailor['full_name'] ?? 'Unknown Tailor';
    final rating = (tailor['rating'] ?? 0.0).toStringAsFixed(1);
    final address = tailor['address'] ?? '';

    List<String> skills = [];
    final rawSkills = tailor['skills'];
    if (rawSkills is List) {
      skills = rawSkills.map((s) => s.toString()).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store, color: AppTheme.primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text('$rating', style: const TextStyle(color: Colors.amber, fontSize: 13)),
                        if (address.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              address,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: skills.take(4).map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.4)),
                ),
                child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _openCollaborationModal(tailor),
              icon: const Icon(Icons.handshake, color: Colors.white, size: 18),
              label: const Text(
                'Request Collaboration',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCollaborationModal(Map<String, dynamic> tailor) {
    final name = tailor['shop_name'] ?? tailor['full_name'] ?? 'Tailor';
    Map<String, dynamic>? attachedMeasurements;
    final TextEditingController msgCtrl = TextEditingController(
      text: 'Hi $name, our shop is overloaded with orders right now. We would like to collaborate and offload a sizing request to your shop.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.handshake_outlined, color: AppTheme.primaryGreen, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Collaborate with $name',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Message:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('AI Sizing Data:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  if (attachedMeasurements != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 16),
                              SizedBox(width: 6),
                              Text('AI Measurements Attached!',
                                style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            attachedMeasurements!.entries.map((e) => '${e.key.toUpperCase()}: ${e.value}').join('  •  '),
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryPurple,
                          side: const BorderSide(color: AppTheme.primaryPurple),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => const AiScanDialog(),
                          );
                          if (result != null) {
                            setModalState(() { attachedMeasurements = result; });
                          }
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Run AI Scan to Attach Sizing'),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              attachedMeasurements != null
                                  ? 'Collaboration Request & AI Measurements sent to $name!'
                                  : 'Collaboration Request sent to $name!',
                            ),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      },
                      child: const Text('Send Collaboration Request',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
