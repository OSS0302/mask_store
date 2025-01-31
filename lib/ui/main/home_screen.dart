import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      {'title': '마스크 스토어', 'icon': Icons.storefront, 'route': '/maskStoreScreen'},
      {'title': '설정', 'icon': Icons.settings, 'route': '/settingsScreen'},
      {'title': '즐겨찾기', 'icon': Icons.favorite, 'route': '/favoritesScreen'},
      {'title': '장바구니', 'icon': Icons.shopping_cart, 'route': '/cartScreen'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '마스크 스토어 앱',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: isDarkMode ? Colors.white : Colors.teal.shade800,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal.shade200,
        elevation: 8,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => context.push('/profileScreen'),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(
                  context,
                  category['title'] as String,
                  category['icon'] as IconData,
                  category['route'] as String,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, String route) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.grey.shade800, Colors.grey.shade700]
                : [Colors.white, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: isDarkMode ? Colors.white : Colors.teal),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
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
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
              title: Text(
                '약국 검색',
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '검색어를 입력하세요',
                      hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  if (searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        '검색어: ${searchController.text}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('취소', style: TextStyle(color: isDarkMode ? Colors.white : Colors.teal)),
                ),
                TextButton(
                  onPressed: () {
                    final searchTerm = searchController.text.trim();
                    Navigator.of(context).pop();
                    if (searchTerm.isNotEmpty) {
                      _performSearch(context, searchTerm);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.teal.shade100,
                          content: const Text('검색어를 입력하세요'),
                        ),
                      );
                    }
                  },
                  child: Text('검색', style: TextStyle(color: isDarkMode ? Colors.white : Colors.teal)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _performSearch(BuildContext context, String searchTerm) {
    context.push('/maskStoreScreen?search=$searchTerm');
  }
}
