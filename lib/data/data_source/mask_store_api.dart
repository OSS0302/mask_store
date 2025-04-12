import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mask_store/data/model/mask_store.dart';

class MaskStoreApi {
  Future<List<MaskStore>> getStores() async {
    final response = await http.get(Uri.parse('https://gist.githubusercontent.com/junsuk5/bb7485d5f70974deee920b8f0cd1e2f0/raw/063f64d9b343120c2cb01a6555cf9b38761b1d94/sample.json'));
    final List storeList =   jsonDecode(response.body)['stores'];
    return storeList.where((e)=> e['remain_stat'] != null)
        .map(
          (e) => MaskStore(
        storeName: e['name'] as String,
        address: e['addr'] as String ,
        distance: 0,
        remainStatus: e['remain_stat'] as String ,
        latitude: e['lat'] as double,
        longitude: e['lng'] as double, openAt: null, closeAt: null,
      ),
    ).toList();
  }
}
