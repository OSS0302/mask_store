import 'package:flutter/material.dart';
import 'package:mask_store/data/model/mask_store.dart';
import 'package:mask_store/data/repository/my_location_repository.dart';
import 'package:mask_store/data/repository/mask_store_repository.dart';

class MaskStoreViewModel extends ChangeNotifier {
  final MaskStoreRepository _maskStoreRepository;
  final MyLocationRepository _myLocationRepository;
  final ScrollController scrollController = ScrollController();

  MaskStoreViewModel({
    required MaskStoreRepository maskStoreRepository,
    required MyLocationRepository myLocationRepository,
  })  : _maskStoreRepository = maskStoreRepository,
        _myLocationRepository = myLocationRepository {
    fetchStores();
  }

  // 변수 상태 관리
  List<MaskStore> _stores = [];

  List<MaskStore> get stores => List.unmodifiable(_stores);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> refreshStores() async {
    await fetchStores();
  }

  Future<void> fetchStores() async {
    _isLoading = true;
    notifyListeners();

    final stores = await _maskStoreRepository.getStoreInfo();
    final myLocation = await _myLocationRepository.getMyLocation();

    for (var store in stores) {
      store.distance = _myLocationRepository.distanceBetween(
        store.latitude,
        store.longitude,
        myLocation.latitude,
        myLocation.longitude,
      );
    }

    // 정렬
    stores.sort((store, my)=> store.distance.compareTo(my.distance));
    _stores = stores;

    _isLoading = false;
    notifyListeners();
  }
}
