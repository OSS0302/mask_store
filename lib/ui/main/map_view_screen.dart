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
  List<Map<String, dynamic>> _pharmacies = [];
  String _searchQuery = "";
  String _stockFilter = '전체'; // '전체', '재고 있음', '재고 부족'
  String _sortOption = '가까운 순'; // '가까운 순', '이름순'

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationUpdates();
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
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
    });
  }

  void _updateCurrentLocationMarker() {
    _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: '내 위치'),
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
      _generatePharmacyMarkers();
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 14));
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  void _generatePharmacyMarkers() {
    Random random = Random();
    _pharmacies.clear();
    _markers.removeWhere((marker) => marker.markerId.value.startsWith('pharmacy_'));

    for (int i = 0; i < 10; i++) {
      double latOffset = (random.nextDouble() - 0.5) / 500;
      double lngOffset = (random.nextDouble() - 0.5) / 500;
      LatLng pharmacyLocation = LatLng(_currentPosition.latitude + latOffset, _currentPosition.longitude + lngOffset);

      String stock = random.nextBool() ? '재고 있음' : '재고 부족';

      Map<String, dynamic> pharmacy = {
        'id': i,
        'name': '약국 ${i + 1}',
        'location': pharmacyLocation,
        'stock': stock,
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
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _sortPharmacies() {
    if (_sortOption == '가까운 순') {
      _pharmacies.sort((a, b) {
        double distanceA = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          a['location'].latitude,
          a['location'].longitude,
        );
        double distanceB = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          b['location'].latitude,
          b['location'].longitude,
        );
        return distanceA.compareTo(distanceB);
      });
    } else if (_sortOption == '이름순') {
      _pharmacies.sort((a, b) => a['name'].compareTo(b['name']));
    }
  }

  @override
  Widget build(BuildContext context) {
    _sortPharmacies();
    final filteredPharmacies = _pharmacies.where((p) {
      if (_stockFilter == '전체') return p['name'].contains(_searchQuery);
      return p['stock'] == _stockFilter && p['name'].contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 약국'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _toggleMapType,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '가까운 순', child: Text('가까운 순')),
              const PopupMenuItem(value: '이름순', child: Text('이름순')),
            ],
            icon: const Icon(Icons.sort),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
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
            top: 80,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: const Text('전체'),
                  selected: _stockFilter == '전체',
                  onSelected: (_) => setState(() => _stockFilter = '전체'),
                ),
                ChoiceChip(
                  label: const Text('재고 있음'),
                  selected: _stockFilter == '재고 있음',
                  onSelected: (_) => setState(() => _stockFilter = '재고 있음'),
                ),
                ChoiceChip(
                  label: const Text('재고 부족'),
                  selected: _stockFilter == '재고 부족',
                  onSelected: (_) => setState(() => _stockFilter = '재고 부족'),
                ),
              ],
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
                itemCount: filteredPharmacies.length,
                itemBuilder: (context, index) {
                  final pharmacy = filteredPharmacies[index];
                  final stockBadgeColor = pharmacy['stock'] == '재고 있음' ? Colors.green : Colors.red;
                  final stockBadgeText = pharmacy['stock'] == '재고 있음' ? '🟢 재고 있음' : '🔴 재고 부족';

                  return GestureDetector(
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
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy['name'],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: stockBadgeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                stockBadgeText,
                                style: TextStyle(color: stockBadgeColor, fontWeight: FontWeight.bold),
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
