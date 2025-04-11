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

  // 테마 색상 이름
  String _currentThemeColorName = 'blue';
  String get currentThemeColorName => _currentThemeColorName;

  // 폰트 크기 설정
  double _fontSize = 16.0;
  double get fontSize => _fontSize;

  // 장바구니
  final List<String> _cartItems = []; // 장바구니 아이템 목록

  List<String> get cartItems => List.unmodifiable(_cartItems);

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

  bool showOpenNowOnly = false;

  void _filterAndSortStores() {
    List<MaskStore> filteredStores = List.from(_allStores);

    if (_searchQuery.isNotEmpty) {
      filteredStores = filteredStores.where((store) {
        return store.storeName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (showOpenNowOnly) {
      final now = DateTime.now();
      filteredStores = filteredStores.where((store) {
        return store.openAt.isBefore(now) && store.closeAt.isAfter(now);
      }).toList();
    }

    _state = _state.copyWith(stores: filteredStores);
  }

  Future<void> refreshStores() async {
    await fetchStores();
  }

  void updateStores(List<MaskStore> newStores) {
    for (var newStore in newStores) {
      final existing = _state.stores.firstWhere(
              (s) => s.storeName == newStore.storeName,
          orElse: () => newStore);

      if (existing.isFavorite &&
          existing.remainStatus != 'plenty' &&
          newStore.remainStatus == 'plenty') {
        // 재고 상태가 plenty로 바뀐 즐겨찾기 약국 -> 알림!
        _notifyPlentyStatus(newStore);
      }

      newStore.previousRemainStatus = existing.remainStatus;
    }

    _state = _state.copyWith(stores: newStores);
    notifyListeners();
  }

  void _notifyPlentyStatus(MaskStore store) {
    // 여기에 콜백이나 상태 업데이트 후 Snackbar 표시하도록 설정
    _plentyAlertStore = store;
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

  // 테마 색상 변경
  MaterialColor _currentThemeColor = Colors.blue; // 기본 색상
  MaterialColor get currentThemeColor => _currentThemeColor;

// 테마 색상 변경 메서드
  void changeThemeColor(MaterialColor color) {
    _currentThemeColor = color;
    notifyListeners();
  }

  // 폰트 크기 변경
  void changeFontSize(double newSize) {
    _fontSize = newSize;
    notifyListeners();
  }

  // 즐겨찾기 토글 메서드
  void toggleFavorite(MaskStore store) {
    store.toggleFavorite();
    notifyListeners(); // UI에 변경 사항 반영
  }

  // 즐겨찾기 초기화
  void clearFavorites() {
    for (var store in _allStores) {
      store.isFavorite = false; // 모든 즐겨찾기 해제
    }
    _state = state.copyWith(stores: List.from(_allStores));
    notifyListeners(); // 상태 변경 알림
  }

  // 거리순 정렬
  void sortByDistance() {
    _state = state.copyWith(
      stores: List.from(_state.stores)..sort((a, b) => a.distance.compareTo(b.distance)),
    );
    notifyListeners();
  }

  // 재고순 정렬
  void sortByStock() {
    _state = state.copyWith(
      stores: List.from(_state.stores)..sort((a, b) => b.remainStatus.compareTo(a.remainStatus)),
    );
    notifyListeners();
  }

  // 장바구니
  void addToCart(String item) {
    _cartItems.add(item);
    notifyListeners(); // 상태 변경 알림
  }

  void removeFromCart(String item) {
    _cartItems.remove(item);
    notifyListeners(); // 상태 변경 알림
  }

  MaskStore? _plentyAlertStore;
  MaskStore? get plentyAlertStore => _plentyAlertStore;

  void clearPlentyAlert() {
    _plentyAlertStore = null;
  }

  void filterStores(String query) {
    _searchQuery = query;
    _filterAndSortStores();
    notifyListeners();
  }

  void toggleOpenNowOnly() {
    showOpenNowOnly = !showOpenNowOnly;
    _filterAndSortStores();
    notifyListeners();
  }



}
