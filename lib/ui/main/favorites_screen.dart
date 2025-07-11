import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/model/mask_store.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'name';
  String _selectedCategory = 'all';
  bool _showNearbyOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<MaskStoreViewModel>();
    final alertStore = vm.plentyAlertStore;
    if (alertStore != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${alertStore.storeName} 약국에 재고가 충분해졌습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        vm.clearPlentyAlert();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();
    final isDarkMode = maskStoreViewModel.isDarkMode;

    final favoriteStores = maskStoreViewModel.state.stores.where((store) {
      final matchesSearch = store.storeName.contains(_searchQuery);
      final matchesFilter = _selectedFilter == 'all' || store.remainStatus == _selectedFilter;
      final matchesCategory = _selectedCategory == 'all' || store.category == _selectedCategory;
      final matchesNearby = !_showNearbyOnly || store.distance <= 1.0;
      return store.isFavorite && matchesSearch && matchesFilter && matchesCategory && matchesNearby;
    }).toList();

    if (_selectedSort == 'name') {
      favoriteStores.sort((a, b) => a.storeName.compareTo(b.storeName));
    } else if (_selectedSort == 'distance') {
      favoriteStores.sort((a, b) => a.distance.compareTo(b.distance));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('즐겨찾기 약국', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.black : Colors.teal.shade300,
        elevation: 0,
        actions: [
          if (favoriteStores.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _shareFavorites(favoriteStores),
            ),
          if (favoriteStores.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map, color: Colors.white),
              onPressed: () => _openInMap(favoriteStores),
            ),
          if (favoriteStores.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: () => _exportFavorites(favoriteStores),
            ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.white),
            onPressed: () => maskStoreViewModel.toggleDarkMode(),
          ),
          if (favoriteStores.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _clearFavorites(context),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode ? [Colors.black87, Colors.grey.shade900] : [Colors.teal.shade100, Colors.teal.shade50],
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
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: '약국 이름 검색',
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.teal),
                    onPressed: () => setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    }),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('정렬:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: _selectedSort,
                        onChanged: (value) => setState(() => _selectedSort = value ?? 'name'),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('이름순')),
                          DropdownMenuItem(value: 'distance', child: Text('거리순')),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('1km 이내'),
                      Switch(
                        value: _showNearbyOnly,
                        onChanged: (val) => setState(() => _showNearbyOnly = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('카테고리:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    onChanged: (value) => setState(() => _selectedCategory = value ?? 'all'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('전체')),
                      DropdownMenuItem(value: 'pharmacy', child: Text('약국')),
                      DropdownMenuItem(value: 'hospital', child: Text('병원')),
                      DropdownMenuItem(value: 'mart', child: Text('마트')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: favoriteStores.isEmpty
                  ? _buildEmptyFavorites(isDarkMode)
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                itemCount: favoriteStores.length,
                itemBuilder: (context, index) {
                  final store = favoriteStores[index];
                  return Dismissible(
                    key: Key(store.storeName),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => context.read<MaskStoreViewModel>().toggleFavorite(store),
                    child: _buildStoreCard(store, context, isDarkMode),
                  );
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
    final filterLabels = {
      'all': '전체',
      'plenty': '충분',
      'some': '보통',
      'few': '부족',
      'empty': '없음'
    };

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
              onSelected: (selected) => setState(() => _selectedFilter = filter),
              selectedColor: Colors.teal.shade300,
              backgroundColor: Colors.grey.shade300,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyFavorites(bool isDarkMode) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.favorite_border, color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400, size: 100),
        const SizedBox(height: 16),
        Text(
          '즐겨찾기 한 약국이 없습니다.',
          style: TextStyle(fontSize: 20, color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _buildStoreCard(MaskStore store, BuildContext context, bool isDarkMode) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/storeDetail', arguments: store),
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            child: SizedBox(
              width: double.infinity,
              height: 180,
              child: Image.network(
                store.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 50, color: Colors.red),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.storeName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.teal.shade300),
                    const SizedBox(width: 4),
                    Text('${store.distance.toStringAsFixed(2)} km', style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(store.remainStatus),
                    IconButton(
                      icon: Icon(store.isFavorite ? Icons.favorite : Icons.favorite_border, color: store.isFavorite ? Colors.red : (isDarkMode ? Colors.grey.shade400 : Colors.grey)),
                      onPressed: () => context.read<MaskStoreViewModel>().toggleFavorite(store),
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
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

  void _shareFavorites(List<MaskStore> stores) {
    final storeList = stores.map((store) => '- ${store.storeName} (${store.distance.toStringAsFixed(2)} km)').join('\n');
    Share.share('내 즐겨찾기 약국 목록:\n\n$storeList');
  }

  void _openInMap(List<MaskStore> stores) async {
    if (stores.isEmpty) return;
    final store = stores.first;
    final url = 'https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw '지도를 열 수 없습니다: $url';
    }
  }

  Future<void> _exportFavorites(List<MaskStore> stores) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/favorites.txt');
      final content = stores.map((s) => '${s.storeName} (${s.distance.toStringAsFixed(2)} km)').join('\n');
      await file.writeAsString(content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('즐겨찾기 파일을 내보냈습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파일 저장 실패')),
      );
    }
  }
}
