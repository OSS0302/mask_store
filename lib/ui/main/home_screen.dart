import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'mask_store_screen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 검색 기능을 여기에 추가할 수 있습니다.
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
            ],
          ),
        ),
      ),
    );
  }

  // 카드 생성을 위한 헬퍼 메서드
  Widget _buildCard(BuildContext context,
      {required IconData icon,
        required String title,
        required String subtitle,
        required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: Colors.grey.withOpacity(0.2),
        child: ListTile(
          leading: Icon(icon, size: 50, color: Colors.teal),
          title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        ),
      ),
    );
  }
}
