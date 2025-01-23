import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 다크모드 여부 확인
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '마스크 스토어 앱',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black, // 다크모드에 맞춰 색상 변경
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal,
        elevation: 0, // 앱바 그림자 제거
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              _showSearchDialog(context); // 검색 다이얼로그 호출
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey.shade900] // 다크모드 배경색
                : [Colors.teal.shade200, Colors.teal.shade50], // 라이트모드 배경색
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
              // 마스크 스토어 섹션
              _buildCard(
                context,
                icon: Icons.storefront,
                title: '마스크 스토어',
                subtitle: '마스크 스토어 재고 보기',
                onTap: () {
                  context.push('/maskStoreScreen');
                },
              ),
              const SizedBox(height: 16),
              // 설정 섹션
              _buildCard(
                context,
                icon: Icons.settings,
                title: '설정',
                subtitle: '사용자 환경 설정 관리',
                onTap: () {
                  context.push('/settingsScreen');
                },
              ),
              const SizedBox(height: 16),
              // 즐겨찾기 섹션
              _buildCard(
                context,
                icon: Icons.favorite,
                title: '즐겨찾기',
                subtitle: '즐겨찾기 한 약국 보기',
                onTap: () {
                  context.push('/favoritesScreen');
                },
              ),
              const SizedBox(height: 16),
              // 장바구니 섹션 추가
              _buildCard(
                context,
                icon: Icons.shopping_cart,
                title: '장바구니',
                subtitle: '장바구니에 담긴 상품 보기',
                onTap: () {
                  context.push('/cartScreen');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 카드 생성을 위한 헬퍼 메서드
  Widget _buildCard(BuildContext context,
      {required IconData icon, required String title, required String subtitle, required Function() onTap}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white, // 다크모드에서 카드 배경 색 변경
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
              color: isDarkMode ? Colors.white : Colors.black, // 다크모드에서 텍스트 색상 변경
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey, // 서브타이틀 색상 다크모드 적용
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: isDarkMode ? Colors.white : Colors.grey),
        ),
      ),
    );
  }

  // 검색 다이얼로그
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
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('취소', style: TextStyle(color: isDarkMode ? Colors.white : Colors.teal)),
            ),
            TextButton(
              onPressed: () {
                final searchTerm = searchController.text;
                Navigator.of(context).pop(); // 다이얼로그 닫기
                _performSearch(context, searchTerm); // 검색 실행
              },
              child: Text('검색', style: TextStyle(color: isDarkMode ? Colors.white : Colors.teal)),
            ),
          ],
        );
      },
    );
  }

  // 검색 결과를 처리하는 함수
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
