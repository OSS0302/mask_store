import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '마스크 스토어 앱',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              // 사용자 프로필 화면으로 이동
              context.push('/profileScreen');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey.shade900]
                : [Colors.teal.shade200, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              _buildCategoryCard(context, '마스크 스토어', Icons.storefront, '/maskStoreScreen'),
              const SizedBox(height: 16),
              _buildCategoryCard(context, '설정', Icons.settings, '/settingsScreen'),
              const SizedBox(height: 16),
              _buildCategoryCard(context, '즐겨찾기', Icons.favorite, '/favoritesScreen'),
              const SizedBox(height: 16),
              _buildCategoryCard(context, '장바구니', Icons.shopping_cart, '/cartScreen'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, String route) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.push(route);
      },
      child: Card(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: Colors.grey.withOpacity(0.3),
        child: ListTile(
          leading: Icon(icon, size: 40, color: isDarkMode ? Colors.white : Colors.teal),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            '이 섹션을 클릭하여 자세히 알아보세요.',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: isDarkMode ? Colors.white : Colors.grey),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          title: Text(
            '약국 검색',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: '검색어를 입력하세요',
              hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            ),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소', style: TextStyle(color: isDarkMode ? Colors.white : Colors.teal)),
            ),
            TextButton(
              onPressed: () {
                final searchTerm = searchController.text;
                Navigator.of(context).pop();
                _performSearch(context, searchTerm);
              },
              child: Text('검색', style: TextStyle(color: isDarkMode ? Colors.white : Colors.teal)),
            ),
          ],
        );
      },
    );
  }

  void _performSearch(BuildContext context, String searchTerm) {
    if (searchTerm.isNotEmpty) {
      context.push('/maskStoreScreen?search=$searchTerm');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색어를 입력하세요')),
      );
    }
  }
}
