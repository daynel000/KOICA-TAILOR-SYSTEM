// ============================================================
// screens/tailor/tailor_map_screen.dart
//
// Tailor Dashboard Map: Shows nearby partner tailors and clients
// on OpenStreetMap in the Philippines (Dumaguete City / Local GPS)
// with OSRM turn-by-turn routing, driving/walking modes, route HUD,
// user location blue dot, and collaboration features.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../theme/tailor_theme.dart';
import '../../services/tailor_api_service.dart';
import 'tailor_ai_scan_dialog.dart';

class TailorMapScreen extends StatefulWidget {
  const TailorMapScreen({super.key});

  @override
  State<TailorMapScreen> createState() => _TailorMapScreenState();
}

class _TailorMapScreenState extends State<TailorMapScreen> {
  final TailorApiService _apiService = TailorApiService();
  final MapController _mapController = MapController();

  List<dynamic> _tailors = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _selectedTailor;

  // Dumaguete City, Negros Oriental, Philippines as primary default center
  static const LatLng _fallbackCenter = LatLng(9.3076, 123.3054);
  LatLng? _userLocation;
  bool _locationLoaded = false;

  // ── OSRM Routing States ────────────────────────────────────
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;
  double? _routeDistanceKm;
  double? _routeDurationMin;
  Map<String, dynamic>? _activeRoutingTailor;
  String _transportMode = 'foot'; // 'foot' (walking) or 'car' (driving)

