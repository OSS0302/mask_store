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
              title: '초기 화면 설정',
              icon: Icons.home,
              isDarkMode: isDarkMode,
              subtitle: '현재: ${maskStoreViewModel.initialScreen}',
              onTap: () => _showInitialScreenDialog(context, maskStoreViewModel),
            ),

            _buildSettingCard(
              context,
              title: '진동 설정',
              icon: Icons.vibration,
              isDarkMode: isDarkMode,
              onTap: () {
                HapticFeedback.mediumImpact();
                _showCustomSnackBar(context, '진동 테스트!', isDarkMode);
              },
            ),

            _buildSettingCard(
              context,
              title: '데이터 사용량',
              icon: Icons.data_usage,
              isDarkMode: isDarkMode,
              subtitle: '오늘 12.4MB',
              onTap: () {},
            ),

            _buildSettingCard(
              context,
              title: '앱 이용 가이드',
              icon: Icons.menu_book,
              isDarkMode: isDarkMode,
              onTap: () => _showAppGuide(context),
            ),

            _buildSettingCard(
              context,
              title: '앱 평가하기',
              icon: Icons.star_rate,
              isDarkMode: isDarkMode,
              onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=com.example.app'),
            ),

            _buildSettingCard(
              context,
              title: '문의하기',
              icon: Icons.mail_outline,
              isDarkMode: isDarkMode,
              onTap: () => _launchEmail(),
            ),

            _buildSettingCard(
              context,
              title: '라이선스 보기',
              icon: Icons.description,
              isDarkMode: isDarkMode,
              onTap: () => showLicensePage(context: context),
            ),

            _buildSettingCard(
              context,
              title: '앱 종료',
              icon: Icons.exit_to_app,
              isDarkMode: isDarkMode,
              onTap: () => exit(0),
            ),
          ],
        ),
      ),
    );
  }

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

  void _showInitialScreenDialog(BuildContext context, MaskStoreViewModel viewModel) {
    final options = ['홈', '즐겨찾기', '지도'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('초기 화면 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: viewModel.initialScreen,
                onChanged: (value) {
                  viewModel.changeInitialScreen(value!);
                  Navigator.pop(context);
                  setState(() {});
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAppGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('앱 이용 가이드'),
          content: const Text('1. 마스크 매장 검색\n2. 즐겨찾기 등록\n3. 재고 상태 확인\n4. 테마 설정 가능\n5. 설정 화면에서 다양한 기능 제공'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
          ],
        );
      },
    );
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@maskstore.app',
      query: 'subject=문의사항&body=여기에 내용을 입력하세요.',
    );
    await launchUrl(emailLaunchUri);
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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

  Widget _buildDarkModeSetting(BuildContext context, MaskStoreViewModel viewModel, bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: isDarkMode ? Colors.white : Colors.teal),
        title: Text('다크 모드',
            style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
        trailing: Switch(
          value: viewModel.isDarkMode,
          onChanged: (value) {
            viewModel.toggleDarkMode();
            final darkMessage = value ? '다크 모드 ON' : '다크 모드 OFF';
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
        leading: Icon(Icons.notifications, color: isDarkMode ? Colors.white : Colors.teal),
        title: Text('알림 설정',
            style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
        trailing: Switch(
          value: viewModel.isNotificationsEnabled,
          onChanged: (value) {
            viewModel.toggleNotifications();
            final alarmMessage = value ? '알림 ON' : '알림 OFF';
            _showCustomSnackBar(context, alarmMessage, isDarkMode);
          },
        ),
      ),
    );
  }
}
