import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:offline_first_aid_app/core/services/location_service.dart';
import 'package:offline_first_aid_app/core/services/connectivity_service.dart';
import 'package:offline_first_aid_app/core/services/map_download_service.dart';
import 'package:offline_first_aid_app/core/services/routing_service.dart';
import 'package:offline_first_aid_app/features/hospitals/presentation/bloc/hospital_bloc.dart';
import 'package:offline_first_aid_app/features/hospitals/presentation/bloc/hospital_event.dart';
import 'package:offline_first_aid_app/features/hospitals/presentation/bloc/hospital_state.dart';
import 'package:offline_first_aid_app/features/hospitals/data/models/hospital_model.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final MapDownloadService _mapDownloadService = MapDownloadService();
  final RoutingService _routingService = RoutingService();

  bool _isOffline = false;
  HospitalModel? _selectedHospital;
  List<LatLng> _currentRoute = [];
  String? _tilePath;

  @override
  void initState() {
    super.initState();
    context.read<HospitalBloc>().add(LoadHospitals());
    _checkConnectivity();
    _initLocation();
    _initTilePath();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await _connectivityService.isConnected();
    if (mounted) {
      setState(() {
        _isOffline = !isConnected;
      });
    }
  }

  Future<void> _initTilePath() async {
    final path = await _mapDownloadService.getTilePath();
    if (mounted) {
      setState(() {
        _tilePath = path;
      });
    }
  }

  Future<void> _initLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      final userLoc = LatLng(position.latitude, position.longitude);
      context.read<HospitalBloc>().add(UpdateUserLocation(userLoc));
      _mapController.move(userLoc, 13);
    } else if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ኢንተርኔት የለም። እባክዎ ካርታው ላይ በመጫን ያሉበትን ቦታ ይምረጡ'),
        ),
      );
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_isOffline) {
      context.read<HospitalBloc>().add(UpdateUserLocation(point));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('የእርስዎ ቦታ ተመርጧል')));
      // Recalculate route if hospital is selected
      if (_selectedHospital != null) {
        _calculateRoute(
          point,
          LatLng(_selectedHospital!.latitude, _selectedHospital!.longitude),
        );
      }
    }
  }

  Future<void> _calculateRoute(LatLng start, LatLng destination) async {
    final route = await _routingService.getOfflineRoute(start, destination);
    if (mounted) {
      setState(() {
        _currentRoute = route;
      });
    }
  }

  void _navigateToHospital(HospitalModel hospital) {
    setState(() {
      _selectedHospital = hospital;
    });

    final userLocation = context.read<HospitalBloc>().state.userLocation;
    if (userLocation != null) {
      _calculateRoute(
        userLocation,
        LatLng(hospital.latitude, hospital.longitude),
      );
    }

    Navigator.pop(context); // Close the bottom sheet

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('በካርታው ላይ መስመሩን ማየት ይችላሉ። (Offline Routing)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ቅርብ ሆስፒታሎች'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              context.read<HospitalBloc>().add(UpdateHospitalsFromRemote());
            },
            tooltip: 'የሆስፒታል መረጃ አድስ (Admin Sync)',
          ),
        ],
      ),
      body: BlocBuilder<HospitalBloc, HospitalState>(
        builder: (context, state) {
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      state.userLocation ??
                      const LatLng(9.0192, 38.7525), // Addis Ababa center
                  initialZoom: 13,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: (_isOffline && _tilePath != null)
                        ? '$_tilePath/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.offline_first_aid_app',
                    tileProvider: (_isOffline && !kIsWeb)
                        ? FileTileProvider()
                        : null,
                  ),
                  MarkerLayer(
                    markers: [
                      // User Location Marker
                      if (state.userLocation != null)
                        Marker(
                          point: state.userLocation!,
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      // Hospital Markers
                      ...state.hospitals.map(
                        (hospital) => Marker(
                          point: LatLng(hospital.latitude, hospital.longitude),
                          width: 80,
                          height: 80,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedHospital = hospital;
                              });
                              _showHospitalDetails(context, hospital);
                            },
                            child: const Icon(
                              Icons.local_hospital,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentRoute.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _currentRoute,
                          color: Colors.green,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                ],
              ),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (_isOffline)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.orange.withOpacity(0.8),
                    child: const Text(
                      'ከኢንተርኔት ውጭ ነዎት (Offline Mode). የወረደው ካርታ ጥቅም ላይ እየዋለ ነው።',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _initLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showHospitalDetails(BuildContext context, HospitalModel hospital) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hospital.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('አድራሻ: ${hospital.address}'),
              const SizedBox(height: 4),
              Text('ስልክ: ${hospital.phone}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _navigateToHospital(hospital),
                    icon: const Icon(Icons.navigation),
                    label: const Text('መንገድ አሳይ'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = 'tel:${hospital.phone.replaceAll(' ', '')}';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('ደውል'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
