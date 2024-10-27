import 'package:flutter/material.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';
import '../../data/model/mask_store.dart';
import '../component/store_item.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();
    final isDarkMode = maskStoreViewModel.isDarkMode; // 다크모드 여부 가져오기

    final favoriteStores = maskStoreViewModel.state.stores
        .where((store) => store.isFavorite && store.storeName.contains(_searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '즐겨찾기 약국',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.black : Colors.teal.shade300,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black87, Colors.grey.shade900]
                : [Colors.teal.shade100, Colors.teal.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: '약국 이름 검색',
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey : Colors.black54),
                ),
              ),
            ),
            Expanded(
              child: favoriteStores.isEmpty
                  ? _buildEmptyFavorites(isDarkMode)
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: favoriteStores.length,
                  itemBuilder: (context, index) {
                    final store = favoriteStores[index];
                    return _buildStoreCard(store, context, isDarkMode);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
            size: 100,
          ),
          const SizedBox(height: 16),
          Text(
            '즐겨찾기 한 약국이 없습니다.',
            style: TextStyle(
              fontSize: 20,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(MaskStore store, BuildContext context, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        // 약국 상세 페이지로 이동하거나 다른 동작 추가 가능
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 10),
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: SizedBox(
                width: 400,
                child: Image.network(
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRK0ZkGuGa63hz6IGaxDNfhOHR4VK3Y7wkAIjsTeEYTycSq9xBzvjfAH7E&s',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, size: 50, color: Colors.red);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.storeName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.teal.shade300),
                      const SizedBox(width: 4),
                      Text(
                        '${store.distance.toStringAsFixed(2)} km',
                        style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusChip(store.remainStatus),
                      IconButton(
                        icon: Icon(
                          store.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: store.isFavorite ? Colors.red : (isDarkMode ? Colors.grey.shade400 : Colors.grey),
                        ),
                        onPressed: () {
                          context.read<MaskStoreViewModel>().toggleFavorite(store);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'plenty':
        color = Colors.green;
        text = '충분';
        break;
      case 'some':
        color = Colors.orange;
        text = '보통';
        break;
      case 'few':
        color = Colors.red;
        text = '부족';
        break;
      case 'empty':
      default:
        color = Colors.grey;
        text = '없음';
        break;
    }

    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
