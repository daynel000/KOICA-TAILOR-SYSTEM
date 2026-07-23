// ============================================================
// screens/map_screen.dart
//
// Tab 2 - Map: Shows all nearby tailors on an OpenStreetMap.
//
// FEATURES:
//   - Live GPS location of the customer (blue dot)
//   - Custom pin markers for each tailor shop
//   - Tap a marker → bottom sheet preview with shop info
//   - "View on Map" from Home/Details auto-zooms to that tailor
//   - "My Location" button to re-center the map
//   - In-app routing via OSRM API (draws glowing route line)
//   - Driving / Walking mode toggles
//   - Route HUD overlay showing ETA, Distance, and External Map launch
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;

import '../main.dart';
import '../models/tailor_model.dart';
import '../providers/app_provider.dart';
import 'tailor_details_screen.dart';

class MapScreen extends StatefulWidget {
  final void Function(int tabIndex) onNavigateToTab;
  final void Function(String message) onShowToast;

  const MapScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onShowToast,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  bool _locationLoading = true;

  AppProvider? _provider;

  // Dumaguete City center as default fallback
  static const LatLng _defaultCenter = LatLng(9.3076, 123.3054);

  // ── Routing States ─────────────────────────────────────────
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;
  double? _routeDistanceKm;
  double? _routeDurationMin;
  TailorModel? _activeRoutingTailor;
  String _transportMode = 'foot'; // 'foot' (walking) or 'car' (driving)

