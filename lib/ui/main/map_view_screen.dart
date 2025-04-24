import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  final Set<Marker> _markers = {};
  final List<Map<String, dynamic>> _pharmacies = [];
  final Completer<GoogleMapController> _controller = Completer();
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<Position>? _positionStream;
  MapType _currentMapType = MapType.normal;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initTTS();
    _getCurrentLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    _updateCurrentLocationMarker();
    _generatePharmacyMarkers();

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 14));
    _speak("현재 위치를 불러왔습니다.");
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateCurrentLocationMarker();
      });
    });
  }

  void _updateCurrentLocationMarker() {
    _markers.removeWhere((m) => m.markerId.value == 'current_location');
    _markers.add(
      Marker(
        markerId: MarkerId('current_location'),
        position: _currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: '내 위치'),
      ),
    );
  }

  void _generatePharmacyMarkers() {
    _pharmacies.clear();
    Random random = Random();
    for (int i = 0; i < 8; i++) {
      double latOffset = (random.nextDouble() - 0.5) / 500;
      double lngOffset = (random.nextDouble() - 0.5) / 500;
      LatLng location = LatLng(_currentPosition.latitude + latOffset, _currentPosition.longitude + lngOffset);

      final name = '약국 ${i + 1}';
      final stock = random.nextBool() ? '마스크 재고 있음' : '재고 부족';

      _pharmacies.add({
        'name': name,
        'location': location,
        'stock': stock,
      });

      _markers.add(
        Marker(
          markerId: MarkerId('pharmacy_$i'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: name,
            snippet: stock,
            onTap: () => _launchMaps(location),
          ),
        ),
      );
    }
  }

  Future<void> _launchMaps(LatLng destination) async {
    final url = "https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}";
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 약국'),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _toggleMapType,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 14),
            onMapCreated: (controller) {
              _mapController = controller;
              _controller.complete(controller);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _currentMapType,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: '약국 검색',
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _pharmacies
                    .where((p) => p['name'].contains(_searchQuery))
                    .map((pharmacy) => GestureDetector(
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(pharmacy['location'], 16),
                    );
                    _speak("${pharmacy['name']}은 ${pharmacy['stock']} 상태입니다.");
                  },
                  child: Card(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pharmacy['name'],
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            pharmacy['stock'],
                            style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
