class MaskStore {
  final String storeName;
  final String address;
   double distance;
  final String remainStatus;
  final double latitude;
  final double longitude;
  bool isFavorite;

  MaskStore({
    required this.storeName,
    required this.address,
    required this.distance,
    required this.remainStatus,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
  });

  // 즐겨찾기 상태를 토글하는 메서드
  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

}