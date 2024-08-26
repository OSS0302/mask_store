import 'package:mask_store/data/model/mask_store.dart';
import 'package:mask_store/data/repository/mask_store_repository.dart';

class MockMaskStoreRepository implements MaskStoreRepository {
  final _storeList = [
    {
      "addr": "서울특별시 강북구 솔매로 38 (미아동)",
      "code": "11817488",
      "created_at": "2020/07/03 11:00:00",
      "lat": 37.6254369,
      "lng": 127.0164096,
      "name": "승약국",
      "remain_stat": "plenty",
      "stock_at": "2020/07/02 18:05:00",
      "type": "01"
    },
    {
      "addr": "서울특별시 강북구 삼양로 247 3층 (미아동)",
      "code": "12856941",
      "created_at": "2020/07/03 11:00:00",
      "lat": 37.6255182,
      "lng": 127.017747,
      "name": "대지약국",
      "remain_stat": "plenty",
      "stock_at": "2020/07/03 10:45:00",
      "type": "01"
    },
    {
      "addr": "서울특별시 강북구 삼양로 255 (미아동)",
      "code": "11819723",
      "created_at": "2020/07/03 11:00:00",
      "lat": 37.6261612,
      "lng": 127.0180494,
      "name": "청구약국",
      "remain_stat": "plenty",
      "stock_at": "2020/07/03 10:40:00",
      "type": "01"
    },
  ];

  @override
  Future<List<MaskStore>> getStoreInfo() async {
    return _storeList.map(
      (e) => MaskStore(
        storeName: e['name'] as String,
        address: e['addr'] as String ,
        distance: 0,
        remainStatus: e['remain_stat'] as String ,
        latitude: e['lat'] as double,
        longitude: e['lng'] as double,
      ),
    ).toList();
  }
}
