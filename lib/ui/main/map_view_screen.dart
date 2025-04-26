import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final List<Map<String, dynamic>> _favoritePharmacies = [];
  String _searchQuery = "";
  bool _showOnlyFavorites = false;
  bool _showOnlyStockAvailable = false;
  FlutterTts _flutterTts = FlutterTts();
  int? _nearestPharmacyIndex;

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
        _highlightNearestPharmacy();
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
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
    _highlightNearestPharmacy();
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
    for (int i = 0; i < 8; i++) {
      double latOffset = (random.nextDouble() - 0.5) / 300;
      double lngOffset = (random.nextDouble() - 0.5) / 300;
      LatLng pharmacyLocation = LatLng(_currentPosition.latitude + latOffset, _currentPosition.longitude + lngOffset);

      Map<String, dynamic> pharmacy = {
        'id': 'pharmacy_$i',
        'name': '약국 ${i + 1}',
        'location': pharmacyLocation,
        'stock': random.nextBool() ? '마스크 재고 있음' : '재고 부족',
        'favorite': false,
      };

      _pharmacies.add(pharmacy);
    }
    _refreshMarkers();
  }

  void _refreshMarkers() {
    _markers.removeWhere((marker) => marker.markerId.value != 'current_location');

    for (var pharmacy in _pharmacies) {
      if (_showOnlyFavorites && pharmacy['favorite'] != true) continue;
      if (_showOnlyStockAvailable && pharmacy['stock'] != '마스크 재고 있음') continue;

      _markers.add(
        Marker(
          markerId: MarkerId(pharmacy['id']),
          position: pharmacy['location'],
          icon: BitmapDescriptor.defaultMarkerWithHue(
              pharmacy['favorite'] ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: pharmacy['name'],
            snippet: pharmacy['stock'],
            onTap: () => _launchMaps(pharmacy['location']),
          ),
        ),
      );
    }
    setState(() {});
  }

  void _toggleFavorite(Map<String, dynamic> pharmacy) {
    setState(() {
      pharmacy['favorite'] = !(pharmacy['favorite'] ?? false);
    });
    _refreshMarkers();
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  void _launchMaps(LatLng destination) async {
    String url = "https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}";
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _highlightNearestPharmacy() async {
    if (_pharmacies.isEmpty) return;
    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < _pharmacies.length; i++) {
      double distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _pharmacies[i]['location'].latitude,
        _pharmacies[i]['location'].longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    setState(() {
      _nearestPharmacyIndex = nearestIndex;
    });

    await _flutterTts.speak("${_pharmacies[nearestIndex]['name']}이 가장 가까운 약국입니다.");
  }
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayedPharmacies = _pharmacies
        .where((p) =>
    (!_showOnlyFavorites || p['favorite'] == true) &&
        (!_showOnlyStockAvailable || p['stock'] == '마스크 재고 있음') &&
        p['name'].contains(_searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 약국'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () {
              setState(() {
                _showOnlyStockAvailable = !_showOnlyStockAvailable;
              });
              _refreshMarkers();
            },
            tooltip: _showOnlyStockAvailable ? '모든 약국 보기' : '재고 있는 약국만 보기',
          ),
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
              _refreshMarkers();
            },
            tooltip: _showOnlyFavorites ? '모든 약국 보기' : '즐겨찾기만 보기',
          ),
          IconButton(
            icon: Icon(Icons.map),
            onPressed: _toggleMapType,
            tooltip: '지도 타입 변경',
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: displayedPharmacies.length,
                itemBuilder: (context, index) {
                  final pharmacy = displayedPharmacies[index];
                  return GestureDetector(
                    onTap: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(pharmacy['location'], 16),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: EdgeInsets.symmetric(horizontal: 8),
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    pharmacy['favorite'] ? Icons.star : Icons.star_border,
                                    color: pharmacy['favorite'] ? Colors.yellow[700] : Colors.grey,
                                  ),
                                  onPressed: () => _toggleFavorite(pharmacy),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Text(
                              pharmacy['stock'],
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Spacer(),
                            ElevatedButton(
                              onPressed: () => _launchMaps(pharmacy['location']),
                              child: Text('길찾기'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                minimumSize: Size(double.infinity, 36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
