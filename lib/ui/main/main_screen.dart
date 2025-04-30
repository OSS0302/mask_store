import 'package:flutter/material.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';
import '../setting/settings_screen.dart';
import 'mask_store_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;
  final List<Widget> _screens = const [
    MaskStoreScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialIndex();
  }

  Future<void> _loadInitialIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('main_tab_index') ?? 0;
    setState(() {
      _currentIndex = savedIndex;
    });
  }

  Future<void> _saveTabIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('main_tab_index', index);
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('뒤로 버튼을 한 번 더 누르면 종료됩니다')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _screens[_currentIndex],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            _saveTabIndex(index);
          },
          height: 65,
          backgroundColor: theme.colorScheme.surface,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          indicatorColor: theme.colorScheme.primary.withOpacity(0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: '스토어',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}