  static const brandNavy = Color(0xFF132238);
  static const brandGold = Color(0xFFD49228);
  static const bgColor   = Color(0xFFFAFAFC);

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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _userLocation = _fallbackCenter;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _userLocation = _fallbackCenter;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _locationLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userLocation = _fallbackCenter;
        });
      }
    }
  }

  Future<void> _loadTailors() async {
    try {
      final tailors = await _apiService.fetchNearbyTailors();
      if (mounted) {
        setState(() {
          _tailors = tailors.isNotEmpty ? tailors : _getFallbackTailors();
          final others = _tailors.where((t) => t['profile_id'] != 1).toList();
          _selectedTailor = others.isNotEmpty ? others[0] : null;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_userLocation != null) {
            _mapController.move(_userLocation!, 14.5);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tailors = _getFallbackTailors();
          final others = _tailors.where((t) => t['profile_id'] != 1).toList();
          _selectedTailor = others.isNotEmpty ? others[0] : null;
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFallbackTailors() {
    return [
      {
        'profile_id': 1,
        'full_name': 'Elite Tailoring Studio',
        'shop_name': 'Elite Tailoring (Your Shop)',
        'rating': 5.0,
        'address': 'Dumaguete City Center, Philippines',
        'skills': ['Suits', 'Alterations', 'Custom Gowns'],
      },
      {
        'profile_id': 2,
        'full_name': 'JDC Custom Tailors',
        'shop_name': 'JDC Tailoring & Embroidery',
        'rating': 4.9,
        'address': 'Hibbard Ave, Dumaguete City, Philippines',
        'skills': ['Barong Tagalog', 'Formal Wear', 'Embroidery'],
      },
      {
        'profile_id': 3,
        'full_name': 'Royal Stitches Studio',
        'shop_name': 'Royal Stitches Couture',
        'rating': 4.8,
        'address': 'Real Street, Dumaguete City, Philippines',
        'skills': ['Wedding Gowns', 'Pattern Making', 'Dresses'],
      },
      {
        'profile_id': 4,
        'full_name': 'Visayas Suit Masters',
        'shop_name': 'Visayas Custom Suits',
        'rating': 4.7,
        'address': 'Silliman Ave, Dumaguete City, Philippines',
        'skills': ['Tuxedos', 'Slacks Fitting', 'Uniforms'],
      },
    ];
  }

  LatLng _getTailorLocation(int index, bool isMe) {
    final base = _userLocation ?? _fallbackCenter;
    if (isMe) return base;
    final lat = base.latitude;
    final lng = base.longitude;
    final offsets = [
      LatLng(lat + 0.008, lng + 0.009),
      LatLng(lat - 0.007, lng - 0.008),
      LatLng(lat + 0.012, lng - 0.006),
      LatLng(lat - 0.009, lng + 0.011),
    ];
    return offsets[index % offsets.length];
  }

  // ── OSRM API Routing ───────────────────────────────────────
  Future<void> _fetchRoute(Map<String, dynamic> tailor, LatLng destLocation) async {
    final currentLoc = _userLocation ?? _fallbackCenter;

    setState(() {
      _isFetchingRoute = true;
      _activeRoutingTailor = tailor;
    });

    final modePath = _transportMode == 'car' ? 'driving' : 'foot';
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$modePath/'
      '${currentLoc.longitude},${currentLoc.latitude};'
      '${destLocation.longitude},${destLocation.latitude}?overview=full&geometries=geojson'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final List<LatLng> points = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          setState(() {
            _routePoints = points;
            _routeDistanceKm = (route['distance'] as num).toDouble() / 1000.0;
            _routeDurationMin = (route['duration'] as num).toDouble() / 60.0;
          });

          _fitRouteBounds(destLocation);
        } else {
          _fallbackStraightLineRoute(destLocation);
        }
      } else {
        _fallbackStraightLineRoute(destLocation);
      }
    } catch (_) {
      _fallbackStraightLineRoute(destLocation);
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRoute = false;
        });
      }
    }
  }

  void _fallbackStraightLineRoute(LatLng destLocation) {
    final currentLoc = _userLocation ?? _fallbackCenter;
    setState(() {
      _routePoints = [currentLoc, destLocation];
      _routeDistanceKm = Geolocator.distanceBetween(
        currentLoc.latitude,
        currentLoc.longitude,
        destLocation.latitude,
        destLocation.longitude,
      ) / 1000.0;
      _routeDurationMin = _transportMode == 'foot'
          ? (_routeDistanceKm! * 12.0)
          : (_routeDistanceKm! * 3.0);
    });
    _fitRouteBounds(destLocation);
  }

  void _fitRouteBounds(LatLng destLocation) {
    final currentLoc = _userLocation ?? _fallbackCenter;
    final double minLat = currentLoc.latitude < destLocation.latitude ? currentLoc.latitude : destLocation.latitude;
    final double maxLat = currentLoc.latitude > destLocation.latitude ? currentLoc.latitude : destLocation.latitude;
    final double minLng = currentLoc.longitude < destLocation.longitude ? currentLoc.longitude : destLocation.longitude;
    final double maxLng = currentLoc.longitude > destLocation.longitude ? currentLoc.longitude : destLocation.longitude;

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    final distance = Geolocator.distanceBetween(
      currentLoc.latitude,
      currentLoc.longitude,
      destLocation.latitude,
      destLocation.longitude,
    );

    double zoom = 14.5;
    if (distance > 10000) zoom = 11.5;
    else if (distance > 5000) zoom = 12.5;
    else if (distance > 2000) zoom = 13.5;
    else if (distance > 800) zoom = 14.5;
    else zoom = 15.5;

    _mapController.move(LatLng(centerLat, centerLng), zoom);
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _activeRoutingTailor = null;
      _routeDistanceKm = null;
      _routeDurationMin = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandGold))
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
            const Icon(Icons.wifi_off_rounded, color: Color(0xFF94A3B8), size: 56),
            const SizedBox(height: 16),
            Text('Could not load tailors: $_errorMessage',
                style: const TextStyle(color: Color(0xFF64748B)), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandGold),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isMe
                        ? brandNavy
                        : isSelected
                            ? brandGold
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMe
                          ? brandNavy
                          : isSelected
                              ? brandGold
                              : const Color(0xFFCBD5E1),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
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
                        color: (isMe || isSelected) ? Colors.white : brandNavy,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isMe ? 'Your Shop' : shopName,
                          style: TextStyle(
                            color: (isMe || isSelected) ? Colors.white : brandNavy,
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
                          style: TextStyle(
                              color: isSelected ? Colors.white : brandGold, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: isMe ? brandNavy : brandGold, size: 22),
              ],
            ),
          ),
        ),
      );
    }

    final currentCenter = _userLocation ?? _fallbackCenter;

    return Stack(
      children: [
        // ── OpenStreetMap ─────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentCenter,
            initialZoom: 14.5,
            minZoom: 6,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tailorconnect.tailordash',
            ),

            // Glowing OSRM Route Layer
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 6.5,
                    color: brandGold.withOpacity(0.4),
                  ),
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 3.5,
                    color: brandGold,
                  ),
                ],
              ),

            MarkerLayer(markers: markers),

            // User location glowing blue dot
            MarkerLayer(
              markers: [
                Marker(
                  point: currentCenter,
                  width: 28,
                  height: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Top Floating Header Overlay (Same as Customer Map) ───
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brandNavy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: brandNavy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nearby Partner Tailors',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: brandNavy,
                        ),
                      ),
                      Text(
                        _locationLoaded
                            ? 'Showing tailors near your location'
                            : 'Showing tailors in Dumaguete City, Philippines',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: brandNavy, size: 20),
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadTailors();
                  },
                ),
              ],
            ),
          ),
        ),

        // ── Partner Selector Chips ────────────────────────────────
        Positioned(
          bottom: _activeRoutingTailor != null
              ? 110
              : _selectedTailor != null
                  ? 200
                  : 20,
          left: 16,
          right: 16,
          child: _buildTailorListChips(),
        ),

        // ── Active Navigation HUD overlay ──────────────────────────
        if (_activeRoutingTailor != null)
          Positioned(
            bottom: 20,
            left: 16,
            right: 80,
            child: _buildRouteHUD(),
          ),

        // ── Selected Tailor Card ─────────────────────────────────
        if (_selectedTailor != null && _activeRoutingTailor == null)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildTailorCard(_selectedTailor!),
          ),

        // ── My Location FAB ──────────────────────────────────────
        Positioned(
          bottom: 28,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'myLocationBtn',
            backgroundColor: Colors.white,
            elevation: 4,
            tooltip: 'My Location',
            onPressed: () async {
              await _getUserLocation();
              _mapController.move(_userLocation ?? _fallbackCenter, 14.5);
            },
            child: const Icon(Icons.my_location, color: brandNavy),
          ),
        ),

        // ── Fetching Loader Overlay ──────────────────────────────
        if (_isFetchingRoute)
          Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(
              child: Card(
                color: Colors.white,
                shape: CircleBorder(),
                elevation: 6,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: brandGold,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRouteHUD() {
    final name = _activeRoutingTailor?['shop_name'] ?? _activeRoutingTailor?['full_name'] ?? 'Partner';
    final distStr = _routeDistanceKm != null ? '${_routeDistanceKm!.toStringAsFixed(1)} km' : '...';
    final durationStr = _routeDurationMin != null ? '${_routeDurationMin!.round()} min' : '...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: brandNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.navigation_rounded, color: brandGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Route to $name',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _clearRoute,
                child: const Icon(Icons.close, color: Colors.white70, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(distStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(width: 12),
              Text('•  $durationStr', style: const TextStyle(color: brandGold, fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),

              // Transport Mode Toggle Button (Walking vs Driving)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _transportMode = _transportMode == 'foot' ? 'car' : 'foot';
                  });
                  if (_activeRoutingTailor != null) {
                    final idx = _tailors.indexOf(_activeRoutingTailor);
                    final loc = _getTailorLocation(idx, false);
                    _fetchRoute(_activeRoutingTailor!, loc);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _transportMode == 'foot' ? Icons.directions_walk : Icons.directions_car,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _transportMode == 'foot' ? 'Walk' : 'Drive',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                color: isSelected ? brandNavy : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? brandNavy : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.store,
                      color: isSelected ? Colors.white : brandNavy, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    tailor['shop_name'] ?? tailor['full_name'] ?? 'Tailor',
                    style: TextStyle(
                        color: isSelected ? Colors.white : brandNavy, fontWeight: FontWeight.bold, fontSize: 13),
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
    int idx = _tailors.indexOf(tailor);
    final destLoc = _getTailorLocation(idx, false);

    List<String> skills = [];
    final rawSkills = tailor['skills'];
    if (rawSkills is List) {
      skills = rawSkills.map((s) => s.toString()).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
                  color: brandNavy.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store, color: brandNavy, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold, color: brandNavy)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: brandGold, size: 14),
                        const SizedBox(width: 4),
                        Text('$rating', style: const TextStyle(color: brandGold, fontSize: 13, fontWeight: FontWeight.bold)),
                        if (address.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              address,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(s, style: const TextStyle(color: brandNavy, fontSize: 11, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              // Get Directions Action
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandNavy,
                    side: const BorderSide(color: brandNavy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _fetchRoute(tailor, destLoc),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              // Request Collaboration Action
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _openCollaborationModal(tailor),
                  icon: const Icon(Icons.handshake, color: Colors.white, size: 18),
                  label: const Text(
                    'Collaborate',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
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
                color: Colors.white,
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
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.handshake_outlined, color: brandNavy, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Collaborate with $name',
                          style: const TextStyle(color: brandNavy, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Message:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: brandNavy, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('AI Sizing Data:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (attachedMeasurements != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF0F9D6C), size: 16),
                              SizedBox(width: 6),
                              Text('AI Measurements Attached!',
                                style: TextStyle(color: Color(0xFF0F9D6C), fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            attachedMeasurements!.entries.map((e) => '${e.key.toUpperCase()}: ${e.value}').join('  •  '),
                            style: const TextStyle(color: brandNavy, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brandNavy,
                          side: const BorderSide(color: brandNavy),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => const TailorAiScanDialog(),
                          );
                          if (result != null) {
                            setModalState(() { attachedMeasurements = result; });
                          }
                        },
                        icon: const Icon(Icons.auto_awesome, color: brandGold),
                        label: const Text('Run AI Scan to Attach Sizing', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGold,
                        elevation: 0,
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
                            backgroundColor: brandNavy,
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
