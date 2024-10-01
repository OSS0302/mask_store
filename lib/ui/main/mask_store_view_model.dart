import 'package:flutter/material.dart';
import 'package:mask_store/data/repository/my_location_repository.dart';
import 'package:mask_store/data/repository/mask_store_repository.dart';
import 'package:mask_store/ui/main/mask_store_state.dart';
import 'package:mask_store/data/model/mask_store.dart'; // MaskStore 모델 임포트

class MaskStoreViewModel extends ChangeNotifier {
  final MaskStoreRepository _maskStoreRepository;
  final MyLocationRepository _myLocationRepository;
  final ScrollController scrollController = ScrollController();

  // 다크 모드 상태
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // 알림 설정 상태
  bool _isNotificationsEnabled = false;
  bool get isNotificationsEnabled => _isNotificationsEnabled;

  // 언어 설정 상태
  String _currentLanguage = '한국어';
  String get currentLanguage => _currentLanguage;



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

  // 다크 모드 토글
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // 알림 설정 토글
  void toggleNotifications() {
    _isNotificationsEnabled = !_isNotificationsEnabled;
    notifyListeners();
  }

  // 언어 변경
  void changeLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  // 즐겨찾기 토글 메서드
  void toggleFavorite(MaskStore store) {
    store.toggleFavorite();
    notifyListeners(); // UI에 변경 사항 반영
  }
}


