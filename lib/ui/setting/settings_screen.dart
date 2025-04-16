import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter/services.dart';
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
            _buildDarkModeSetting(context, maskStoreViewModel, isDarkMode),
            _buildNotificationSetting(context, maskStoreViewModel, isDarkMode),
            _buildSettingCard(
              context,
              title: '테마 색상',
              icon: Icons.palette,
              isDarkMode: isDarkMode,
              subtitle: maskStoreViewModel.currentThemeColorName,
              onTap: () => _showThemeColorDialog(context, maskStoreViewModel),
            ),
            _buildSettingCard(
              context,
              title: '폰트 크기',
              icon: Icons.text_fields,
              isDarkMode: isDarkMode,
              subtitle: '현재 크기: ${maskStoreViewModel.fontSize}',
              onTap: () => _showFontSizeDialog(context, maskStoreViewModel),
            ),
            _buildSettingCard(
              context,
              title: '캐시 초기화',
              icon: Icons.delete_forever,
              isDarkMode: isDarkMode,
              onTap: () => _clearCache(context),
            ),
            _buildSettingCard(
              context,
              title: '앱 이용 가이드',
              icon: Icons.menu_book,
              isDarkMode: isDarkMode,
              onTap: () {
                context.push('/guide');
              },
            ),
            _buildSettingCard(
              context,
              title: '앱 평가하기',
              icon: Icons.star_rate,
              isDarkMode: isDarkMode,
              onTap: _launchAppReview,
            ),
            _buildSettingCard(
              context,
              title: '문의하기',
              icon: Icons.email,
              isDarkMode: isDarkMode,
              onTap: _launchEmail,
            ),
            _buildSettingCard(
              context,
              title: '앱 종료',
              icon: Icons.exit_to_app,
              isDarkMode: isDarkMode,
              onTap: _exitApp,
            ),
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

  // 다크 모드
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
          style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black),
        ),
        trailing: Switch(
          value: viewModel.isDarkMode,
          onChanged: (value) {
            viewModel.toggleDarkMode();
            final darkMessage = viewModel.isDarkMode ? '다크 모드가 활성화되었습니다' : '다크 모드가 비활성화되었습니다';
            _showCustomSnackBar(context, darkMessage, isDarkMode);
          },
        ),
      ),
    );
  }

  // 알림 설정
  Widget _buildNotificationSetting(BuildContext context, MaskStoreViewModel viewModel, bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(Icons.notifications, color: isDarkMode ? Colors.white : Colors.teal),
        title: Text(
          '알림 설정',
          style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black),
        ),
        trailing: Switch(
          value: viewModel.isNotificationsEnabled,
          onChanged: (value) {
            viewModel.toggleNotifications();
            final message = viewModel.isNotificationsEnabled ? '알림이 활성화되었습니다' : '알림이 비활성화되었습니다';
            _showCustomSnackBar(context, message, isDarkMode);
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
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

  // 테마 색상
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

  // 폰트 크기
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
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
          content: const Text('마스크 스토어 앱\n버전: 1.0.0\n개발자: Mask Store Team\n문의: maskstore@app.com'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
          ],
        );
      },
    );
  }

  // 앱 평가하기
  void _launchAppReview() async {
    const url = 'https://play.google.com/store/apps/details?id=com.example.app';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // 문의하기
  void _launchEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'maskstore@app.com',
      query: 'subject=앱 문의&body=문의 내용을 작성해주세요.',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  // 앱 종료
  void _exitApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }

  // 스낵바
  void _showCustomSnackBar(BuildContext context, String message, bool isDarkMode) {
    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: isDarkMode ? Colors.black : Colors.white)),
      backgroundColor: isDarkMode ? Colors.teal.shade200 : Colors.teal.shade600,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // 공통 카드 위젯
  Widget _buildSettingCard(BuildContext context,
      {required String title, required IconData icon, required bool isDarkMode, String? subtitle, VoidCallback? onTap}) {
    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.teal),
        title: Text(title, style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(color: isDarkMode ? Colors.grey : Colors.black45))
            : null,
        onTap: onTap,
      ),
    );
  }
}
