import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '마스크 스토어 앱',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 0, // 앱바 그림자 제거
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context); // 검색 다이얼로그 호출
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.teal.shade50],
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
              const SizedBox(height: 30),
              // 추가 섹션
              _buildCard(
                context,
                icon: Icons.favorite,
                title: '즐겨찾기',
                subtitle: '즐겨찾기 한 약국 보기',
                onTap: () {
                  context.push('/favoritesScreen');
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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: Colors.grey.withOpacity(0.3),
        child: ListTile(
          leading: Icon(icon, size: 40, color: Colors.teal),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        ),
      ),
    );
  }

  // 검색 다이얼로그
  void _showSearchDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('약국 검색'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: '검색어를 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final searchTerm = searchController.text;
                Navigator.of(context).pop(); // 다이얼로그 닫기
                _performSearch(context, searchTerm); // 검색 실행
              },
              child: const Text('검색'),
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
