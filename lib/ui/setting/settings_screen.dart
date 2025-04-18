import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main/mask_store_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MaskStoreViewModel>();
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
          padding: const EdgeInsets.all(16),
          children: [
            _buildDarkModeSetting(context, viewModel, isDarkMode),
            _buildNotificationSetting(context, viewModel, isDarkMode),
            _buildSettingCard(
              context,
              title: '테마 색상',
              icon: Icons.palette,
              isDarkMode: isDarkMode,
              subtitle: viewModel.currentThemeColorName,
              onTap: () => _showThemeColorDialog(context, viewModel),
            ),
            _buildSettingCard(
              context,
              title: '폰트 크기',
              icon: Icons.text_fields,
              isDarkMode: isDarkMode,
              subtitle: '현재 크기: ${viewModel.fontSize}',
              onTap: () => _showFontSizeDialog(context, viewModel),
            ),
            _buildSettingCard(
              context,
              title: '앱 언어 설정',
              icon: Icons.language,
              isDarkMode: isDarkMode,
              onTap: () => _showLanguageDialog(context, isDarkMode),
            ),
            _buildSettingCard(
              context,
              title: '초기 화면 설정',
              icon: Icons.home,
              isDarkMode: isDarkMode,
              onTap: () => _showStartScreenDialog(context, isDarkMode),
            ),
            _buildSettingCard(
              context,
              title: '진동 설정',
              icon: Icons.vibration,
              isDarkMode: isDarkMode,
              onTap: () => _toggleVibration(context, isDarkMode),
            ),
            _buildSettingCard(
              context,
              title: '데이터 사용량 확인',
              icon: Icons.data_usage,
              isDarkMode: isDarkMode,
              onTap: () => _showDataUsageDialog(context, isDarkMode),
            ),
            _buildSettingCard(
              context,
              title: '앱 이용 가이드',
              icon: Icons.menu_book,
              isDarkMode: isDarkMode,
              onTap: () => _showGuideDialog(context, isDarkMode),
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
              title: '데이터 백업 & 복원',
              icon: Icons.backup,
              isDarkMode: isDarkMode,
              onTap: () => _showBackupDialog(context, isDarkMode),
            ),
            _buildSettingCard(
              context,
              title: '라이선스 보기',
              icon: Icons.article,
              isDarkMode: isDarkMode,
              onTap: () => showLicensePage(context: context),
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
              title: '앱 정보',
              icon: Icons.info,
              isDarkMode: isDarkMode,
              onTap: () => _showAppInfo(context, isDarkMode),
            ),
            _buildSettingCard(
              context,
              title: '앱 종료',
              icon: Icons.exit_to_app,
              isDarkMode: isDarkMode,
              onTap: () => _exitApp(),
            ),
          ],
        ),
      ),
    );
  }

  // 기존 기능 위젯 + 각종 Dialog 메서드들 아래로...

  // 기존 다크 모드, 알림 설정, 캐시 초기화, 테마 색상, 폰트 크기, 앱 정보, CustomSnackBar 함수 그대로 두고

  void _showLanguageDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('앱 언어 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['한국어', 'English', '日本語'].map((lang) {
            return ListTile(
              title: Text(lang),
              onTap: () {
                Navigator.pop(context);
                _showCustomSnackBar(context, '언어가 $lang(으)로 설정되었습니다', isDarkMode);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showStartScreenDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('초기 화면 선택'),
        children: [
          SimpleDialogOption(child: const Text('홈'), onPressed: () { Navigator.pop(context); }),
          SimpleDialogOption(child: const Text('즐겨찾기'), onPressed: () { Navigator.pop(context); }),
          SimpleDialogOption(child: const Text('설정'), onPressed: () { Navigator.pop(context); }),
        ],
      ),
    );
  }

  void _toggleVibration(BuildContext context, bool isDarkMode) {
    _showCustomSnackBar(context, '진동 설정이 변경되었습니다', isDarkMode);
  }

  void _showDataUsageDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('데이터 사용량'),
        content: const Text('총 1.5MB 사용 중'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
  }

  void _showGuideDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('앱 이용 가이드'),
        content: const Text('1. 위치 허용\n2. 마스크 매장 확인\n3. 즐겨찾기 추가\n4. 설정 변경'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기'))],
      ),
    );
  }

  void _launchAppReview() async {
    const url = 'https://play.google.com/store/apps/details?id=com.example.app';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@maskstore.com',
      query: 'subject=문의&body=앱 관련 문의드립니다.',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showBackupDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('데이터 백업 & 복원'),
        content: const Text('데이터를 백업하거나 복원하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: () { Navigator.pop(context); _showCustomSnackBar(context, '백업 완료', isDarkMode); }, child: const Text('백업')),
          TextButton(onPressed: () { Navigator.pop(context); _showCustomSnackBar(context, '복원 완료', isDarkMode); }, child: const Text('복원')),
        ],
      ),
    );
  }

  void _exitApp() {
    Future.delayed(const Duration(milliseconds: 300), () {
      // 앱 종료 로직 (platform별 처리 가능)
    });
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
