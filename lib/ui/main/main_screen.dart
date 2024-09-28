import 'package:flutter/material.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';
import '../setting/settings_screen.dart';
import 'mask_store_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 화면 리스트, index 0은 MaskStoreScreen, index 1은 SettingsScreen
  final List<Widget> _screens = [
    const MaskStoreScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();

    return Scaffold(
      body: _screens[_currentIndex], // 현재 선택된 탭에 맞는 화면 표시
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // 탭 클릭 시 화면 전환
          });
        },
        backgroundColor: Colors.teal, // 네비게이션 바 색상
        selectedItemColor: Colors.white, // 선택된 아이템 색상
        unselectedItemColor: Colors.grey.shade400, // 선택되지 않은 아이템 색상
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: '스토어',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
