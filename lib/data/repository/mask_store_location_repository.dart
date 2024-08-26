import 'package:mask_store/data/model/my_location.dart';

abstract interface class MyLocationRepository {
  Future<MyLocation> getMyLocation();

  double distanceBetween(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      );
}