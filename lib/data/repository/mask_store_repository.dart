import 'package:mask_store/data/model/mask_store.dart';

abstract interface class MaskStoreRepository {
  Future<List<MaskStore>> getStoreInfo();
}