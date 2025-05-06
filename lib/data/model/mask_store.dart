class MaskStore {
  final String storeName;
  final String address;
   double distance;
  final String remainStatus;
  final double latitude;
  final double longitude;
  bool isFavorite;
  String previousRemainStatus;
  DateTime? openAt;
  DateTime? closeAt;

  MaskStore({
    required this.storeName,
    required this.address,
    required this.distance,
    required this.remainStatus,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
    this.previousRemainStatus = '',
    required this.openAt,
    required this.closeAt,
  });

  // 예: JSON에서 받아올 때
  factory MaskStore.fromJson(Map<String, dynamic> json) {
    return MaskStore(
      storeName: json['storeName'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      distance: 0.0, // 초기값
      remainStatus: json['remainStatus'],
      openAt: DateTime.parse(json['openAt']),
      closeAt: DateTime.parse(json['closeAt']), address: '',
    );
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}

