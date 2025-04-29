// dependencies 추가 필요
// pubspec.yaml
// flutter_tts: ^3.6.3

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // TTS 추가
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  final Set<Marker> _markers = {};
  final Completer<GoogleMapController> _controller = Completer();
  MapType _currentMapType = MapType.normal;
  StreamSubscription<Position>? _positionStream;
  final List<Map<String, dynamic>> _pharmacies = [];
  String _searchQuery = "";
  bool _showFavoritesOnly = false;
  final Set<String> _favoritePharmacies = {};
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasAnnounced = false; // 중복 안내 방지

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationUpdates();
    _generatePharmacyMarkers();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateCurrentLocationMarker();
        _checkNearestPharmacyForTTS();
      });
    });
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
      _updateCurrentLocationMarker();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 14),
    );
  }

  void _updateCurrentLocationMarker() {
    _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
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
    Random random = Random();
    for (int i = 0; i < 10; i++) {
      double latOffset = (random.nextDouble() - 0.5) / 500;
      double lngOffset = (random.nextDouble() - 0.5) / 500;
      LatLng pharmacyLocation = LatLng(_currentPosition.latitude + latOffset, _currentPosition.longitude + lngOffset);

      bool hasStock = random.nextBool();
      Map<String, dynamic> pharmacy = {
        'id': 'pharmacy_$i',
        'name': '약국 ${i + 1}',
        'location': pharmacyLocation,
        'stock': hasStock ? '마스크 재고 있음' : '재고 부족',
      };

      _pharmacies.add(pharmacy);

      _addMarker(pharmacy);
    }
  }

  void _addMarker(Map<String, dynamic> pharmacy) {
    _markers.add(
      Marker(
        markerId: MarkerId(pharmacy['id']),
        position: pharmacy['location'],
        icon: BitmapDescriptor.defaultMarkerWithHue(
          pharmacy['stock'] == '마스크 재고 있음' ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: pharmacy['name'],
          snippet: pharmacy['stock'],
          onTap: () => _showPharmacyDetails(pharmacy),
        ),
      ),
    );
  }

  void _showPharmacyDetails(Map<String, dynamic> pharmacy) {
    double distance = _calculateDistance(_currentPosition, pharmacy['location']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pharmacy['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('재고 상태: ${pharmacy['stock']}'),
            SizedBox(height: 8),
            Text('거리: ${_formatDistance(distance)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _launchNaverMaps(pharmacy['location']),
            child: Text('네이버지도 열기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchNaverMaps(LatLng destination) async {
    final url = 'nmap://route/walk?dlat=${destination.latitude}&dlng=${destination.longitude}&appname=com.example.maskstore';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // fallback: 브라우저로 열기
      final webUrl = 'https://map.naver.com/v5/directions/-/-/${destination.longitude},${destination.latitude},PLACE';
      if (await canLaunch(webUrl)) {
        await launch(webUrl);
      }
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude);
  }

  String _formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return "${distanceMeters.toStringAsFixed(0)}m";
    } else {
      return "${(distanceMeters / 1000).toStringAsFixed(1)}km";
    }
  }

  void _toggleFavorite(String pharmacyId) {
    setState(() {
      if (_favoritePharmacies.contains(pharmacyId)) {
        _favoritePharmacies.remove(pharmacyId);
      } else {
        _favoritePharmacies.add(pharmacyId);
      }
    });
  }

  void _checkNearestPharmacyForTTS() async {
    if (_hasAnnounced) return;

    _pharmacies.sort((a, b) {
      double distanceA = _calculateDistance(_currentPosition, a['location']);
      double distanceB = _calculateDistance(_currentPosition, b['location']);
      return distanceA.compareTo(distanceB);
    });

    if (_pharmacies.isNotEmpty) {
      double nearestDistance = _calculateDistance(_currentPosition, _pharmacies.first['location']);
      if (nearestDistance < 200) {
        await _flutterTts.speak('${_pharmacies.first['name']}, ${_pharmacies.first['stock']}');
        _hasAnnounced = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredPharmacies = _pharmacies
        .where((p) =>
    p['name'].contains(_searchQuery) &&
        (!_showFavoritesOnly || _favoritePharmacies.contains(p['id'])))
        .toList();

    filteredPharmacies.sort((a, b) {
      double distanceA = _calculateDistance(_currentPosition, a['location']);
      double distanceB = _calculateDistance(_currentPosition, b['location']);
      return distanceA.compareTo(distanceB);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 약국'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.star),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: Icon(Icons.map),
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
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '약국 검색',
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),
                  onChanged: (query) {
                    setState(() => _searchQuery = query);
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
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: filteredPharmacies.map((pharmacy) {
                  double distance = _calculateDistance(_currentPosition, pharmacy['location']);
                  return GestureDetector(
                    onTap: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(pharmacy['location'], 16),
                      );
                      _showPharmacyDetails(pharmacy);
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Container(
                        width: 220,
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    pharmacy['name'],
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _favoritePharmacies.contains(pharmacy['id']) ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                  ),
                                  onPressed: () => _toggleFavorite(pharmacy['id']),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Text(pharmacy['stock'], style: TextStyle(color: Colors.grey[600])),
                            SizedBox(height: 5),
                            Text('거리: ${_formatDistance(distance)}', style: TextStyle(color: Colors.blueAccent)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
