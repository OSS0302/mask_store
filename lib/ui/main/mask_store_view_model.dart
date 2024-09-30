import 'package:flutter/material.dart';
import 'package:mask_store/data/repository/my_location_repository.dart';
import 'package:mask_store/data/repository/mask_store_repository.dart';
import 'package:mask_store/ui/main/mask_store_state.dart';
import 'package:mask_store/data/model/mask_store.dart'; // MaskStore 모델 임포트

class MaskStoreViewModel extends ChangeNotifier {
  final MaskStoreRepository _maskStoreRepository;
  final MyLocationRepository _myLocationRepository;
  final ScrollController scrollController = ScrollController();

  bool _isDarkMode = false; // 다크 모드 기본 값 설정

  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode; // 다크 모드 상태 변경
    notifyListeners(); // UI 업데이트를 위한 알림
  }

  MaskStoreViewModel({
    required MaskStoreRepository maskStoreRepository,
    required MyLocationRepository myLocationRepository,
  })  : _maskStoreRepository = maskStoreRepository,
        _myLocationRepository = myLocationRepository {
    fetchStores(); // 초기 데이터 로드
  }

  MaskStoreState _state = MaskStoreState(
    isLoading: false,
    stores: List.unmodifiable([]),
  );

  MaskStoreState get state => _state;

  String _searchQuery = ''; // 검색어 상태 관리
  List<MaskStore> _allStores = []; // 모든 약국 데이터를 저장하는 리스트

  Future<void> refreshStores() async {
    await fetchStores();
  }



  Future<void> fetchStores() async {
    _state = state.copyWith(isLoading: true);
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

    stores.sort((store, my) => store.distance.compareTo(my.distance));
    _allStores = stores; // 모든 데이터를 저장
    _state = state.copyWith(
      isLoading: false,
      stores: _filterStores(_searchQuery), // 필터링된 리스트 적용
    );
    notifyListeners();
  }

  // 검색어로 리스트 필터링
  void filterStores(String query) {
    _searchQuery = query;
    _state = state.copyWith(stores: _filterStores(query));
    notifyListeners();
  }

  // 검색어에 따라 약국 리스트 필터링하는 함수
  List<MaskStore> _filterStores(String query) {
    if (query.isEmpty) {
      return _allStores; // 검색어가 없으면 모든 데이터를 반환
    }

    return _allStores.where((store) {
      return store.storeName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // 알림 설정 상태 가져오기
  bool get isNotificationsEnabled => _state.isNotificationsEnabled;

  // 알림 설정 토글 메소드 추가
  void toggleNotifications() {
    _state = _state.copyWith(
      isNotificationsEnabled: !_state.isNotificationsEnabled,
    );
    notifyListeners();
  }

  // 언어 변경 메소드 추가
  void changeLanguage(String newLanguage) {
    _state = _state.copyWith(currentLanguage: newLanguage);
    notifyListeners();
  }

  // 즐겨찾기 토글 메서드
  void toggleFavorite(MaskStore store) {
    store.toggleFavorite();
    notifyListeners(); // UI에 변경 사항 반영
  }
}


