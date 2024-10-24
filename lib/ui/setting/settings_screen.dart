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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            Card(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.dark_mode, color: isDarkMode ? Colors.white : Colors.teal),
                title: Text(
                  '다크 모드',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                trailing: Switch(
                  value: maskStoreViewModel.isDarkMode,
                  activeColor: Colors.teal,
                  onChanged: (value) {
                    maskStoreViewModel.toggleDarkMode();
                    final darkMessage = maskStoreViewModel.isDarkMode
                        ? '다크 모드가 활성화되었습니다'
                        : '다크 모드가 비활성화되었습니다';
                    _showCustomSnackBar(context, darkMessage, isDarkMode);
                  },
                ),
              ),
            ),

            // 알림 설정
            Card(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.notifications, color: isDarkMode ? Colors.white : Colors.teal),
                title: Text(
                  '알림 설정',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                trailing: Switch(
                  value: maskStoreViewModel.isNotificationsEnabled,
                  activeColor: Colors.teal,
                  onChanged: (value) {
                    maskStoreViewModel.toggleNotifications();
                    final alarmMessage = maskStoreViewModel.isNotificationsEnabled
                        ? '알림이 활성화되었습니다'
                        : '알림이 비활성화되었습니다';
                    _showCustomSnackBar(context, alarmMessage, isDarkMode);
                  },
                ),
              ),
            ),

            // 언어 설정
            Card(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.language, color: isDarkMode ? Colors.white : Colors.teal),
                title: Text(
                  '언어 설정',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  maskStoreViewModel.currentLanguage,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                  ),
                ),
                onTap: () {
                  _showLanguageDialog(context, maskStoreViewModel);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomSnackBar(BuildContext context, String message, bool isDarkMode) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isDarkMode ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isDarkMode ? Colors.teal.shade200 : Colors.teal.shade600,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showLanguageDialog(BuildContext context, MaskStoreViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          title: Text(
            '언어 선택',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                RadioListTile<String>(
                  title: Text(
                    '한국어',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  value: '한국어',
                  groupValue: viewModel.currentLanguage,
                  onChanged: (value) {
                    viewModel.changeLanguage(value!);
                    _showCustomSnackBar(context, '언어가 한국어로 변경되었습니다', isDarkMode);
                    context.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: Text(
                    'English',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  value: 'English',
                  groupValue: viewModel.currentLanguage,
                  onChanged: (value) {
                    viewModel.changeLanguage(value!);
                    _showCustomSnackBar(context, '언어가 변경되었습니다.', isDarkMode);
                    context.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                '닫기',
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.teal),
              ),
              onPressed: () {
                context.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
