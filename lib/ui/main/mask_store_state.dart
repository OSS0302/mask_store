import '../../data/model/mask_store.dart';

class MaskStoreState {
  List<MaskStore> _stores = [];

  List<MaskStore> get stores => List.unmodifiable(_stores);

  bool isLoading = false;
  bool isNotificationsEnabled; // 알림 설정 추가
  String currentLanguage; // 현재 언어 설정 추가

  // 생성자
  MaskStoreState({
    required this.isLoading,
    required List<MaskStore> stores,
    this.isNotificationsEnabled = false, // 기본값
    this.currentLanguage = '한국어', // 기본 언어
  }) : _stores = stores;

  bool get _isLoading => isLoading;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is MaskStoreState &&
              runtimeType == other.runtimeType &&
              _stores == other._stores &&
              isLoading == other.isLoading &&
              isNotificationsEnabled == other.isNotificationsEnabled &&
              currentLanguage == other.currentLanguage);

  @override
  int get hashCode => _stores.hashCode ^ isLoading.hashCode ^ isNotificationsEnabled.hashCode ^ currentLanguage.hashCode;

  @override
  String toString() {
    return 'MaskStoreState{' +
        ' _stores: $_stores,' +
        ' isLoading: $isLoading,' +
        ' isNotificationsEnabled: $isNotificationsEnabled,' +
        ' currentLanguage: $currentLanguage,' +
        '}';
  }

  // copyWith 메소드 수정
  MaskStoreState copyWith({
    List<MaskStore>? stores,
    bool? isLoading,
    bool? isNotificationsEnabled,
    String? currentLanguage,
  }) {
    return MaskStoreState(
      stores: stores ?? this._stores,
      isLoading: isLoading ?? this.isLoading,
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      currentLanguage: currentLanguage ?? this.currentLanguage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_stores': this._stores,
      'isLoading': this.isLoading,
      'isNotificationsEnabled': this.isNotificationsEnabled,
      'currentLanguage': this.currentLanguage,
    };
  }

  factory MaskStoreState.fromMap(Map<String, dynamic> map) {
    return MaskStoreState(
      stores: map['_stores'] as List<MaskStore>,
      isLoading: map['isLoading'] as bool,
      isNotificationsEnabled: map['isNotificationsEnabled'] as bool,
      currentLanguage: map['currentLanguage'] as String,
    );
  }
}
