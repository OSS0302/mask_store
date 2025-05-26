import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../setting/settings_screen.dart';
import 'mask_store_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;
  bool _showSettingsBadge = true;
  String _userGreeting = '';
  String _appVersion = '';

  final List<Widget> _screens = const [
    ContactUsScreen(),
    SettingsScreen(),
  ];

  final List<String> _appBarTitles = [
    '마스크 스토어',
    '설정',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialIndex();
    _loadGreeting();
    _loadAppVersion();
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

  Future<void> _loadGreeting() async {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = '좋은 아침입니다!';
    } else if (hour < 18) {
      greeting = '좋은 오후입니다!';
    } else {
      greeting = '좋은 저녁입니다!';
    }
    setState(() {
      _userGreeting = greeting;
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("한 번 더 누르면 앱이 종료됩니다.")),
      );
      return false;
    }
    return true;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _saveTabIndex(index);
      if (index == 1) _showSettingsBadge = false;
    });
    HapticFeedback.selectionClick();
  }

  void _onFabSelected(String action) {
    if (action == 'guide') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    } else if (action == 'share') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("앱 공유 기능은 준비 중입니다.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _appBarTitles[_currentIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text(
                '$_userGreeting  v$_appVersion',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: isDark ? Colors.grey[900] : Colors.teal,
        ),
        body: _screens[_currentIndex],
        floatingActionButton: _buildFab(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: isDark ? Colors.grey[900] : Colors.teal,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront),
              label: '스토어',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.settings),
                  if (_showSettingsBadge)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return ExpandableFab(
      distance: 100,
      children: [
        ActionButton(
          onPressed: () => _onFabSelected('guide'),
          icon: const Icon(Icons.info_outline),
          tooltip: '앱 이용 가이드',
        ),
        ActionButton(
          onPressed: () => _onFabSelected('share'),
          icon: const Icon(Icons.share),
          tooltip: '앱 공유하기',
        ),
      ],
    );
  }
}

// FAB 위젯들
class ExpandableFab extends StatefulWidget {
  final double distance;
  final List<Widget> children;

  const ExpandableFab({
    super.key,
    required this.distance,
    required this.children,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnimation = CurvedAnimation(curve: Curves.easeOut, parent: _controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ..._buildExpandingActionButtons(),
          FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: Colors.teal,
            child: Icon(_open ? Icons.close : Icons.menu),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (int i = 0; i < count; i++) {
      final angle = i * step;
      final offset = Offset.fromDirection(angle * (3.14159265 / 180), widget.distance);
      children.add(
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Positioned(
              right: offset.dx * _expandAnimation.value + 16,
              bottom: offset.dy * _expandAnimation.value + 16,
              child: FadeTransition(
                opacity: _expandAnimation,
                child: child,
              ),
            );
          },
          child: widget.children[i],
        ),
      );
    }
    return children;
  }
}

class ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String? tooltip;

  const ActionButton({super.key, required this.onPressed, required this.icon, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      tooltip: tooltip,
      onPressed: onPressed,
      backgroundColor: Colors.teal.shade700,
      child: icon,
    );
  }
}
