import 'package:flutter/material.dart';
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
    super.dispose();
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateCurrentLocationMarker();
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );
    });
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

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  void _generatePharmacyMarkers() {
    Random random = Random();
    for (int i = 0; i < 5; i++) {
      double latOffset = (random.nextDouble() - 0.5) / 500;
      double lngOffset = (random.nextDouble() - 0.5) / 500;
      LatLng pharmacyLocation = LatLng(_currentPosition.latitude + latOffset, _currentPosition.longitude + lngOffset);

      Map<String, dynamic> pharmacy = {
        'name': '약국 ${i + 1}',
        'location': pharmacyLocation,
        'stock': random.nextBool() ? '마스크 재고 있음' : '재고 부족'
      };

      _pharmacies.add(pharmacy);
      _markers.add(
        Marker(
          markerId: MarkerId('pharmacy_$i'),
          position: pharmacyLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: pharmacy['name'],
            snippet: pharmacy['stock'],
            onTap: () => _launchMaps(pharmacyLocation),
          ),
        ),
      );
    }
  }

  void _launchMaps(LatLng destination) async {
    String url = "https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}";
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 약국'),
        backgroundColor: Colors.teal,
        actions: [
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
                          Text(pharmacy['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text(pharmacy['stock'], style: TextStyle(color: Colors.grey[600])),
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
