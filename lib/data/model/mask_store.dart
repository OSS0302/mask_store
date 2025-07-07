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
  final String category;
  final String imageUrl;

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
    required this.category,
    required this.imageUrl,
  });

  factory MaskStore.fromJson(Map<String, dynamic> json) {
    return MaskStore(
      storeName: json['storeName'],
      address: json['address'] ?? '',
      distance: 0.0,
      remainStatus: json['remainStatus'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      openAt: json['openAt'] != null ? DateTime.parse(json['openAt']) : null,
      closeAt: json['closeAt'] != null ? DateTime.parse(json['closeAt']) : null,
      category: json['category'] ?? '기타',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}
