import 'package:flutter/material.dart';
import 'package:mask_store/data/repository/my_location_repository.dart';
import 'package:mask_store/data/repository/mask_store_repository.dart';
import 'package:mask_store/ui/main/mask_store_state.dart';
import 'package:mask_store/data/model/mask_store.dart';

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

  // 상태 변수들
  String _initialScreen = '홈';
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = false;
  String _currentLanguage = '한국어';
  String _currentThemeColorName = 'blue';
  double _fontSize = 16.0;
  final List<String> _cartItems = [];
  final List<MaskStore> _recentlyViewedStores = [];
  final Map<String, String> _storeNotes = {};
  bool _showWelcomeMessage = true;

  // 필터/정렬 상태
  String _searchQuery = '';
  bool showOpenNowOnly = false;
  bool showFavoritesOnly = false;
  String _sortCriteria = 'distance'; // 'distance', 'stock', 'name'

  MaskStoreState _state =
      MaskStoreState(isLoading: false, stores: List.unmodifiable([]));
  List<MaskStore> _allStores = [];
  MaskStore? _plentyAlertStore;

  // Getters
  String get initialScreen => _initialScreen;

  bool get isDarkMode => _isDarkMode;

  bool get isNotificationsEnabled => _isNotificationsEnabled;

  String get currentLanguage => _currentLanguage;

  String get currentThemeColorName => _currentThemeColorName;

  double get fontSize => _fontSize;

  List<String> get cartItems => List.unmodifiable(_cartItems);

  List<MaskStore> get recentlyViewedStores =>
      List.unmodifiable(_recentlyViewedStores);

  Map<String, String> get storeNotes => _storeNotes;

  bool get showWelcomeMessage => _showWelcomeMessage;

  String get sortCriteria => _sortCriteria;

  MaskStoreState get state => _state;

  MaskStore? get plentyAlertStore => _plentyAlertStore;

  // ===== 설정 관련 =====
  void changeInitialScreen(String screen) {
    _initialScreen = screen;
    notifyListeners();
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

  void toggleShowWelcomeMessage() {
    _showWelcomeMessage = !_showWelcomeMessage;
    notifyListeners();
  }

  // ===== 약국 관련 =====
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

    stores.sort((a, b) => a.distance.compareTo(b.distance));
    _allStores = stores;
    _applyFilters();
  }

  void filterStores(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void toggleOpenNowOnly() {
    showOpenNowOnly = !showOpenNowOnly;
    _applyFilters();
  }

  void toggleFavoritesOnly() {
    showFavoritesOnly = !showFavoritesOnly;
    _applyFilters();
  }

  void toggleFavorite(MaskStore store) {
    store.toggleFavorite();
    notifyListeners();
  }

  void clearFavorites() {
    for (var store in _allStores) {
      store.isFavorite = false;
    }
    _applyFilters();
  }

  void sortBy(String criteria) {
    _sortCriteria = criteria;
    _applyFilters();
  }

  void _applyFilters() {
    List<MaskStore> result = List.from(_allStores);

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((s) =>
              s.storeName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (showOpenNowOnly) {
      final now = DateTime.now();
      result = result
          .where((s) =>
              s.openAt?.isBefore(now) == true &&
              s.closeAt?.isAfter(now) == true)
          .toList();
    }

    if (showFavoritesOnly) {
      result = result.where((s) => s.isFavorite).toList();
    }

    switch (_sortCriteria) {
      case 'name':
        result.sort((a, b) => a.storeName.compareTo(b.storeName));
        break;
      case 'stock':
        result.sort((a, b) => b.remainStatus.compareTo(a.remainStatus));
        break;
      case 'distance':
      default:
        result.sort((a, b) => a.distance.compareTo(b.distance));
        break;
    }

    _state = _state.copyWith(isLoading: false, stores: result);
    notifyListeners();
  }

  void viewStore(MaskStore store) {
    _recentlyViewedStores.remove(store);
    _recentlyViewedStores.insert(0, store);
    if (_recentlyViewedStores.length > 10) {
      _recentlyViewedStores.removeLast();
    }
    notifyListeners();
  }

  void addNoteToStore(String storeId, String note) {
    _storeNotes[storeId] = note;
    notifyListeners();
  }

  void removeNoteFromStore(String storeId) {
    _storeNotes.remove(storeId);
    notifyListeners();
  }

  // ===== 장바구니 =====
  void addToCart(String item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeFromCart(String item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  // ===== plenty 알림 =====
  void updateStores(List<MaskStore> newStores) {
    for (var newStore in newStores) {
      final existing = _state.stores.firstWhere(
        (s) => s.storeName == newStore.storeName,
        orElse: () => newStore,
      );

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

  void clearPlentyAlert() {
    _plentyAlertStore = null;
  }

  Future<void> refreshStores() async {
    await fetchStores();
  }

  void sortByDistance() {
    _state.stores.sort((a, b) {
      final aDist = a.distance.isNaN ? double.infinity : a.distance;
      final bDist = b.distance.isNaN ? double.infinity : b.distance;
      return aDist.compareTo(bDist);
    });
    notifyListeners();
  }

  void sortByStock() {
    const stockOrder = {
      'plenty': 0, // 100개 이상
      'some': 1, // 30~99개
      'few': 2, // 2~29개
      'empty': 3, // 1개 이하
      'break': 4, // 판매 중지
      '': 5, // 값 없음
    };

    _state.stores.sort((a, b) {
      final aOrder = stockOrder[a.remainStatus] ?? 5;
      final bOrder = stockOrder[b.remainStatus] ?? 5;
      return aOrder.compareTo(bOrder);
    });
    notifyListeners();
  }
}
