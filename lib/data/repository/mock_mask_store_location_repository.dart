import 'package:mask_store/data/model/my_location.dart';
import 'package:mask_store/data/repository/mask_store_location_repository.dart';

class MockMaskStoreLocationRepository implements MyLocationRepository {
  @override
  double distanceBetween(double startLat, double startLng, double endLat, double endLng) {
    return 0;
  }

  @override
  Future<MyLocation> getMyLocation() async{
    return const MyLocation(latitude: 0, longitude: 0);
  }

}