import 'package:mask_store/data/model/mask_store_location.dart';

abstract interface class MaskStoreLocationRepository {
  Future<MaskStoreLocation> getMaskStoreLocation();
}