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
        title: const Text(
          '설정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
            // 다크 모드 설정
            _buildDarkModeSetting(context, maskStoreViewModel, isDarkMode),

            // 알림 설정
            _buildNotificationSetting(context, maskStoreViewModel, isDarkMode),

            // 테마 색상 설정
            _buildSettingCard(
              context,
              title: '테마 색상',
              icon: Icons.palette,
              isDarkMode: isDarkMode,
              subtitle: maskStoreViewModel.currentThemeColorName,
              onTap: () => _showThemeColorDialog(context, maskStoreViewModel),
            ),

            // 폰트 크기 설정
            _buildSettingCard(
              context,
              title: '폰트 크기',
              icon: Icons.text_fields,
              isDarkMode: isDarkMode,
              subtitle: '현재 크기: ${maskStoreViewModel.fontSize}',
              onTap: () => _showFontSizeDialog(context, maskStoreViewModel),
            ),

            // 캐시 데이터 초기화
            _buildSettingCard(
              context,
              title: '캐시 초기화',
              icon: Icons.delete_forever,
              isDarkMode: isDarkMode,
              onTap: () => _clearCache(context),
            ),

            // 앱 정보
            _buildSettingCard(
              context,
              title: '앱 정보',
              icon: Icons.info,
              isDarkMode: isDarkMode,
              onTap: () => _showAppInfo(context, isDarkMode),
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
        leading: Icon(
          isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: isDarkMode ? Colors.white : Colors.teal,
        ),
        title: Text(
          '다크 모드',
          style: TextStyle(
            fontSize: 18,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        trailing: Switch(
          value: viewModel.isDarkMode,
          onChanged: (value) {
            viewModel.toggleDarkMode();
            final darkMessage = viewModel.isDarkMode
                ? '다크 모드가 활성화되었습니다'
                : '다크 모드가 비활성화되었습니다';
            _showCustomSnackBar(context, darkMessage, isDarkMode);
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
        leading: Icon(
          Icons.notifications,
          color: isDarkMode ? Colors.white : Colors.teal,
        ),
        title: Text(
          '알림 설정',
          style: TextStyle(
            fontSize: 18,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        trailing: Switch(
          value: viewModel.isNotificationsEnabled,
          onChanged: (value) {
            viewModel.toggleNotifications();
            final alarmMessage = viewModel.isNotificationsEnabled
                ? '알림이 활성화되었습니다'
                : '알림이 비활성화되었습니다';
            _showCustomSnackBar(context, alarmMessage, isDarkMode);
          },
        ),
      ),
    );
  }

  // 캐시 초기화
  void _clearCache(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('캐시 초기화'),
          content: const Text('캐시 데이터를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCustomSnackBar(context, '캐시 데이터가 초기화되었습니다', isDarkMode);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // 테마 색상 선택
  void _showThemeColorDialog(BuildContext context, MaskStoreViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = {'Teal': Colors.teal, 'Blue': Colors.blue, 'Green': Colors.green};
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('테마 색상 선택'),
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
                  _showCustomSnackBar(context, '테마 색상이 ${entry.key}로 변경되었습니다', isDarkMode);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // 폰트 크기 설정
  void _showFontSizeDialog(BuildContext context, MaskStoreViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('폰트 크기 설정'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  // 앱 정보
  void _showAppInfo(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('앱 정보'),
          content: const Text('마스크 스토어 앱\n버전: 1.0.0\n개발자: Mask Store Team'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
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
      {required String title,
        required IconData icon,
        required bool isDarkMode,
        String? subtitle,
        VoidCallback? onTap}) {
    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.teal),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(color: isDarkMode ? Colors.grey : Colors.black45))
            : null,
        onTap: onTap,
      ),
    );
  }
}
