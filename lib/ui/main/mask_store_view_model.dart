import 'package:flutter/material.dart';
import 'package:mask_store/data/model/mask_store.dart';
import 'package:mask_store/data/repository/my_location_repository.dart';
import 'package:mask_store/data/repository/mask_store_repository.dart';
import 'package:mask_store/ui/main/mask_store_state.dart';

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



   MaskStoreState _state = MaskStoreState(
    isLoading: false,
    stores: List.unmodifiable([]),
  );

  MaskStoreState get state => _state;

  Future<void> refreshStores() async {
    await fetchStores();
  }

  Future<void> fetchStores() async {
   _state = state.copyWith(
     isLoading: true,
   );
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
    stores.sort((store, my) => store.distance.compareTo(my.distance));
    final _stores = stores;

    _state = state.copyWith(
      isLoading: false,
      stores: _stores,
    );
    notifyListeners();
  }
}
