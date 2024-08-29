import 'package:geolocator/geolocator.dart';
import 'package:mask_store/data/model/my_location.dart';

import 'my_location_repository.dart';

class MyLocationRepositoryImpl implements MyLocationRepository {
  @override
  double distanceBetween(
          double startLat, double startLng, double endLat, double endLng) =>
      Geolocator.distanceBetween(startLat, startLng, endLat, endLng).ceilToDouble();

  @override
  Future<MyLocation> getMyLocation() async {
    // 퍼미션 추가
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    // 권한 체크
    if (serviceEnabled) {
      var permission = await Geolocator.checkPermission();

      // 권한 거부시 권한 요청히고 기본값으로 위도 0 경도 0
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        return const MyLocation(latitude: 0, longitude: 0);
        // 연속적으로 권한 거부 시
      }else if(permission == LocationPermission.deniedForever) {
        return const MyLocation(latitude: 0, longitude: 0);
      }
    // 승인
    final position = await Geolocator.getCurrentPosition();
    return MyLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    }
    return const MyLocation(latitude: 0, longitude: 0);
  }
}
