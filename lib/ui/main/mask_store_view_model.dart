import 'package:flutter/material.dart';
import 'package:mask_store/data/repository/my_location_repository.dart';
import 'package:mask_store/data/repository/mask_store_repository.dart';
import 'package:mask_store/ui/main/mask_store_state.dart';
import 'package:mask_store/data/model/mask_store.dart'; // MaskStore 모델 임포트

class MaskStoreViewModel extends ChangeNotifier {
  final MaskStoreRepository _maskStoreRepository;
  final MyLocationRepository _myLocationRepository;
  final ScrollController scrollController = ScrollController();

  // ✅ 초기 화면 설정 상태
  String _initialScreen = '홈'; // 기본값 '홈'
  String get initialScreen => _initialScreen;

  void changeInitialScreen(String screen) {
    _initialScreen = screen;
    notifyListeners();
  }

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
  final List<String> _cartItems = [];
  List<String> get cartItems => List.unmodifiable(_cartItems);

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

  String _searchQuery = '';
  List<MaskStore> _allStores = [];

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
        _notifyPlentyStatus(newStore);
      }

      newStore.previousRemainStatus = existing.remainStatus;
    }

    _state = _state.copyWith(stores: newStores);
    notifyListeners();
  }

  void _notifyPlentyStatus(MaskStore store) {
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
    _allStores = stores;
    _state = state.copyWith(
      isLoading: false,
      stores: _filterStores(_searchQuery),
    );
    notifyListeners();
  }

  void filterStores(String query) {
    _searchQuery = query;
    _state = state.copyWith(stores: _filterStores(query));
    notifyListeners();
  }

  List<MaskStore> _filterStores(String query) {
    if (query.isEmpty) {
      return _allStores;
    }

    return _allStores.where((store) {
      return store.storeName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleNotifications() {
    _isNotificationsEnabled = !_isNotificationsEnabled;
    notifyListeners();
  }

  void changeLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  MaterialColor _currentThemeColor = Colors.blue;
  MaterialColor get currentThemeColor => _currentThemeColor;

  void changeThemeColor(MaterialColor color) {
    _currentThemeColor = color;
    notifyListeners();
  }

  void changeFontSize(double newSize) {
    _fontSize = newSize;
    notifyListeners();
  }

  void toggleFavorite(MaskStore store) {
    store.toggleFavorite();
    notifyListeners();
  }

  void clearFavorites() {
    for (var store in _allStores) {
      store.isFavorite = false;
    }
    _state = state.copyWith(stores: List.from(_allStores));
    notifyListeners();
  }

  void sortByDistance() {
    _state = state.copyWith(
      stores: List.from(_state.stores)..sort((a, b) => a.distance.compareTo(b.distance)),
    );
    notifyListeners();
  }

  void sortByStock() {
    _state = state.copyWith(
      stores: List.from(_state.stores)..sort((a, b) => b.remainStatus.compareTo(a.remainStatus)),
    );
    notifyListeners();
  }

  void addToCart(String item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeFromCart(String item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  MaskStore? _plentyAlertStore;
  MaskStore? get plentyAlertStore => _plentyAlertStore;

  void clearPlentyAlert() {
    _plentyAlertStore = null;
  }

  void toggleOpenNowOnly() {
    showOpenNowOnly = !showOpenNowOnly;
    _filterAndSortStores();
    notifyListeners();
  }
}
