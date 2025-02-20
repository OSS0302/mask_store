import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';

class MapViewScreen extends StatefulWidget {
  @override
  _MapViewScreenState createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  final Set<Marker> _markers = {};
  final List<Map<String, dynamic>> _pharmacies = [];
  final Completer<GoogleMapController> _controller = Completer();
  final List<LatLng> _polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  bool _isDarkMode = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadPharmacyMarkers();
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
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 14),
      );
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: '내 위치'),
        ),
      );
    });
  }

  void _loadPharmacyMarkers() {
    List<Map<String, dynamic>> pharmacies = [
      {'name': '약국 1', 'location': LatLng(37.7749, -122.4192), 'stock': '마스크 재고 있음'},
      {'name': '약국 2', 'location': LatLng(37.7755, -122.4184), 'stock': '재고 부족'},
      {'name': '약국 3', 'location': LatLng(37.7760, -122.4201), 'stock': '마스크 충분'},
    ];
    setState(() {
      _pharmacies.addAll(pharmacies);
      for (var i = 0; i < pharmacies.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('pharmacy_$i'),
            position: pharmacies[i]['location'],
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: pharmacies[i]['name'],
              snippet: pharmacies[i]['stock'],
              onTap: () => _showPharmacyDetails(pharmacies[i]),
            ),
          ),
        );
      }
    });
  }

  Future<void> _createRoute(LatLng destination) async {
    _polylineCoordinates.clear();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'YOUR_GOOGLE_MAPS_API_KEY',
      PointLatLng(_currentPosition.latitude, _currentPosition.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
      setState(() {});
    }
  }

  void _showPharmacyDetails(Map<String, dynamic> pharmacy) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: 240,
        child: Column(
          children: [
            Text(pharmacy['name'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(pharmacy['stock']),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await _createRoute(pharmacy['location']);
                _navigateToPharmacy(pharmacy['location']);
              },
              icon: Icon(Icons.directions),
              label: Text('경로 안내'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPharmacy(LatLng destination) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(destination, 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 약국'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
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
            polylines: {
              Polyline(
                polylineId: PolylineId("route"),
                color: Colors.blue,
                width: 5,
                points: _polylineCoordinates,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _isDarkMode ? MapType.hybrid : MapType.normal,
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
                  onTap: () => _navigateToPharmacy(pharmacy['location']),
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
