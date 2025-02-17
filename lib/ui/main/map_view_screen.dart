import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapViewScreen extends StatefulWidget {
  @override
  _MapViewScreenState createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  final Set<Marker> _markers = {};
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadPharmacyMarkers();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
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
    List<LatLng> pharmacyLocations = [
      LatLng(37.7749, -122.4192),
      LatLng(37.7755, -122.4184),
      LatLng(37.7760, -122.4201),
    ];

    for (var i = 0; i < pharmacyLocations.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('pharmacy_$i'),
          position: pharmacyLocations[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '약국 ${i + 1}',
            snippet: '마스크 재고 있음',
            onTap: () => _showPharmacyDetails('약국 ${i + 1}'),
          ),
        ),
      );
    }
  }

  void _showPharmacyDetails(String pharmacyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pharmacyName),
        content: const Text('이곳에서 마스크를 구매할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
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
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 14),
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        mapType: _isDarkMode ? MapType.hybrid : MapType.normal,
      ),
    );
  }
}