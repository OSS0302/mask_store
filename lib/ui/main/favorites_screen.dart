import 'package:flutter/material.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';
import '../../data/model/mask_store.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 필터 상태 ('all', 'plenty', 'some', 'few', 'empty')

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();
    final isDarkMode = maskStoreViewModel.isDarkMode;

    final favoriteStores = maskStoreViewModel.state.stores
        .where((store) =>
    store.isFavorite &&
        store.storeName.contains(_searchQuery) &&
        (_selectedFilter == 'all' || store.remainStatus == _selectedFilter))
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
        actions: [
          if (favoriteStores.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                _clearFavorites(context);
              },
            ),
        ],
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
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.teal),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
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
            _buildFilterChips(),
            Expanded(
              child: favoriteStores.isEmpty
                  ? _buildEmptyFavorites(isDarkMode)
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                itemCount: favoriteStores.length,
                itemBuilder: (context, index) {
                  final store = favoriteStores[index];
                  return _buildStoreCard(store, context, isDarkMode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['all', 'plenty', 'some', 'few', 'empty'];
    final filterLabels = {'all': '전체', 'plenty': '충분', 'some': '보통', 'few': '부족', 'empty': '없음'};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filterLabels[filter] ?? filter),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: Colors.teal.shade300,
              backgroundColor: Colors.grey.shade300,
            ),
          );
        }).toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${store.storeName} 클릭됨')),
        );
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
                width: double.infinity,
                height: 180,
                child: Image.network(
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRK0ZkGuGa63hz6IGaxDNfhOHR4VK3Y7wkAIjsTeEYTycSq9xBzvjfAH7E&s',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  void _clearFavorites(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('즐겨찾기 초기화'),
        content: const Text('모든 즐겨찾기를 비우시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<MaskStoreViewModel>().clearFavorites();
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
