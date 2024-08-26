import 'package:mask_store/data/data_source/mask_store_api.dart';
import 'package:mask_store/data/model/mask_store.dart';

import 'mask_store_repository.dart';

class MaskStoreRepositoryImpl implements MaskStoreRepository {
  final _api = MaskStoreApi();

  @override
  Future<List<MaskStore>> getStoreInfo() async{
    final api = await _api.getStores();

    return api;
  }
}

