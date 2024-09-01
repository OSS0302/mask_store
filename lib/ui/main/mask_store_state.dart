import '../../data/model/mask_store.dart';

class MaskStoreState {
  List<MaskStore> _stores = [];

  List<MaskStore> get stores => List.unmodifiable(_stores);

  bool isLoading = false;

  bool get _isLoading => isLoading;

//<editor-fold desc="Data Methods">
  MaskStoreState({
    required this.isLoading,
    required List<MaskStore> stores,
  }) : _stores = stores;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaskStoreState &&
          runtimeType == other.runtimeType &&
          _stores == other._stores &&
          isLoading == other.isLoading);

  @override
  int get hashCode => _stores.hashCode ^ isLoading.hashCode;

  @override
  String toString() {
    return 'MaskStoreState{' +
        ' _stores: $_stores,' +
        ' isLoading: $isLoading,' +
        '}';
  }

  MaskStoreState copyWith({
    List<MaskStore>? stores,
    bool? isLoading,
  }) {
    return MaskStoreState(
      stores: stores ?? this._stores,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_stores': this._stores,
      'isLoading': this.isLoading,
    };
  }

  factory MaskStoreState.fromMap(Map<String, dynamic> map) {
    return MaskStoreState(
      stores: map['_stores'] as List<MaskStore>,
      isLoading: map['isLoading'] as bool,
    );
  }

}