  @override
  void initState() {
    super.initState();
    _loadUserLocation();

    // Listen for focusedMapTailor changes from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<AppProvider>();
      _provider!.addListener(_handleMapFocusChange);
      // Handle if a tailor was already focused before this screen mounted
      _handleMapFocusChange();
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_handleMapFocusChange);
    super.dispose();
  }

  // Called whenever provider notifies — checks if we need to zoom to a tailor
  void _handleMapFocusChange() {
    final focused = _provider?.focusedMapTailor;
    if (focused != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(LatLng(focused.latitude, focused.longitude), 16.5);
        _showTailorBottomSheet(focused);
        _provider?.clearMapFocus();
      });
    }
  }

  Future<void> _loadUserLocation() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationLoading = false);
        return;
      }

      // Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLoading = false);
        return;
      }

      // Get actual position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _locationLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  // ── OSRM API Routing ───────────────────────────────────────
  Future<void> _fetchRoute(TailorModel tailor) async {
    if (_userLocation == null) {
      widget.onShowToast("Unable to get current location for directions");
      return;
    }

    setState(() {
      _isFetchingRoute = true;
      _activeRoutingTailor = tailor;
    });

    // OSRM expects driving mode: 'car', walking mode: 'foot'
    final modePath = _transportMode == 'car' ? 'driving' : 'foot';
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$modePath/'
      '${_userLocation!.longitude},${_userLocation!.latitude};'
      '${tailor.longitude},${tailor.latitude}?overview=full&geometries=geojson'
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

          _fitRouteBounds(tailor);
        } else {
          _fallbackStraightLineRoute(tailor);
        }
      } else {
        _fallbackStraightLineRoute(tailor);
      }
    } catch (e) {
      _fallbackStraightLineRoute(tailor);
    } finally {
      setState(() {
        _isFetchingRoute = false;
      });
    }
  }

  void _fallbackStraightLineRoute(TailorModel tailor) {
    if (_userLocation == null) return;
    // Straight line route as fallback if API fails
    setState(() {
      _routePoints = [_userLocation!, LatLng(tailor.latitude, tailor.longitude)];
      _routeDistanceKm = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        tailor.latitude,
        tailor.longitude
      ) / 1000.0;
      _routeDurationMin = _transportMode == 'foot' 
          ? (_routeDistanceKm! * 12.0) // ~12 mins per km walking
          : (_routeDistanceKm! * 3.0);  // ~3 mins per km driving
    });
    _fitRouteBounds(tailor);
    widget.onShowToast("Using straight-line direction (offline fallback)");
  }

  void _fitRouteBounds(TailorModel tailor) {
    if (_userLocation == null) return;
    final double minLat = _userLocation!.latitude < tailor.latitude ? _userLocation!.latitude : tailor.latitude;
    final double maxLat = _userLocation!.latitude > tailor.latitude ? _userLocation!.latitude : tailor.latitude;
    final double minLng = _userLocation!.longitude < tailor.longitude ? _userLocation!.longitude : tailor.longitude;
    final double maxLng = _userLocation!.longitude > tailor.longitude ? _userLocation!.longitude : tailor.longitude;

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      tailor.latitude,
      tailor.longitude
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

  Future<void> _launchExternalMap(TailorModel tailor) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin='
      '${_userLocation?.latitude ?? ""},${_userLocation?.longitude ?? ""}'
      '&destination=${tailor.latitude},${tailor.longitude}&travelmode='
      '${_transportMode == "foot" ? "walking" : "driving"}'
    );
    
    final appleMapsUrl = Uri.parse(
      'http://maps.apple.com/?saddr='
      '${_userLocation?.latitude ?? ""},${_userLocation?.longitude ?? ""}'
      '&daddr=${tailor.latitude},${tailor.longitude}&dirflg='
      '${_transportMode == "foot" ? "w" : "d"}'
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        final genericUrl = Uri.parse(
          'geo:${tailor.latitude},${tailor.longitude}?q='
          '${Uri.encodeComponent(tailor.shopName)}'
        );
        if (await canLaunchUrl(genericUrl)) {
          await launchUrl(genericUrl, mode: LaunchMode.externalApplication);
        } else {
          widget.onShowToast("Could not launch external maps application");
        }
      }
    } catch (e) {
      widget.onShowToast("Error launching map app");
    }
  }

  void _showTailorBottomSheet(TailorModel tailor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TailorMapBottomSheet(
        tailor: tailor,
        onGetDirections: () {
          Navigator.pop(context);
          _fetchRoute(tailor);
        },
        onLaunchMaps: () {
          Navigator.pop(context);
          _launchExternalMap(tailor);
        },
        onViewDetails: () {
          Navigator.pop(context);
          context.read<AppProvider>().selectTailorForDetails(tailor);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TailorDetailsScreen(
                tailor: tailor,
                onBookTailor: (tailorId) {
                  Navigator.of(context).pop();
                  widget.onNavigateToTab(2); // Orders tab
                  widget.onShowToast(
                    'Opening request wizard. Tailor locked: ${tailor.shopName}',
                  );
                },
                onViewOnMap: null, // already on map
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tailors = context.watch<AppProvider>().tailorList;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── OpenStreetMap ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? _defaultCenter,
              initialZoom: 14.5,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              // OSM Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tailorconnect.app',
                maxZoom: 18,
              ),

              // Glowing Route Polyline Layer
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer glow
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.5,
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                    // Inner active line
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 3.5,
                      color: AppColors.primaryLight,
                    ),
                  ],
                ),

              // Tailor shop markers
              MarkerLayer(
                markers: tailors
                    .map(
                      (tailor) => Marker(
                        point: LatLng(tailor.latitude, tailor.longitude),
                        width: 52,
                        height: 64,
                        child: GestureDetector(
                          onTap: () => _showTailorBottomSheet(tailor),
                          child: _TailorMapPin(
                            tailor: tailor,
                            isRoutingDest: _activeRoutingTailor?.tailorId == tailor.tailorId,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              // User location blue dot
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 28,
                      height: 28,
                      child: const _UserLocationDot(),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top header overlay ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _buildHeader(tailors.length),
          ),

          // ── Active Navigation HUD overlay ──────────────────────
          if (_activeRoutingTailor != null)
            Positioned(
              bottom: 28,
              left: 16,
              right: 80, // Leave room for My Location button
              child: _buildRouteHUD(),
            ),

          // ── My Location FAB ────────────────────────────────────
          Positioned(
            bottom: 28,
            right: 16,
            child: _buildMyLocationButton(),
          ),

          // ── Fetching Loader ────────────────────────────────────
          if (_isFetchingRoute)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  color: AppColors.surface,
                  shape: CircleBorder(),
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryLight,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(int tailorCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.map_rounded,
              color: AppColors.primaryLight,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nearby Tailors',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF132238),
                  ),
                ),
                Text(
                  _locationLoading
                      ? 'Locating you...'
                      : _userLocation != null
                          ? 'Showing tailors near your location'
                          : 'Showing tailors in Dumaguete City',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              '$tailorCount found',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHUD() {
    final distText = _routeDistanceKm != null ? '${_routeDistanceKm!.toStringAsFixed(1)} km' : '-- km';
    final durationText = _routeDurationMin != null ? '${_routeDurationMin!.toStringAsFixed(0)} mins' : '-- mins';
    final tailorName = _activeRoutingTailor?.shopName ?? 'Tailor';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 16,
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
              Expanded(
                child: Text(
                  'Directions to $tailorName',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF132238)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _clearRoute,
                child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF5A6A7E)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    durationText,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.emerald),
                  ),
                  Text(
                    distText,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              // Transport toggle
              _buildTransportIcon('foot', Icons.directions_walk_rounded),
              const SizedBox(width: 6),
              _buildTransportIcon('car', Icons.directions_car_rounded),
              const SizedBox(width: 10),
              // External navigation trigger
              GestureDetector(
                onTap: () => _launchExternalMap(_activeRoutingTailor!),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.navigation_rounded, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransportIcon(String mode, IconData icon) {
    final active = _transportMode == mode;
    return GestureDetector(
      onTap: () {
        if (!active) {
          setState(() {
            _transportMode = mode;
          });
          if (_activeRoutingTailor != null) {
            _fetchRoute(_activeRoutingTailor!);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primary.withOpacity(0.4) : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? AppColors.primaryLight : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return GestureDetector(
      onTap: () {
        if (_userLocation != null) {
          _mapController.move(_userLocation!, 15.5);
        } else {
          setState(() => _locationLoading = true);
          _loadUserLocation();
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _locationLoading
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryLight,
                ),
              )
            : Icon(
                _userLocation != null
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                color: AppColors.primaryLight,
                size: 22,
              ),
      ),
    );
  }
}

// ── Tailor pin widget ──────────────────────────────────────────────
class _TailorMapPin extends StatelessWidget {
  final TailorModel tailor;
  final bool isRoutingDest;

  const _TailorMapPin({
    required this.tailor,
    this.isRoutingDest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular avatar with border
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRoutingDest ? AppColors.emerald : AppColors.primary,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: (isRoutingDest ? AppColors.emerald : AppColors.primary).withOpacity(0.55),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              tailor.avatarImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.store_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        // Triangle pointer
        CustomPaint(
          painter: _PinTrianglePainter(color: isRoutingDest ? AppColors.emerald : AppColors.primary),
          size: const Size(14, 9),
        ),
      ],
    );
  }
}

class _PinTrianglePainter extends CustomPainter {
  final Color color;
  _PinTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── User location blue pulsing dot ────────────────────────────────
class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.45),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet shown when a tailor marker is tapped ─────────────
class _TailorMapBottomSheet extends StatelessWidget {
  final TailorModel tailor;
  final VoidCallback onViewDetails;
  final VoidCallback onGetDirections;
  final VoidCallback onLaunchMaps;

  const _TailorMapBottomSheet({
    required this.tailor,
    required this.onViewDetails,
    required this.onGetDirections,
    required this.onLaunchMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Tailor header row
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(tailor.avatarImageUrl),
                backgroundColor: AppColors.background,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tailor.shopName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF132238),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${tailor.rating}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '(${tailor.reviewsCount} reviews)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            tailor.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Distance badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_walk_rounded,
                      size: 12,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tailor.distanceFromCustomer,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Working hours
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                tailor.workingHours,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tailor.priceRange,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Specialty tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tailor.specialties
                .take(3)
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 20),

          // Navigation & Action Buttons Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onGetDirections,
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text(
                    'Get Route',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLaunchMaps,
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: const Text(
                    'Open Maps',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Secondary full profile link
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onViewDetails,
              child: Text(
                'View Full Profile',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
