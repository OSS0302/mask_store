import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../main/mask_store_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey.shade900]
                : [Colors.teal.shade100, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildDarkModeSetting(context, maskStoreViewModel, isDarkMode),
            _buildNotificationSetting(context, maskStoreViewModel, isDarkMode),

            // 테마 색상
            _buildSettingCard(
              context,
              title: '테마 색상',
              icon: Icons.palette,
              isDarkMode: isDarkMode,
              subtitle: maskStoreViewModel.currentThemeColorName,
              onTap: () => _showThemeColorDialog(context, maskStoreViewModel),
            ),

            // 폰트 크기
            _buildSettingCard(
              context,
              title: '폰트 크기',
              icon: Icons.text_fields,
              isDarkMode: isDarkMode,
              subtitle: '현재 크기: ${maskStoreViewModel.fontSize}',
              onTap: () => _showFontSizeDialog(context, maskStoreViewModel),
            ),

            // 앱 언어 설정
            _buildSettingCard(
              context,
              title: '앱 언어',
              icon: Icons.language,
              isDarkMode: isDarkMode,
              subtitle: maskStoreViewModel.currentLanguage,
              onTap: () => _showLanguageDialog(context, maskStoreViewModel),
            ),

            // 초기 화면 설정
            _buildSettingCard(
              context,
              title: '초기 화면',
              icon: Icons.home_filled,
              isDarkMode: isDarkMode,
              subtitle: maskStoreViewModel.initialScreen,
              onTap: () => _showInitialScreenDialog(context, maskStoreViewModel),
            ),

            // 이용 가이드
            _buildSettingCard(
              context,
              title: '앱 이용 가이드',
              icon: Icons.help_outline,
              isDarkMode: isDarkMode,
              onTap: () {
                context.push('/guide');
              },
            ),

            // 캐시 초기화
            _buildSettingCard(
              context,
              title: '캐시 초기화',
              icon: Icons.delete_forever,
              isDarkMode: isDarkMode,
              onTap: () => _clearCache(context),
            ),

            // 앱 평가하기
            _buildSettingCard(
              context,
              title: '앱 평가하기',
              icon: Icons.star_rate,
              isDarkMode: isDarkMode,
              onTap: () {
                _showCustomSnackBar(context, '스토어 페이지로 이동합니다.', isDarkMode);
              },
            ),

            // 앱 정보
            _buildSettingCard(
              context,
              title: '앱 정보',
              icon: Icons.info,
              isDarkMode: isDarkMode,
              onTap: () => _showAppInfo(context, isDarkMode),
            ),

            // 앱 종료
            _buildSettingCard(
              context,
              title: '앱 종료',
              icon: Icons.exit_to_app,
              isDarkMode: isDarkMode,
              onTap: () => _exitAppDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeSetting(BuildContext context, MaskStoreViewModel viewModel, bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: isDarkMode ? Colors.white : Colors.teal),
        title: Text('다크 모드', style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
        trailing: Switch(
          value: viewModel.isDarkMode,
          onChanged: (value) {
            viewModel.toggleDarkMode();
            final msg = viewModel.isDarkMode ? '다크 모드 ON' : '다크 모드 OFF';
            _showCustomSnackBar(context, msg, isDarkMode);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationSetting(BuildContext context, MaskStoreViewModel viewModel, bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(Icons.notifications, color: isDarkMode ? Colors.white : Colors.teal),
        title: Text('알림 설정', style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
        trailing: Switch(
          value: viewModel.isNotificationsEnabled,
          onChanged: (value) {
            viewModel.toggleNotifications();
            final msg = viewModel.isNotificationsEnabled ? '알림 ON' : '알림 OFF';
            _showCustomSnackBar(context, msg, isDarkMode);
          },
        ),
      ),
    );
  }

  void _clearCache(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('캐시 초기화'),
          content: const Text('캐시 데이터를 삭제하시겠습니까?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCustomSnackBar(context, '캐시 데이터 초기화 완료', isDarkMode);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _showAppInfo(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('앱 정보'),
          content: const Text('마스크 스토어 앱\n버전: 1.0.0\n개발자: Mask Store Team'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기'))],
        );
      },
    );
  }

  void _showThemeColorDialog(BuildContext context, MaskStoreViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = {'Teal': Colors.teal, 'Blue': Colors.blue, 'Green': Colors.green};
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('테마 색상'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: colors.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.key, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                value: entry.key,
                groupValue: viewModel.currentThemeColorName,
                onChanged: (value) {
                  viewModel.changeThemeColor(entry.value);
                  Navigator.pop(context);
                  _showCustomSnackBar(context, '${entry.key}로 변경됨', isDarkMode);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showFontSizeDialog(BuildContext context, MaskStoreViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('폰트 크기'),
          content: Slider(
            value: viewModel.fontSize,
            min: 12,
            max: 24,
            divisions: 6,
            label: '${viewModel.fontSize.round()}',
            onChanged: (value) {
              viewModel.changeFontSize(value);
              setState(() {});
            },
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기'))],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, MaskStoreViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final languages = ['한국어', 'English'];
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('앱 언어 설정'),
          children: languages.map((lang) {
            return SimpleDialogOption(
              child: Text(lang, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
              onPressed: () {
                viewModel.changeLanguage(lang);
                Navigator.pop(context);
                _showCustomSnackBar(context, '$lang로 변경됨', isDarkMode);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showInitialScreenDialog(BuildContext context, MaskStoreViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screens = ['홈', '즐겨찾기', '설정'];
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('초기 화면 설정'),
          children: screens.map((screen) {
            return SimpleDialogOption(
              child: Text(screen, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
              onPressed: () {
                viewModel.changeInitialScreen(screen);
                Navigator.pop(context);
                _showCustomSnackBar(context, '초기 화면: $screen', isDarkMode);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _exitAppDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('앱 종료'),
          content: const Text('앱을 종료하시겠습니까?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
          ],
        );
      },
    );
  }

  void _showCustomSnackBar(BuildContext context, String message, bool isDarkMode) {
    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: isDarkMode ? Colors.black : Colors.white)),
      backgroundColor: isDarkMode ? Colors.teal.shade200 : Colors.teal.shade600,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildSettingCard(BuildContext context,
      {required String title, required IconData icon, required bool isDarkMode, String? subtitle, VoidCallback? onTap}) {
    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.teal),
        title: Text(title, style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: isDarkMode ? Colors.grey : Colors.black45)) : null,
        onTap: onTap,
      ),
    );
  }
}
